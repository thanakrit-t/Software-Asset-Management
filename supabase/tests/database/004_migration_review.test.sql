begin;

select plan(31);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
values
  ('40000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'migration-admin@test.local', crypt('test-only', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('40000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'migration-user@test.local', crypt('test-only', gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

update public.profiles set app_role = 'admin'
where id = '40000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"40000000-0000-4000-8000-000000000002","role":"authenticated"}', true);

select throws_ok(
  $$ select public.get_import_batch_review(gen_random_uuid()) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot read migration review data'
);

select throws_ok(
  $$ select public.begin_import_batch('{}'::jsonb) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot begin an import batch'
);

reset role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
do $fixture$
begin
  perform vault.create_secret(
    'local-test-pepper-not-for-production', 'sam_license_fingerprint_pepper', 'pgTAP fixture'
  );
end $fixture$;

select lives_ok(
  $$ select public.begin_import_batch(jsonb_build_object(
    'batch_name', 'pgTAP migration fixture',
    'environment', 'local-test',
    'sources', jsonb_build_array(
      jsonb_build_object('kind','asset','file_name','02 203Total License(TKC) Update 2026-08-28.xlsx','sha256','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','file_size_bytes',10),
      jsonb_build_object('kind','license','file_name','03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx','sha256','bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb','file_size_bytes',20)
    )
  )) $$,
  'service context can begin approved import batch'
);

select set_config('test.batch_id', (select id::text from migration.import_batches where batch_name = 'pgTAP migration fixture'), true);
select set_config('test.asset_file_id', (select id::text from migration.source_files where import_batch_id = current_setting('test.batch_id')::uuid and file_name like '02 %'), true);
select set_config('test.license_file_id', (select id::text from migration.source_files where import_batch_id = current_setting('test.batch_id')::uuid and file_name like '03 %'), true);

select throws_ok(
  $$ select public.stage_license_rows(
    current_setting('test.batch_id')::uuid,
    jsonb_build_array(jsonb_build_object(
      'source_file_id', current_setting('test.license_file_id'),
      'sheet_name','Software License FACTORY','source_row_number',9,
      'source_row_hash', repeat('c',64),
      'raw_data',jsonb_build_object('Serial No.','FORBIDDEN'),
      'normalized_product_name','Unsafe'
    ))
  ) $$,
  '22023', 'PLAINTEXT_SECRET_REJECTED',
  'staging rejects secret-like raw JSON keys case-insensitively'
);

select throws_ok(
  $$ select public.stage_asset_rows(current_setting('test.batch_id')::uuid, '[]'::jsonb) $$,
  '22023', 'ROWS_REQUIRED',
  'staging rejects an empty row array'
);

select throws_ok(
  $$ select public.stage_asset_rows(current_setting('test.batch_id')::uuid,
     (select jsonb_agg(jsonb_build_object('source_file_id',current_setting('test.asset_file_id'),'sheet_name','Software(Factory)','source_row_number',g,'source_row_hash',encode(digest(g::text,'sha256'),'hex'),'raw_data','{}'::jsonb)) from generate_series(1,101) g)) $$,
  '22023', 'BATCH_TOO_LARGE',
  'staging limits each call to one hundred rows'
);

select lives_ok(
  $$ select public.stage_asset_rows(current_setting('test.batch_id')::uuid, jsonb_build_array(
    jsonb_build_object('source_file_id',current_setting('test.asset_file_id'),'sheet_name','Software(Factory)','source_row_number',7,'source_row_hash',repeat('1',64),'raw_data',jsonb_build_object('label','asset'), 'normalized_asset_code','MIG-A-001','normalized_computer_name','MIG-PC-001','normalized_site_code','FACTORY','normalized_mac_address','AA:BB:CC:DD:EE:FF'),
    jsonb_build_object('source_file_id',current_setting('test.asset_file_id'),'sheet_name','Software(Office)','source_row_number',7,'source_row_hash',repeat('2',64),'raw_data',jsonb_build_object('label','duplicate'), 'normalized_asset_code','MIG-A-001','normalized_computer_name','MIG-PC-DUP','normalized_site_code','FACTORY','normalized_mac_address','AA:BB:CC:DD:EE:FF','normalized_ip_address','10.0.0.2'),
    jsonb_build_object('source_file_id',current_setting('test.asset_file_id'),'sheet_name','Software(Factory)','source_row_number',9,'source_row_hash',repeat('3',64),'raw_data',jsonb_build_object('label','bad'), 'normalized_site_code','FACTORY')
  )) $$,
  'asset staging accepts sanitized rows'
);

select lives_ok(
  $$ select public.stage_license_rows(current_setting('test.batch_id')::uuid, jsonb_build_array(
    jsonb_build_object('source_file_id',current_setting('test.license_file_id'),'sheet_name','Software License FACTORY','source_row_number',9,'source_row_hash',repeat('4',64),'raw_data',jsonb_build_object('label','license'), 'normalized_publisher','Migration Publisher','normalized_vendor','Migration Vendor','normalized_product_name','Migration Product','normalized_version','1','normalized_classification','Commercial','normalized_purchase_form','Perpetual','normalized_owned_quantity',3,'normalized_record_status','active','normalized_start_date','2027-01-01','normalized_end_date','2026-01-01','serial_present',true,'serial_fingerprint',repeat('5',64),'serial_masked_hint','MASKED-ONLY'),
    jsonb_build_object('source_file_id',current_setting('test.license_file_id'),'sheet_name','Software License FACTORY','source_row_number',10,'source_row_hash',repeat('6',64),'raw_data',jsonb_build_object('label','warning'), 'normalized_publisher','Migration Publisher','normalized_product_name','Warning Product','normalized_owned_quantity',1)
  )) $$,
  'license staging accepts fingerprints and masked hints without plaintext'
);

select is((select status::text from migration.import_batches where id=current_setting('test.batch_id')::uuid), 'extracted', 'staging advances batch to extracted');
select is((select version from migration.import_batches where id=current_setting('test.batch_id')::uuid), 3, 'each staging status mutation increments version');

select lives_ok($$ select public.validate_import_batch(current_setting('test.batch_id')::uuid) $$, 'validation runs atomically');
select is((select status::text from migration.import_batches where id=current_setting('test.batch_id')::uuid), 'validated', 'validation advances batch to validated');
select is((select count(*)::integer from migration.row_results where import_batch_id=current_setting('test.batch_id')::uuid and result_status='error'), 1, 'missing Asset business key is an error');
select is((select count(*)::integer from migration.row_results where import_batch_id=current_setting('test.batch_id')::uuid and decision_reason='DUPLICATE_EXACT'), 1, 'exact duplicate is skipped deterministically');
select is((select count(*)::integer from migration.row_results where import_batch_id=current_setting('test.batch_id')::uuid and jsonb_array_length(warnings)>0), 1, 'incomplete optional License values are warnings');

select lives_ok($$ select public.validate_import_batch(current_setting('test.batch_id')::uuid) $$, 'validation can be rerun');
select is((select count(*)::integer from migration.row_results where import_batch_id=current_setting('test.batch_id')::uuid), 5, 'revalidation replaces rather than duplicates results');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"40000000-0000-4000-8000-000000000001","role":"authenticated"}', true);

