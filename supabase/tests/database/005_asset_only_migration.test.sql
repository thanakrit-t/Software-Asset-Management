begin;

select plan(30);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
values (
  '41000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'asset-migration-admin@test.local',
  crypt('test-only', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
);

update public.profiles
set app_role = 'admin'
where id = '41000000-0000-4000-8000-000000000001';

select vault.create_secret(
  'pgTAP-license-only-pepper',
  'sam_license_fingerprint_pepper',
  'Asset-only migration test fixture'
);

select set_config('request.jwt.claims', '{"role":"service_role"}', true);

select lives_ok(
  $$ select public.begin_import_batch(jsonb_build_object(
    'batch_name', 'pgTAP Asset-only fixture',
    'environment', 'local-test',
    'sources', jsonb_build_array(
      jsonb_build_object(
        'kind', 'asset',
        'file_name', '02 203Total License(TKC) Update 2026-08-28.xlsx',
        'sha256', 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'file_size_bytes', 30
      )
    )
  )) $$,
  'service context can begin an Asset-only import batch'
);

select is(
  (
    select count(*)::integer
    from migration.source_files
    where import_batch_id = (
      select id from migration.import_batches
      where batch_name = 'pgTAP Asset-only fixture'
    )
  ),
  1,
  'Asset-only batch records only one approved source file'
);

select lives_ok(
  $$ select public.begin_import_batch(jsonb_build_object(
    'batch_name', 'pgTAP License-only fixture',
    'environment', 'local-test',
    'sources', jsonb_build_array(
      jsonb_build_object(
        'kind', 'license',
        'file_name', '03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx',
        'sha256', 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
        'file_size_bytes', 40
      )
    )
  )) $$,
  'a later License-only import remains possible after Asset-only publication'
);

select set_config(
  'test.asset_only_batch_id',
  (
    select id::text from migration.import_batches
    where batch_name = 'pgTAP Asset-only fixture'
  ),
  true
);

select lives_ok(
  $$ select public.stage_asset_rows(
    current_setting('test.asset_only_batch_id')::uuid,
    jsonb_build_array(jsonb_build_object(
      'source_file_name', '02 203Total License(TKC) Update 2026-08-28.xlsx',
      'sheet_name', 'Software(Factory)',
      'source_row_number', 7,
      'source_row_hash', repeat('e', 64),
      'raw_data', jsonb_build_object(
        'asset_type', 'pc',
        'location', 'Server Room',
        'manufacturer', 'Example Maker',
        'model', 'Example Model',
        'operating_system', 'Windows 11 Pro',
        'network_data', jsonb_build_array(
          jsonb_build_object('kind','mac','interface_name','lan','value','AA:BB:CC:DD:EE:01'),
          jsonb_build_object('kind','mac','interface_name','wifi','value','AA:BB:CC:DD:EE:02'),
          jsonb_build_object('kind','mac','interface_name','vpn','value','AA:BB:CC:DD:EE:03'),
          jsonb_build_object('kind','ip','interface_name','lan','value','10.10.0.1'),
          jsonb_build_object('kind','ip','interface_name','wifi','value','10.10.0.2'),
          jsonb_build_object('kind','ip','interface_name','vpn','value','10.10.0.2')
        ),
        'people_assignments', jsonb_build_array(
          jsonb_build_object('person_label','Alice Responsible','assignment_kind','responsible'),
          jsonb_build_object('person_label','Dave Secondary','assignment_kind','responsible'),
          jsonb_build_object('person_label','Bob Primary','assignment_kind','user'),
          jsonb_build_object('person_label','Carol Additional','assignment_kind','user')
        ),
        'installed_software', jsonb_build_array(
          jsonb_build_object('product_label','Microsoft Office'),
          jsonb_build_object('product_label','7-Zip')
        )
      ),
      'normalized_asset_code', 'ASSET-ONLY-001',
      'normalized_computer_name', 'ASSET-ONLY-PC-001',
      'normalized_site_code', 'FACTORY',
      'normalized_location_code', 'Server Room',
      'normalized_mac_address', 'AA:BB:CC:DD:EE:01',
      'normalized_ip_address', '10.10.0.1',
      'secret_present', false
    ))
  ) $$,
  'Asset-only staging accepts the complete sanitized Asset payload'
);

select lives_ok(
  $$ select public.validate_import_batch(current_setting('test.asset_only_batch_id')::uuid) $$,
  'Asset-only batch validates without a License source'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"41000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select lives_ok(
  $$ select public.publish_import_batch(
    current_setting('test.asset_only_batch_id')::uuid,
    ((public.get_import_batch_review(current_setting('test.asset_only_batch_id')::uuid)->'batch'->>'version')::integer),
    false
  ) $$,
  'eligible Asset-only batch publishes atomically'
);

reset role;

select is(
  (select count(*)::integer from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid),
  1,
  'publish creates one traced Asset'
);
select is(
  (select count(*)::integer from public.locations where name = 'Server Room'),
  1,
  'publish resolves the exact location label'
);
select is(
  (select count(*)::integer from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid and location_id is not null),
  1,
  'published Asset references its location'
);
select is(
  (select count(*)::integer from public.asset_network_interfaces where asset_id = (select id from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid)),
  2,
  'publish creates every paired LAN and Wi-Fi interface'
);
select is(
  (select count(*)::integer from public.people where primary_site_id = '01000000-0000-4000-8000-000000000001' and display_name in ('Alice Responsible','Dave Secondary','Bob Primary','Carol Additional')),
  4,
  'publish resolves people by exact Site and display name'
);
select is(
  (select count(*)::integer from public.asset_person_assignments where asset_id = (select id from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid)),
  4,
  'publish creates every Asset person assignment'
);
select is((select count(*)::integer from public.asset_person_assignments where assignment_role = 'responsible_person' and asset_id = (select id from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid)), 1, 'responsible person maps to responsible_person');
select is((select count(*)::integer from public.asset_person_assignments where assignment_role = 'primary_user' and asset_id = (select id from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid)), 1, 'first user maps to primary_user');
select is((select count(*)::integer from public.asset_person_assignments where assignment_role = 'additional_user' and asset_id = (select id from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid)), 2, 'later responsible people and users map to additional_user');
select is(
  (select count(*)::integer from public.publishers where code = 'MIGRATION_UNKNOWN'),
  1,
  'unclassified workbook software uses one migration publisher'
);
select is(
  (select count(*)::integer from public.software_products where publisher_id = (select id from public.publishers where code = 'MIGRATION_UNKNOWN') and name in ('Windows 11 Pro','Microsoft Office','7-Zip')),
  3,
  'publish creates exact software products for OS and installed software labels'
);
select is(
  (select count(*)::integer from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid and operating_system_product_id = (select id from public.software_products where name = 'Windows 11 Pro')),
  1,
  'published Asset references its operating system product'
);
select is(
  (select count(*)::integer from public.asset_software_installations where asset_id = (select id from public.assets where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid) and source = 'migration' and installation_status = 'installed'),
  2,
  'publish creates every exact installed software observation'
);
select is(
  (select count(*)::integer from audit.audit_events where entity_type = 'import_batch' and entity_id = current_setting('test.asset_only_batch_id')::uuid and action = 'publish'),
  1,
  'Asset-only publication writes one audit event'
);
select is(
  (select (new_values->>'products_created')::integer from audit.audit_events where entity_type = 'import_batch' and entity_id = current_setting('test.asset_only_batch_id')::uuid and action = 'publish'),
  3,
  'publish audit includes products created by complete Asset publication'
);
select is(
  (select pg_catalog.jsonb_object_agg(total.metric, pg_catalog.jsonb_build_object('source', total.source_total, 'target', total.target_total, 'status', total.status))
   from migration.reconciliation_totals as total
   join migration.reconciliation_runs as run on run.id = total.reconciliation_run_id
   where run.import_batch_id = current_setting('test.asset_only_batch_id')::uuid
     and total.site_id = '01000000-0000-4000-8000-000000000001'
     and total.metric in ('network_interfaces','person_assignments','software_installations','operating_system_links','location_links')),
  '{"network_interfaces":{"source":2,"target":2,"status":"matched"},"person_assignments":{"source":4,"target":4,"status":"matched"},"software_installations":{"source":2,"target":2,"status":"matched"},"operating_system_links":{"source":1,"target":1,"status":"matched"},"location_links":{"source":1,"target":1,"status":"matched"}}'::jsonb,
  'Asset reconciliation independently matches exact staged and published nested totals'
);
select is(
  (select status::text from migration.import_batches where id = current_setting('test.asset_only_batch_id')::uuid),
  'committed',
  'Asset-only batch is marked committed last'
);
select is(
  (select count(*)::integer from public.license_entitlements where migration_batch_id = current_setting('test.asset_only_batch_id')::uuid),
  0,
  'Asset-only publication creates no License entitlement'
);

select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select set_config('test.license_only_batch_id', (select id::text from migration.import_batches where batch_name = 'pgTAP License-only fixture'), true);
select lives_ok(
  $$ select public.stage_license_rows(current_setting('test.license_only_batch_id')::uuid, jsonb_build_array(
    jsonb_build_object(
    'source_file_name', '03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx',
    'sheet_name', 'Software License FACTORY', 'source_row_number', 9,
    'source_row_hash', repeat('7', 64), 'raw_data', jsonb_build_object('label','license-only'),
    'normalized_publisher', 'License-only Publisher', 'normalized_vendor', 'License-only Vendor',
    'normalized_product_name', 'License-only Product', 'normalized_version', '1',
    'normalized_classification', 'Commercial', 'normalized_purchase_form', 'Perpetual',
    'normalized_owned_quantity', 1, 'normalized_record_status', 'active'
    ),
    jsonb_build_object(
      'source_file_name', '03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx',
      'sheet_name', 'Software License FACTORY', 'source_row_number', 10,
      'source_row_hash', repeat('8', 64), 'raw_data', jsonb_build_object('label','license-only-duplicate'),
      'normalized_publisher', 'License-only Publisher', 'normalized_vendor', 'License-only Vendor',
      'normalized_product_name', 'License-only Product', 'normalized_version', '1',
      'normalized_classification', 'Commercial', 'normalized_purchase_form', 'Perpetual',
      'normalized_owned_quantity', 1, 'normalized_record_status', 'active'
    )
  )) $$,
  'License-only CLI-compatible payload stages after Asset-only publication'
);
select lives_ok(
  $$ select public.validate_import_batch(current_setting('test.license_only_batch_id')::uuid) $$,
  'License-only batch validates after Asset-only publication'
);
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"41000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select lives_ok(
  $$ select public.publish_import_batch(current_setting('test.license_only_batch_id')::uuid, ((public.get_import_batch_review(current_setting('test.license_only_batch_id')::uuid)->'batch'->>'version')::integer), false) $$,
  'License-only batch publishes after Asset-only publication'
);
reset role;
select is(
  (select pg_catalog.jsonb_object_agg(total.metric, pg_catalog.jsonb_build_object('source',total.source_total,'target',total.target_total,'status',total.status))
   from migration.reconciliation_totals as total
   join migration.reconciliation_runs as run on run.id=total.reconciliation_run_id
   where run.import_batch_id=current_setting('test.license_only_batch_id')::uuid
     and total.site_id='01000000-0000-4000-8000-000000000001'
     and total.metric in ('licenses','owned_quantity')),
  '{"licenses":{"source":1,"target":1,"status":"matched"},"owned_quantity":{"source":1,"target":1,"status":"matched"}}'::jsonb,
  'License reconciliation excludes exact duplicates intentionally skipped during publication'
);
select throws_ok(
  $$ select public.begin_import_batch(jsonb_build_object(
    'batch_name', 'duplicate Asset-only fixture',
    'environment', 'local-test',
    'sources', jsonb_build_array(
      jsonb_build_object(
        'kind', 'asset',
        'file_name', '02 203Total License(TKC) Update 2026-08-28.xlsx',
        'sha256', 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'file_size_bytes', 30
      )
    )
  )) $$,
  'P0001', 'SOURCE_ALREADY_PUBLISHED',
  'committed Asset fingerprint cannot be published twice'
);

select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select set_config(
  'test.invalid_network_batch_id',
  public.begin_import_batch(jsonb_build_object(
    'batch_name', 'pgTAP invalid network fixture',
    'environment', 'local-test',
    'sources', jsonb_build_array(
      jsonb_build_object(
        'kind', 'asset',
        'file_name', '02 203Total License(TKC) Update 2026-08-28.xlsx',
        'sha256', 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        'file_size_bytes', 50
      )
    )
  ))::text,
  true
);
select public.stage_asset_rows(
  current_setting('test.invalid_network_batch_id')::uuid,
  jsonb_build_array(jsonb_build_object(
    'source_file_name', '02 203Total License(TKC) Update 2026-08-28.xlsx',
    'sheet_name', 'Software(Factory)',
    'source_row_number', 8,
    'source_row_hash', repeat('9', 64),
    'raw_data', jsonb_build_object(
      'asset_type', 'pc',
      'network_data', jsonb_build_array(
        jsonb_build_object('kind','mac','interface_name','lan','value','NOT-A-MAC'),
        jsonb_build_object('kind','ip','interface_name','lan','value','NOT-AN-IP')
      )
    ),
    'normalized_asset_code', 'INVALID-NETWORK-001',
    'normalized_computer_name', 'INVALID-NETWORK-PC-001',
    'normalized_site_code', 'FACTORY',
    'secret_present', false
  ))
);
select public.validate_import_batch(current_setting('test.invalid_network_batch_id')::uuid);
select is(
  (public.get_import_batch_review(current_setting('test.invalid_network_batch_id')::uuid)->'summary'->>'warning_count')::integer,
  1,
  'invalid MAC or IP observations produce one review warning for the Asset row'
);

select * from finish();
rollback;