select is((public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'summary'->>'error_count')::integer, 1, 'Admin review exposes literal error count');
select is((public.get_import_batch_review(current_setting('test.batch_id')::uuid)::text like '%FORBIDDEN%'), false, 'review DTO contains no plaintext secret value');

select throws_ok($$ select public.acknowledge_import_warnings(current_setting('test.batch_id')::uuid, 1) $$, '40001', 'VERSION_CONFLICT', 'warning acknowledgement enforces optimistic version');
select lives_ok($$ select public.acknowledge_import_warnings(current_setting('test.batch_id')::uuid, ((public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'batch'->>'version')::integer)) $$, 'Admin can acknowledge warnings');

select throws_ok($$ select public.publish_import_batch(current_setting('test.batch_id')::uuid, ((public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'batch'->>'version')::integer), true) $$, 'P0001', 'IMPORT_HAS_ERRORS', 'batch with errors cannot publish');

reset role;

update migration.asset_staging_rows set normalized_asset_code='MIG-A-002', normalized_computer_name='MIG-PC-001' where raw_data->>'label'='duplicate';
update migration.asset_staging_rows set normalized_asset_code='MIG-A-003', normalized_computer_name='MIG-PC-003' where source_row_number=9;
select public.validate_import_batch(current_setting('test.batch_id')::uuid);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"40000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select public.acknowledge_import_warnings(current_setting('test.batch_id')::uuid, ((public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'batch'->>'version')::integer));

select lives_ok($$ select public.publish_import_batch(current_setting('test.batch_id')::uuid, ((public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'batch'->>'version')::integer), true) $$, 'eligible batch publishes atomically');
select is((select count(*)::integer from public.assets where migration_batch_id=current_setting('test.batch_id')::uuid), 3, 'publish creates traced Assets');
select is((select count(*)::integer from public.license_entitlements where migration_batch_id=current_setting('test.batch_id')::uuid), 2, 'publish creates traced License entitlements');
select is((
  select end_date
  from public.license_entitlements
  where migration_batch_id=current_setting('test.batch_id')::uuid
    and migration_source_row_id=(
      select (review_row->>'staging_row_id')::uuid
      from jsonb_array_elements(public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'rows') as review(review_row)
      where review_row->>'entity_type'='license'
        and (review_row->>'source_row_number')::integer=9
    )
), null::date, 'invalid source date range keeps original in staging and clears operational end date');
reset role;
select is((select count(*)::integer from audit.audit_events where entity_type='import_batch' and entity_id=current_setting('test.batch_id')::uuid and action='publish'), 1, 'publish appends one sanitized audit event');
select is((select status::text from migration.import_batches where id=current_setting('test.batch_id')::uuid), 'committed', 'publish marks batch committed last');
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"40000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select throws_ok($$ select public.publish_import_batch(current_setting('test.batch_id')::uuid, ((public.get_import_batch_review(current_setting('test.batch_id')::uuid)->'batch'->>'version')::integer), true) $$, 'P0001', 'IMPORT_ALREADY_PUBLISHED', 'committed batch cannot publish twice');

select is(has_function_privilege('anon','public.publish_import_batch(uuid,integer,boolean)','execute'), false, 'anon cannot execute publish');
select is(has_function_privilege('authenticated','public.publish_import_batch(uuid,integer,boolean)','execute'), true, 'authenticated may execute only guarded publish boundary');

select * from finish();
rollback;
