select exists (
  select 1 from pg_catalog.pg_extension where extname = 'dblink'
) as dblink_preexisting
\gset cleanup_

begin;

select plan(155);

select has_table('public', 'publishers', 'publishers table exists');
select has_table('public', 'software_products', 'software products table exists');
select has_table('public', 'assets', 'assets table exists');
select has_index(
  'public',
  'assets',
  'assets_asset_code_trgm_idx',
  'asset code trigram index exists'
);
select has_index(
  'public',
  'assets',
  'assets_computer_name_trgm_idx',
  'computer name trigram index exists'
);
select has_table('public', 'asset_network_interfaces', 'network interfaces table exists');
select has_table('public', 'asset_person_assignments', 'person assignments table exists');
select has_table('public', 'asset_software_installations', 'software installations table exists');
select has_table('public', 'vendors', 'vendors table exists');
select has_table('public', 'license_entitlements', 'license entitlements table exists');
select has_table('public', 'license_site_scopes', 'license site scopes table exists');
select has_table('public', 'license_allocations', 'license allocations table exists');
select has_table('private', 'license_secrets', 'private license secrets table exists');
select has_table('public', 'notifications', 'notifications table exists');
select has_table('audit', 'audit_events', 'audit events table exists');
select has_table('public', 'system_settings', 'system settings table exists');
select has_table('migration', 'import_batches', 'import batches table exists');
select has_table('migration', 'asset_staging_rows', 'asset staging table exists');
select has_table('migration', 'license_staging_rows', 'license staging table exists');

insert into public.publishers (id, code, name_th, name_en)
values ('20000000-0000-4000-8000-000000000001', 'MICROSOFT', 'ไมโครซอฟท์', 'Microsoft');

insert into public.software_products (
  id, publisher_id, category_id, name, version_edition, support_status
)
values
  (
    '21000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000001',
    'Windows Test',
    '11',
    'supported'
  ),
  (
    '21000000-0000-4000-8000-000000000002',
    '20000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000001',
    'Archive Product',
    '1',
    'supported'
  ),
  (
    '21000000-0000-4000-8000-000000000003',
    '20000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000001',
    'Status Without Reason Product',
    '1',
    'supported'
  ),
  (
    '21000000-0000-4000-8000-000000000004',
    '20000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000001',
    'Status With Reason Product',
    '1',
    'supported'
  );

insert into public.assets (
  id, asset_code, computer_name, asset_type_id, asset_status_id, site_id
)
values
  (
    '22000000-0000-4000-8000-000000000001',
    'TKC-001',
    'TKC-PC-001',
    '10000000-0000-4000-8000-000000000001',
    '11000000-0000-4000-8000-000000000001',
    '01000000-0000-4000-8000-000000000001'
  ),
  (
    '22000000-0000-4000-8000-000000000002',
    'TKC-ARCHIVE',
    'TKC-PC-ARCHIVE',
    '10000000-0000-4000-8000-000000000001',
    '11000000-0000-4000-8000-000000000001',
    '01000000-0000-4000-8000-000000000001'
  ),
  (
    '22000000-0000-4000-8000-000000000003',
    'TKC-STATUS-NO-REASON',
    'TKC-PC-STATUS-NO-REASON',
    '10000000-0000-4000-8000-000000000001',
    '11000000-0000-4000-8000-000000000001',
    '01000000-0000-4000-8000-000000000001'
  ),
  (
    '22000000-0000-4000-8000-000000000004',
    'TKC-STATUS-REASON',
    'TKC-PC-STATUS-REASON',
    '10000000-0000-4000-8000-000000000001',
    '11000000-0000-4000-8000-000000000001',
    '01000000-0000-4000-8000-000000000001'
  );

select throws_ok(
  $$
    insert into public.assets (
      asset_code, asset_type_id, asset_status_id, site_id
    ) values (
      'tkc-001',
      '10000000-0000-4000-8000-000000000001',
      '11000000-0000-4000-8000-000000000001',
      '01000000-0000-4000-8000-000000000002'
    )
  $$,
  '23505',
  null,
  'active asset codes are unique without case sensitivity'
);

select throws_ok(
  $$
    insert into public.asset_network_interfaces (
      asset_id, interface_type, mac_address, address_mode
    ) values (
      '22000000-0000-4000-8000-000000000001',
      'lan',
      'invalid-mac',
      'dhcp'
    )
  $$,
  '23514',
  null,
  'invalid normalized MAC addresses are rejected'
);

insert into public.license_entitlements (
  id, software_product_id, license_metric_id, owned_quantity,
  record_status, scope_mode
)
values (
  '23000000-0000-4000-8000-000000000001',
  '21000000-0000-4000-8000-000000000001',
  '14000000-0000-4000-8000-000000000001',
  2,
  'active',
  'all_sites'
);

select throws_ok(
  $$
    insert into public.license_allocations (
      license_entitlement_id, target_type, asset_id, person_id,
      quantity, allocated_at
    ) values (
      '23000000-0000-4000-8000-000000000001',
      'asset',
      '22000000-0000-4000-8000-000000000001',
      '00000000-0000-4000-8000-000000000099',
      1,
      current_date
    )
  $$,
  '23514',
  null,
  'allocation target columns must match target type'
);

select throws_ok(
  $$
    insert into public.license_allocations (
      license_entitlement_id, target_type, asset_id, quantity, allocated_at
    ) values (
      '23000000-0000-4000-8000-000000000001',
      'asset',
      '22000000-0000-4000-8000-000000000001',
      0,
      current_date
    )
  $$,
  '23514',
  null,
  'allocation quantity must be positive'
);

insert into public.license_allocations (
  id, license_entitlement_id, target_type, asset_id, quantity, allocated_at
)
values (
  '23000000-0000-4000-8000-000000000002',
  '23000000-0000-4000-8000-000000000001',
  'asset',
  '22000000-0000-4000-8000-000000000002',
  1,
  current_date
);

insert into public.license_entitlements (
  id, license_reference, software_product_id, license_metric_id,
  owned_quantity, record_status, scope_mode, owner_name
)
values
  (
    '23000000-0000-4000-8000-000000000003',
    'ARCHIVE-LICENSE',
    '21000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000001',
    1,
    'active',
    'all_sites',
    null
  ),
  (
    '23000000-0000-4000-8000-000000000004',
    'CROSS-ENTITLEMENT-CARRIER',
    '21000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000001',
    1,
    'active',
    'all_sites',
    'CROSS-ENTITLEMENT-RESERVED'
  );

insert into audit.audit_events (
  actor_type, action, entity_type, entity_id, description, new_values
)
values (
  'migration',
  'update',
  'license_entitlement',
  '23000000-0000-4000-8000-000000000004',
  'Historical License snapshot fixture',
  pg_catalog.jsonb_build_object('remark', 'HISTORY-ONLY-RESERVED')
);

select is(
  (select count(*)::integer from public.system_settings),
  1,
  'system settings contains exactly one row'
);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
values
  (
    '24000000-0000-4000-8000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'asset-admin@test.local',
    crypt('local-test-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
  ),
  (
    '24000000-0000-4000-8000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'asset-user@test.local',
    crypt('local-test-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
  );

update public.profiles
set app_role = 'admin'
where id = '24000000-0000-4000-8000-000000000001';

insert into public.notifications (
  id, notification_type, severity, title, message,
  deduplication_key, event_date
)
values (
  '25000000-0000-4000-8000-000000000001',
  'job_failure',
  'warning',
  'TDD notification',
  'TDD notification message',
  'task-2-tdd-notification',
  current_date
);

insert into public.notification_recipients (
  id, notification_id, profile_id, delivered_at
)
values
  (
    '25000000-0000-4000-8000-000000000002',
    '25000000-0000-4000-8000-000000000001',
    '24000000-0000-4000-8000-000000000002',
    now()
  ),
  (
    '25000000-0000-4000-8000-000000000003',
    '25000000-0000-4000-8000-000000000001',
    '24000000-0000-4000-8000-000000000001',
    now()
  );

select set_config('test.asset_id', '22000000-0000-4000-8000-000000000001', true);
select set_config('test.product_id', '21000000-0000-4000-8000-000000000001', true);
select set_config('test.license_id', '23000000-0000-4000-8000-000000000001', true);
select set_config('test.notification_id', '25000000-0000-4000-8000-000000000002', true);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

select throws_ok(
  $$ select public.create_asset('{}'::jsonb) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot create an asset'
);

select throws_ok(
  $$ select public.update_asset('22000000-0000-4000-8000-000000000001', 1, '{}'::jsonb) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot update an asset'
);

select throws_ok(
  $$ select public.archive_asset(
    '22000000-0000-4000-8000-000000000001', 1, 'Denied archive', false
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot archive an asset'
);

select throws_ok(
  $$ select public.create_software_product('{}'::jsonb) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot create a software product'
);

select throws_ok(
  $$ select public.update_software_product(
    '21000000-0000-4000-8000-000000000001', 1, '{}'::jsonb
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot update a software product'
);

select throws_ok(
  $$ select public.archive_software_product(
    '21000000-0000-4000-8000-000000000001', 1, 'Denied archive'
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot archive a software product'
);

select throws_ok(
  $$ select public.create_license_entitlement('{}'::jsonb, '{}'::jsonb) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot create a license entitlement'
);

select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.license_id')::uuid, 1, '{}'::jsonb
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot update a license entitlement'
);

select throws_ok(
  $$ select public.archive_license_entitlement(
    current_setting('test.license_id')::uuid, 1, 'Denied archive'
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot archive a license entitlement'
);

select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.license_id')::uuid,
    'license_key',
    'DENIED-SECRET',
    'Denied rotation'
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot rotate a license secret'
);

select throws_ok(
  $$ select public.reveal_license_secret(
    current_setting('test.license_id')::uuid,
    'license_key',
    gen_random_uuid()
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot reveal a license secret'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select lives_ok(
  $$
    select public.create_asset(
      jsonb_build_object(
        'asset_code', 'TDD-CREATED-ASSET',
        'computer_name', 'TDD-CREATED-PC',
        'asset_type_id', '10000000-0000-4000-8000-000000000001',
        'asset_status_id', '11000000-0000-4000-8000-000000000001',
        'site_id', '01000000-0000-4000-8000-000000000001'
      )
    )
  $$,
  'admin creates an asset through the command'
);

select is(
  (
    select count(*)::integer
    from public.assets
    where asset_code = 'TDD-CREATED-ASSET'
      and archived_at is null
  ),
  1,
  'create_asset persists the active asset'
);

select throws_ok(
  $$
    select public.create_asset(
      jsonb_build_object(
        'asset_code', 'tdd-created-asset',
        'computer_name', 'TDD-DUPLICATE-CREATE-PC',
        'asset_type_id', '10000000-0000-4000-8000-000000000001',
        'asset_status_id', '11000000-0000-4000-8000-000000000001',
        'site_id', '01000000-0000-4000-8000-000000000001'
      )
    )
  $$,
  '23505', 'DUPLICATE_RECORD',
  'asset create maps an exact unique-index conflict to DUPLICATE_RECORD'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where action = 'create'
      and entity_type = 'asset'
      and entity_id = (
        select id from public.assets where asset_code = 'TDD-CREATED-ASSET'
      )
  ),
  1,
  'create_asset writes an audit event'
);

select lives_ok(
  $$ select public.update_asset(
    current_setting('test.asset_id')::uuid,
    1,
    jsonb_build_object('computer_name', 'TDD-PC-UPDATED')
  ) $$,
  'admin updates an asset with the expected version'
);

select throws_ok(
  $$ select public.update_asset(
    current_setting('test.asset_id')::uuid,
    2,
    jsonb_build_object('asset_code', 'TDD-CREATED-ASSET')
  ) $$,
  '23505', 'DUPLICATE_RECORD',
  'asset update maps an exact unique-index conflict to DUPLICATE_RECORD'
);

select throws_ok(
  $$
    select public.update_asset(
      current_setting('test.asset_id')::uuid,
      1,
      jsonb_build_object(
        'asset_status_id', '00000000-0000-0000-0000-000000000099'
      )
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'stale asset updates win over reference validation'
);

select throws_ok(
  $$
    select public.update_asset(
      '00000000-0000-0000-0000-000000000098',
      1,
      jsonb_build_object(
        'asset_status_id', '00000000-0000-0000-0000-000000000099'
      )
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'missing asset updates win over reference validation'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'asset'
      and entity_id = current_setting('test.asset_id')::uuid
      and new_values->>'computer_name' = 'TDD-PC-UPDATED'
  ),
  1,
  'update_asset writes an audit event'
);

select throws_ok(
  $$
    select public.update_asset(
      '22000000-0000-4000-8000-000000000003',
      1,
      jsonb_build_object(
        'asset_status_id', '11000000-0000-4000-8000-000000000002'
      )
    )
  $$,
  '22023', 'REASON_REQUIRED',
  'asset status transitions require a reason'
);

select lives_ok(
  $$
    select public.update_asset(
      '22000000-0000-4000-8000-000000000004',
      1,
      jsonb_build_object(
        'asset_status_id', '11000000-0000-4000-8000-000000000001'
      )
    )
  $$,
  'unchanged asset status does not require a reason'
);

select lives_ok(
  $$
    select public.update_asset(
      '22000000-0000-4000-8000-000000000004',
      2,
      jsonb_build_object(
        'asset_status_id', '11000000-0000-4000-8000-000000000002',
        'reason', 'Asset lifecycle status changed'
      )
    )
  $$,
  'asset status transitions accept a reason'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'asset'
      and entity_id = '22000000-0000-4000-8000-000000000004'
      and new_values->>'asset_status_id' = '11000000-0000-4000-8000-000000000002'
  ),
  'Asset lifecycle status changed',
  'asset status transition reason is written to audit'
);

select throws_ok(
  $$
    select public.archive_asset(
      '22000000-0000-4000-8000-000000000002',
      99,
      'Stale allocated asset',
      false
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'stale asset archive wins over allocation validation'
);

select throws_ok(
  $$
    select public.archive_asset(
      '00000000-0000-0000-0000-000000000098',
      1,
      '',
      false
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'missing asset archive wins over reason validation'
);

select throws_ok(
  $$
    select public.archive_asset(
      '22000000-0000-4000-8000-000000000002',
      1,
      'Allocated asset needs acknowledgement',
      false
    )
  $$,
  'P0001', 'ACTIVE_ALLOCATIONS_EXIST',
  'asset archive blocks unacknowledged active allocations'
);

select lives_ok(
  $$
    select public.archive_asset(
      '22000000-0000-4000-8000-000000000002',
      1,
      'Allocated asset acknowledged',
      true
    )
  $$,
  'asset archive accepts explicit allocation acknowledgement'
);

select isnt(
  (
    select archived_at
    from public.assets
    where id = '22000000-0000-4000-8000-000000000002'
  ),
  null,
  'archive_asset preserves the row with archive metadata'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'archive'
      and entity_type = 'asset'
      and entity_id = '22000000-0000-4000-8000-000000000002'
  ),
  'Allocated asset acknowledged',
  'archive_asset writes its reason to audit'
);

select lives_ok(
  $$
    select public.create_software_product(
      jsonb_build_object(
        'publisher_id', '20000000-0000-4000-8000-000000000001',
        'category_id', '13000000-0000-4000-8000-000000000001',
        'name', 'TDD Created Product',
        'version_edition', '1',
        'support_status', 'supported'
      )
    )
  $$,
  'admin creates a software product through the command'
);

select is(
  (
    select count(*)::integer
    from public.software_products
    where name = 'TDD Created Product'
      and version_edition = '1'
      and archived_at is null
  ),
  1,
  'create_software_product persists the active product'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where action = 'create'
      and entity_type = 'software_product'
      and entity_id = (
        select id
        from public.software_products
        where name = 'TDD Created Product' and version_edition = '1'
      )
  ),
  1,
  'create_software_product writes an audit event'
);

select throws_ok(
  $$
    select public.create_software_product(
      jsonb_build_object(
        'publisher_id', '20000000-0000-4000-8000-000000000001',
        'category_id', '13000000-0000-4000-8000-000000000001',
        'name', 'tdd created product',
        'version_edition', '1'
      )
    )
  $$,
  '23505', 'DUPLICATE_RECORD',
  'software create maps the normalized business-key duplicate'
);

select lives_ok(
  $$
    select public.update_software_product(
      current_setting('test.product_id')::uuid,
      1,
      jsonb_build_object('name', 'Windows Test Updated')
    )
  $$,
  'admin updates a software product with the expected version'
);

select throws_ok(
  $$ select public.update_software_product(
    current_setting('test.product_id')::uuid,
    2,
    jsonb_build_object(
      'name', 'TDD Created Product',
      'version_edition', '1'
    )
  ) $$,
  '23505', 'DUPLICATE_RECORD',
  'software update maps an exact business-key conflict to DUPLICATE_RECORD'
);

select throws_ok(
  $$
    select public.update_software_product(
      current_setting('test.product_id')::uuid,
      1,
      jsonb_build_object(
        'publisher_id', '00000000-0000-0000-0000-000000000099'
      )
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'stale software updates win over reference validation'
);

select throws_ok(
  $$
    select public.update_software_product(
      '00000000-0000-0000-0000-000000000098',
      1,
      jsonb_build_object(
        'publisher_id', '00000000-0000-0000-0000-000000000099'
      )
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'missing software updates win over reference validation'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'software_product'
      and entity_id = current_setting('test.product_id')::uuid
      and new_values->>'name' = 'Windows Test Updated'
  ),
  1,
  'update_software_product writes an audit event'
);

select throws_ok(
  $$
    select public.update_software_product(
      '21000000-0000-4000-8000-000000000003',
      1,
      jsonb_build_object('support_status', 'eol')
    )
  $$,
  '22023', 'REASON_REQUIRED',
  'software support transitions require a reason'
);

select lives_ok(
  $$
    select public.update_software_product(
      '21000000-0000-4000-8000-000000000004',
      1,
      jsonb_build_object('support_status', 'supported')
    )
  $$,
  'unchanged software support status does not require a reason'
);

select lives_ok(
  $$
    select public.update_software_product(
      '21000000-0000-4000-8000-000000000004',
      2,
      jsonb_build_object(
        'support_status', 'eol',
        'reason', 'Vendor support ended'
      )
    )
  $$,
  'software support transitions accept a reason'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'software_product'
      and entity_id = '21000000-0000-4000-8000-000000000004'
      and new_values->>'support_status' = 'eol'
  ),
  'Vendor support ended',
  'software support transition reason is written to audit'
);

select throws_ok(
  $$ select public.archive_software_product(
    '21000000-0000-4000-8000-000000000002', 1, ''
  ) $$,
  '22023', 'REASON_REQUIRED',
  'software archive requires a reason'
);

select throws_ok(
  $$ select public.archive_software_product(
    '21000000-0000-4000-8000-000000000002', 99, ''
  ) $$,
  '40001', 'VERSION_CONFLICT',
  'stale software archive wins over reason validation'
);

select throws_ok(
  $$ select public.archive_software_product(
    '00000000-0000-0000-0000-000000000098', 1, ''
  ) $$,
  '40001', 'VERSION_CONFLICT',
  'missing software archive wins over reason validation'
);

select lives_ok(
  $$ select public.archive_software_product(
    '21000000-0000-4000-8000-000000000002', 1, 'Product retired'
  ) $$,
  'admin archives a software product with a reason'
);

select isnt(
  (
    select archived_at
    from public.software_products
    where id = '21000000-0000-4000-8000-000000000002'
  ),
  null,
  'archive_software_product preserves the row with archive metadata'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'archive'
      and entity_type = 'software_product'
      and entity_id = '21000000-0000-4000-8000-000000000002'
  ),
  'Product retired',
  'archive_software_product writes its reason to audit'
);

select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.license_id')::uuid,
    1,
    jsonb_build_object('owned_quantity', 0)
  ) $$,
  'P0001', 'OWNED_BELOW_ALLOCATED',
  'owned quantity cannot fall below active allocation'
);

select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.license_id')::uuid,
    1,
    jsonb_build_object('license_key', 'PLAINTEXT-IN-ORDINARY-PAYLOAD')
  ) $$,
  '22023', 'INVALID_PAYLOAD',
  'ordinary license updates reject secret fields'
);

select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.license_id')::uuid,
    1,
    jsonb_build_object('record_status', 'deactivated')
  ) $$,
  '22023', 'REASON_REQUIRED',
  'license lifecycle transitions require a reason'
);

select throws_ok(
  $$ select public.archive_license_entitlement(
    current_setting('test.license_id')::uuid,
    1,
    'retired contract'
  ) $$,
  'P0001', 'ACTIVE_ALLOCATIONS_EXIST',
  'license with active allocations cannot be archived'
);

reset role;
savepoint missing_pepper_isolation;
delete from vault.secrets
where name = 'sam_license_fingerprint_pepper';
set local role authenticated;

select throws_ok(
  $$
    select public.create_license_entitlement(
      jsonb_build_object(
        'license_reference', 'NO-PEPPER-LICENSE',
        'software_product_id', current_setting('test.product_id'),
        'owned_quantity', 1,
        'license_metric', 'device'
      ),
      jsonb_build_object('license_key', 'NO-PEPPER-KEY')
    )
  $$,
  'P0001', 'SECRET_PEPPER_NOT_CONFIGURED',
  'secret writes fail closed when the Vault fingerprint pepper is missing'
);

select is(
  (
    select count(*)::integer
    from public.license_entitlements
    where license_reference = 'NO-PEPPER-LICENSE'
  ),
  0,
  'missing pepper failure leaves no entitlement row'
);

reset role;
rollback to savepoint missing_pepper_isolation;
create extension if not exists dblink with schema extensions;

do $concurrency_pepper$
declare
  pepper_id uuid;
  pepper_created boolean;
begin
  perform extensions.dblink_connect(
    'concurrency_pepper_fixture',
    'host=supabase_db_software-asset-management port=5432 dbname=postgres user=postgres password=postgres'
  );
  select result.id, result.created
  into strict pepper_id, pepper_created
  from extensions.dblink(
    'concurrency_pepper_fixture',
    $remote$
      with existing as materialized (
        select secret.id
        from vault.secrets as secret
        where secret.name = 'sam_license_fingerprint_pepper'
        order by secret.created_at desc
        limit 1
      ),
      created as (
        select vault.create_secret(
            'TDD-ONLY-CONCURRENCY-PEPPER',
            'sam_license_fingerprint_pepper',
            'Disposable local concurrency pepper'
          ) as id
        where not exists (select 1 from existing)
      )
      select existing.id, false as created from existing
      union all
      select created.id, true as created from created
    $remote$
  ) as result(id uuid, created boolean);

  perform set_config('test.concurrent_pepper_id', pepper_id::text, true);
  perform set_config(
    'test.concurrent_pepper_created',
    pepper_created::text,
    true
  );
  perform extensions.dblink_disconnect('concurrency_pepper_fixture');
end;
$concurrency_pepper$;

-- Establish committed fixtures before this transaction's first successful
-- License mutation retains the transaction-level plaintext boundary lock.
create or replace function private.test_open_concurrent_session(
  connection_name text,
  actor_id uuid
)
returns void
language plpgsql
set search_path = ''
as $$
begin
  perform extensions.dblink_connect(
    connection_name,
    'host=supabase_db_software-asset-management port=5432 dbname=postgres user=postgres password=postgres'
  );
  perform extensions.dblink_exec(connection_name, 'begin');
  perform extensions.dblink_exec(
    connection_name,
    'set local statement_timeout = ''10s'''
  );
  perform extensions.dblink_exec(
    connection_name,
    'set local idle_in_transaction_session_timeout = ''10s'''
  );
  perform extensions.dblink_exec(
    connection_name,
    pg_catalog.format(
      'set local "request.jwt.claims" = %L',
      pg_catalog.jsonb_build_object(
        'sub', actor_id,
        'role', 'authenticated'
      )::text
    )
  );
  perform extensions.dblink_exec(
    connection_name,
    'set local role authenticated'
  );
end;
$$;

create or replace function private.test_backend_reaches_wait(
  backend_pid integer,
  expected_event text,
  expected_event_type text
)
returns boolean
language plpgsql
set search_path = ''
as $$
declare
  attempt integer;
  observed boolean;
begin
  for attempt in 1..40 loop
    perform pg_catalog.pg_stat_clear_snapshot();

    select exists (
      select 1
      from pg_catalog.pg_stat_activity as activity
      where activity.pid = test_backend_reaches_wait.backend_pid
        and (
          test_backend_reaches_wait.expected_event is null
          or activity.wait_event =
            test_backend_reaches_wait.expected_event
        )
        and (
          test_backend_reaches_wait.expected_event_type is null
          or activity.wait_event_type =
            test_backend_reaches_wait.expected_event_type
        )
    )
    into observed;

    if observed then
      return true;
    end if;

    if not exists (
      select 1
      from pg_catalog.pg_stat_activity as activity
      where activity.pid = test_backend_reaches_wait.backend_pid
    ) then
      return false;
    end if;

    perform pg_catalog.pg_sleep(0.05);
  end loop;

  return false;
end;
$$;

select set_config(
  'test.concurrent_admin_a',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_admin_b',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_publisher_id',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_product_id',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_asset_id',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_asset_license_id',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_license_a',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_license_b',
  extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_reserved_value',
  'CONCURRENT-RESERVED-' || extensions.gen_random_uuid()::text,
  true
);
select set_config(
  'test.concurrent_original_secret',
  'CONCURRENT-ORIGINAL-' || extensions.gen_random_uuid()::text,
  true
);
do $fixture$
declare
  connection_string constant text :=
    'host=supabase_db_software-asset-management port=5432 dbname=postgres user=postgres password=postgres';
  license_vault_id uuid;
begin
  perform extensions.dblink_connect('concurrency_fixture', connection_string);

  -- dblink fixtures commit outside pgTAP's rollback. Neutralize actors from a
  -- prior focused run so the global last-Admin invariant remains repeatable.
  perform extensions.dblink_exec(
    'concurrency_fixture',
    $remote$
      update public.profiles
      set app_role = 'user'::public.app_role,
          account_status = 'inactive'::public.account_status,
          deactivated_at = pg_catalog.now(),
          deactivated_by = null
      where email like 'concurrency-%@test.local'
    $remote$
  );

  perform extensions.dblink_exec(
    'concurrency_fixture',
    pg_catalog.format(
      $remote$
        insert into auth.users (
          id, instance_id, aud, role, email, encrypted_password,
          email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
          created_at, updated_at, confirmation_token, email_change,
          email_change_token_new, recovery_token
        ) values
          (
            %L::uuid, '00000000-0000-0000-0000-000000000000'::uuid,
            'authenticated', 'authenticated', %L, '', pg_catalog.now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{}'::jsonb, pg_catalog.now(), pg_catalog.now(), '', '', '', ''
          ),
          (
            %L::uuid, '00000000-0000-0000-0000-000000000000'::uuid,
            'authenticated', 'authenticated', %L, '', pg_catalog.now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{}'::jsonb, pg_catalog.now(), pg_catalog.now(), '', '', '', ''
          )
      $remote$,
      current_setting('test.concurrent_admin_a'),
      'concurrency-' || current_setting('test.concurrent_admin_a') || '@test.local',
      current_setting('test.concurrent_admin_b'),
      'concurrency-' || current_setting('test.concurrent_admin_b') || '@test.local'
    )
  );

  perform extensions.dblink_exec(
    'concurrency_fixture',
    pg_catalog.format(
      'update public.profiles set app_role = ''admin'' where id in (%L::uuid, %L::uuid)',
      current_setting('test.concurrent_admin_a'),
      current_setting('test.concurrent_admin_b')
    )
  );

  perform extensions.dblink_exec(
    'concurrency_fixture',
    pg_catalog.format(
      'insert into public.publishers (id, code, name_th) values (%L::uuid, %L, %L)',
      current_setting('test.concurrent_publisher_id'),
      'CONCURRENT_' || pg_catalog.replace(
        current_setting('test.concurrent_publisher_id'), '-', ''
      ),
      'Concurrency Publisher'
    )
  );

  perform extensions.dblink_exec(
    'concurrency_fixture',
    pg_catalog.format(
      $remote$
        insert into public.software_products (
          id, publisher_id, category_id, name, version_edition,
          support_status
        ) values (
          %L::uuid, %L::uuid,
          '13000000-0000-4000-8000-000000000001'::uuid,
          %L, '1', 'supported'
        )
      $remote$,
      current_setting('test.concurrent_product_id'),
      current_setting('test.concurrent_publisher_id'),
      'Concurrency Product ' || current_setting('test.concurrent_product_id')
    )
  );

  perform extensions.dblink_exec(
    'concurrency_fixture',
    pg_catalog.format(
      $remote$
        insert into public.assets (
          id, asset_code, computer_name, asset_type_id,
          asset_status_id, site_id
        ) values (
          %L::uuid, %L, %L,
          '10000000-0000-4000-8000-000000000001'::uuid,
          '11000000-0000-4000-8000-000000000001'::uuid,
          '01000000-0000-4000-8000-000000000001'::uuid
        )
      $remote$,
      current_setting('test.concurrent_asset_id'),
      'CONCURRENT-ASSET-' || current_setting('test.concurrent_asset_id'),
      'CONCURRENT-PC-' || current_setting('test.concurrent_asset_id')
    )
  );

  perform extensions.dblink_exec(
    'concurrency_fixture',
    pg_catalog.format(
      $remote$
        insert into public.license_entitlements (
          id, license_reference, software_product_id, license_metric_id,
          owned_quantity, record_status, scope_mode
        ) values
          (
            %L::uuid, %L, %L::uuid,
            '14000000-0000-4000-8000-000000000001'::uuid,
            1, 'active', 'all_sites'
          ),
          (
            %L::uuid, %L, %L::uuid,
            '14000000-0000-4000-8000-000000000001'::uuid,
            1, 'active', 'all_sites'
          ),
          (
            %L::uuid, %L, %L::uuid,
            '14000000-0000-4000-8000-000000000001'::uuid,
            1, 'active', 'all_sites'
          )
      $remote$,
      current_setting('test.concurrent_asset_license_id'),
      'CONCURRENT-ASSET-LICENSE-' || current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_product_id'),
      current_setting('test.concurrent_license_a'),
      'CONCURRENT-LICENSE-A-' || current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_product_id'),
      current_setting('test.concurrent_license_b'),
      'CONCURRENT-LICENSE-B-' || current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_product_id')
    )
  );

  select created.vault_id
  into strict license_vault_id
  from extensions.dblink(
    'concurrency_fixture',
    pg_catalog.format(
      $remote$
        with created_secret as (
          select vault.create_secret(%L, %L, 'Concurrency test key') as id
        ),
        inserted_reference as (
          insert into private.license_secrets (
            license_entitlement_id, license_key_vault_secret_id,
            license_key_fingerprint
          )
          select
            %L::uuid,
            created_secret.id,
            private.fingerprint_license_secret('license_key', %L)
          from created_secret
          returning license_key_vault_secret_id
        )
        select license_key_vault_secret_id from inserted_reference
      $remote$,
      current_setting('test.concurrent_original_secret'),
      'sam_license_' || current_setting('test.concurrent_license_b') || '_license_key',
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_original_secret')
    )
  ) as created(vault_id uuid);

  perform set_config(
    'test.concurrent_license_vault_id',
    license_vault_id::text,
    true
  );

  perform extensions.dblink_disconnect('concurrency_fixture');
end;
$fixture$;
-- Run the License inverse-write schedule before this pgTAP transaction can
-- retain the production transaction-level boundary from ordinary test calls.
select private.test_open_concurrent_session(
  'license_ordinary_session',
  current_setting('test.concurrent_admin_a')::uuid
);
select private.test_open_concurrent_session(
  'license_secret_session',
  current_setting('test.concurrent_admin_a')::uuid
);

select set_config(
  'test.license_secret_backend_pid',
  (
    select response.backend_pid::text
    from extensions.dblink(
      'license_secret_session',
      'select pg_catalog.pg_backend_pid()'
    ) as response(backend_pid integer)
  ),
  true
);

select is(
  (
    select response.entitlement_id
    from extensions.dblink(
      'license_ordinary_session',
      pg_catalog.format(
        'select (public.update_license_entitlement(%L::uuid, 1, %L::jsonb)).id::text',
        current_setting('test.concurrent_license_a'),
        pg_catalog.jsonb_build_object(
          'remark', current_setting('test.concurrent_reserved_value')
        )::text
      )
    )
      as response(entitlement_id text)
  ),
  current_setting('test.concurrent_license_a'),
  'ordinary License write completes while its transaction stays open'
);

select extensions.dblink_send_query(
  'license_secret_session',
  pg_catalog.format(
    'select (public.rotate_license_secret(%L::uuid, ''license_key'', %L, %L)).id::text',
    current_setting('test.concurrent_license_b'),
    current_setting('test.concurrent_reserved_value'),
    'Concurrent collision attempt'
  )
);
select pg_catalog.pg_sleep(0.25);

select ok(
  private.test_backend_reaches_wait(
    current_setting('test.license_secret_backend_pid')::integer,
    'advisory',
    'Lock'
  ),
  'ordinary and secret License writes wait on the shared transaction advisory lock'
);

select extensions.dblink_exec('license_ordinary_session', 'commit');

select count(*)
from extensions.dblink_get_result('license_secret_session', false)
  as response(entitlement_id text);

select is(
  pg_catalog.split_part(
    extensions.dblink_error_message('license_secret_session'),
    E'\n', 1
  ),
  'ERROR:  LICENSE_SECRET_COLLISION',
  'waiting secret rotation rejects with the exact generic collision error'
);

select count(*)
from extensions.dblink_get_result('license_secret_session', false)
  as response(entitlement_id text);

select extensions.dblink_exec('license_secret_session', 'commit', false);

select is(
  (
    select count(*)
    from public.license_entitlements as entitlement
    join private.license_secrets as secret
      on secret.license_entitlement_id =
        current_setting('test.concurrent_license_b')::uuid
    where entitlement.id = current_setting('test.concurrent_license_a')::uuid
      and entitlement.remark = current_setting('test.concurrent_reserved_value')
      and secret.license_key_fingerprint =
        private.fingerprint_license_secret(
          'license_key',
          current_setting('test.concurrent_reserved_value')
        )
  ),
  0::bigint,
  'concurrent inverse writes cannot commit a global secret/plaintext collision'
);

select extensions.dblink_disconnect('license_ordinary_session');
select extensions.dblink_disconnect('license_secret_session');

do $$
begin
  if not exists (
    select 1
    from vault.decrypted_secrets
    where name = 'sam_license_fingerprint_pepper'
  ) then
    perform vault.create_secret(
      'TDD-ONLY-FINGERPRINT-PEPPER',
      'sam_license_fingerprint_pepper',
      'Disposable pgTAP pepper'
    );
  end if;
end;
$$;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

savepoint create_secret_collision_raw;
select throws_ok(
  $$
    select public.create_license_entitlement(
      jsonb_build_object(
        'license_reference', 'CREATE-RAW-SECRET-001',
        'software_product_id', current_setting('test.product_id'),
        'owned_quantity', 1,
        'license_metric', 'device'
      ),
      jsonb_build_object('license_key', 'CREATE-RAW-SECRET-001')
    )
  $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license create rejects raw secret plaintext in an ordinary field'
);
rollback to savepoint create_secret_collision_raw;

savepoint create_secret_collision_normalized;
select throws_ok(
  $$
    select public.create_license_entitlement(
      jsonb_build_object(
        'license_reference', 'CREATE-COLLISION-NORMALIZED',
        'software_product_id', current_setting('test.product_id'),
        'owned_quantity', 1,
        'license_metric', 'device',
        'remark', ' create secret 002 '
      ),
      jsonb_build_object('license_key', 'CREATE-SECRET-002')
    )
  $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license create rejects normalized secret plaintext in an audited field'
);
rollback to savepoint create_secret_collision_normalized;

select lives_ok(
  $$
    select set_config(
      'test.created_license_id',
      (
        select id::text
        from public.create_license_entitlement(
          jsonb_build_object(
            'license_reference', 'TDD-SECRET-LICENSE',
            'software_product_id', current_setting('test.product_id'),
            'owned_quantity', 1,
            'license_metric', 'device',
            'record_status', 'active',
            'scope_mode', 'all_sites'
          ),
          jsonb_build_object(
            'license_key', 'TEST-KEY-001',
            'serial_number', 'SERIAL 001'
          )
        )
      ),
      true
    )
  $$,
  'admin creates an entitlement and stores supplied secrets through Vault'
);

select results_eq(
  $$
    select
      right(license_key_masked, 5),
      license_key_masked = 'TEST-KEY-001',
      right(serial_number_masked, 5),
      serial_number_masked = 'SERIAL 001'
    from public.license_entitlements
    where id = current_setting('test.created_license_id')::uuid
  $$,
  $$ values ('Y-001'::text, false, 'L 001'::text, false) $$,
  'license create stores suffix masks instead of plaintext'
);

reset role;

select results_eq(
  $$
    select
      license_key_vault_secret_id is not null,
      serial_vault_secret_id is not null
    from private.license_secrets
    where license_entitlement_id = current_setting('test.created_license_id')::uuid
  $$,
  $$ values (true, true) $$,
  'license create stores only non-null Vault references in the private row'
);

select is(
  (
    select pg_catalog.jsonb_build_array(
      license_key.decrypted_secret,
      serial.decrypted_secret
    )
    from private.license_secrets as secret_ref
    join vault.decrypted_secrets as license_key
      on license_key.id = secret_ref.license_key_vault_secret_id
    join vault.decrypted_secrets as serial
      on serial.id = secret_ref.serial_vault_secret_id
    where secret_ref.license_entitlement_id =
      current_setting('test.created_license_id')::uuid
  ),
  '["TEST-KEY-001", "SERIAL 001"]'::jsonb,
  'license create writes both plaintext values only to Vault'
);

select results_eq(
  $$
    select
      license_key_fingerprint is not null,
      serial_fingerprint is not null
    from private.license_secrets
    where license_entitlement_id = current_setting('test.created_license_id')::uuid
  $$,
  $$ values (true, true) $$,
  'license create writes HMAC fingerprints to the private row'
);

select set_config(
  'test.license_key_vault_id',
  license_key_vault_secret_id::text,
  true
)
from private.license_secrets
where license_entitlement_id = current_setting('test.created_license_id')::uuid;

select set_config(
  'test.license_key_fingerprint',
  encode(license_key_fingerprint, 'hex'),
  true
)
from private.license_secrets
where license_entitlement_id = current_setting('test.created_license_id')::uuid;

select set_config(
  'test.serial_fingerprint',
  encode(serial_fingerprint, 'hex'),
  true
)
from private.license_secrets
where license_entitlement_id = current_setting('test.created_license_id')::uuid;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select is(
  (
    select
      position('TEST-KEY-001' in to_jsonb(safe_row)::text) = 0
      and position(
        current_setting('test.license_key_vault_id')
        in to_jsonb(safe_row)::text
      ) = 0
      and position(
        current_setting('test.license_key_fingerprint')
        in to_jsonb(safe_row)::text
      ) = 0
    from public.license_safe_v as safe_row
    where id = current_setting('test.created_license_id')::uuid
  ),
  true,
  'ordinary license view exposes no plaintext, Vault UUID, or fingerprint'
);

select throws_ok(
  $$ select public.update_license_entitlement(
    '23000000-0000-4000-8000-000000000001',
    1,
    jsonb_build_object('license_reference', 'archive-license')
  ) $$,
  '23505', 'DUPLICATE_RECORD',
  'license update maps an exact reference conflict to DUPLICATE_RECORD'
);

savepoint update_secret_collision_raw;
select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.created_license_id')::uuid,
    1,
    jsonb_build_object('invoice_reference', 'TEST-KEY-001')
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license update rejects raw stored secret plaintext in an ordinary field'
);
rollback to savepoint update_secret_collision_raw;

savepoint update_secret_collision_normalized;
select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.created_license_id')::uuid,
    1,
    jsonb_build_object('owner_name', E'\tserial\t 001\n')
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license update rejects normalized stored secret plaintext in an ordinary field'
);
rollback to savepoint update_secret_collision_normalized;

savepoint update_reason_secret_collision;
select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.created_license_id')::uuid,
    1,
    jsonb_build_object(
      'record_status', 'deactivated',
      'reason', 'test key 001'
    )
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license state transition rejects a reason matching stored secret plaintext'
);
rollback to savepoint update_reason_secret_collision;

savepoint update_hyphen_only_remark;
select lives_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.created_license_id')::uuid,
    1,
    jsonb_build_object('remark', '---')
  ) $$,
  'license update accepts a benign hyphen-only free-text value'
);
rollback to savepoint update_hyphen_only_remark;

select lives_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.created_license_id')::uuid,
    1,
    jsonb_build_object('remark', 'Metadata updated safely')
  ) $$,
  'admin updates license metadata with optimistic locking'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'license_entitlement'
      and entity_id = current_setting('test.created_license_id')::uuid
      and new_values->>'remark' = 'Metadata updated safely'
  ),
  1,
  'license metadata update writes a redacted audit event'
);

select is(
  (
    select
      position('TEST-KEY-001' in report_row::text) = 0
      and position(
        current_setting('test.license_key_vault_id')
        in report_row::text
      ) = 0
      and position(
        current_setting('test.license_key_fingerprint')
        in report_row::text
      ) = 0
    from public.export_report(
      'license_inventory',
      jsonb_build_object(
        'software_product_id',
        current_setting('test.product_id')
      )
    ) as report_row
    where report_row->>'id' = current_setting('test.created_license_id')
  ),
  true,
  'license inventory export exposes no plaintext, Vault UUID, or fingerprint'
);

savepoint rotate_cross_entitlement_collision;
select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'CROSS-ENTITLEMENT-RESERVED',
    'Cross-entitlement collision test'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'secret rotation rejects plaintext reserved by another entitlement'
);
rollback to savepoint rotate_cross_entitlement_collision;

savepoint rotate_historical_audit_collision;
select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'HISTORY-ONLY-RESERVED',
    'Historical collision test'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'secret rotation rejects plaintext reserved only by immutable License audit history'
);
rollback to savepoint rotate_historical_audit_collision;

savepoint rotate_existing_field_collision_raw;
select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'TDD-SECRET-LICENSE',
    'Routine key renewal'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'secret rotation rejects a new value matching an existing ordinary field'
);
rollback to savepoint rotate_existing_field_collision_raw;

savepoint rotate_existing_field_collision_normalized;
select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'metadata-updated-safely',
    'Routine key renewal'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'secret rotation rejects a new value normalized to an existing audited field'
);
rollback to savepoint rotate_existing_field_collision_normalized;

savepoint rotate_hyphen_only_reason;
select lives_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'ROTATE-SAFE-003',
    '---'
  ) $$,
  'secret rotation accepts a benign hyphen-only reason'
);
rollback to savepoint rotate_hyphen_only_reason;

savepoint rotate_reason_secret_collision_raw;
select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'ROTATE-SECRET-002',
    'ROTATE-SECRET-002'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'secret rotation rejects a reason exactly matching the new secret'
);
rollback to savepoint rotate_reason_secret_collision_raw;

savepoint rotate_reason_secret_collision_normalized;
select throws_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    'ROTATE-SECRET-002',
    ' rotate secret 002 '
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'secret rotation rejects a reason normalized to the new secret'
);
rollback to savepoint rotate_reason_secret_collision_normalized;

select lives_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    ' test key-001 ',
    'Equivalent formatting rotation'
  ) $$,
  'admin rotates a license secret through the Vault boundary'
);

reset role;

select is(
  (
    select license_key_vault_secret_id::text
    from private.license_secrets
    where license_entitlement_id = current_setting('test.created_license_id')::uuid
  ),
  current_setting('test.license_key_vault_id'),
  'secret rotation updates the existing Vault entry instead of replacing its reference'
);

select is(
  (
    select encode(license_key_fingerprint, 'hex')
    from private.license_secrets
    where license_entitlement_id = current_setting('test.created_license_id')::uuid
  ),
  current_setting('test.license_key_fingerprint'),
  'normalized exact-equivalent license keys have the same HMAC fingerprint'
);

select is(
  (
    select right(license_key_masked, 5)
    from public.license_entitlements
    where id = current_setting('test.created_license_id')::uuid
  ),
  'y-001',
  'secret rotation refreshes the public masked hint'
);

select is(
  (
    select decrypted_secret
    from vault.decrypted_secrets
    where id = current_setting('test.license_key_vault_id')::uuid
  ),
  ' test key-001 ',
  'secret rotation updates Vault with the new plaintext value'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select results_eq(
  $$
    select
      reason,
      position(
        'test key-001'
        in coalesce(old_values::text, '') ||
           coalesce(new_values::text, '') ||
           coalesce(metadata::text, '')
      ) = 0
    from public.audit_log_admin_v
    where action = 'rotate_secret'
      and entity_id = current_setting('test.created_license_id')::uuid
  $$,
  $$ values ('Equivalent formatting rotation'::text, true) $$,
  'secret rotation audit contains the reason but not plaintext'
);

select lives_ok(
  $$ select public.rotate_license_secret(
    current_setting('test.created_license_id')::uuid,
    'serial_number',
    E'\tSERIAL\t 001\n',
    'Whitespace-equivalent serial rotation'
  ) $$,
  'serial rotation accepts leading, trailing, and repeated whitespace'
);

reset role;

select is(
  (
    select encode(serial_fingerprint, 'hex')
    from private.license_secrets
    where license_entitlement_id = current_setting('test.created_license_id')::uuid
  ),
  current_setting('test.serial_fingerprint'),
  'serial HMAC normalization trims collapsed leading and trailing whitespace'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select throws_ok(
  $$ select public.reveal_license_secret(
    current_setting('test.created_license_id')::uuid,
    'license_key',
    null
  ) $$,
  '22023', 'CORRELATION_ID_REQUIRED',
  'secret reveal requires a caller-supplied correlation ID'
);

select is(
  (
    select secret_value
    from public.reveal_license_secret(
      current_setting('test.created_license_id')::uuid,
      'license_key',
      '26000000-0000-4000-8000-000000000001'
    )
  ),
  ' test key-001 ',
  'active admin reveals the selected plaintext only through the dedicated RPC'
);

select results_eq(
  $$
    select
      correlation_id,
      position(
        'test key-001'
        in coalesce(old_values::text, '') ||
           coalesce(new_values::text, '') ||
           coalesce(metadata::text, '') ||
           description
      ) = 0
    from public.audit_log_admin_v
    where action = 'reveal_secret'
      and entity_id = current_setting('test.created_license_id')::uuid
      and correlation_id = '26000000-0000-4000-8000-000000000001'
  $$,
  $$ values ('26000000-0000-4000-8000-000000000001'::uuid, true) $$,
  'secret reveal audit records correlation without plaintext'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where entity_id = current_setting('test.created_license_id')::uuid
      and (
        position(
          'TEST-KEY-001'
          in coalesce(old_values::text, '') ||
             coalesce(new_values::text, '') ||
             coalesce(metadata::text, '') ||
             description ||
             coalesce(reason, '')
        ) > 0
        or position(
          'test key-001'
          in coalesce(old_values::text, '') ||
             coalesce(new_values::text, '') ||
             coalesce(metadata::text, '') ||
             description ||
             coalesce(reason, '')
        ) > 0
      )
  ),
  0,
  'all license audit events remain free of secret plaintext'
);

savepoint archive_reason_secret_collision_raw;
select throws_ok(
  $$ select public.archive_license_entitlement(
    '23000000-0000-4000-8000-000000000003', 1, 'TEST-KEY-001'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license archive rejects a reason matching raw stored secret plaintext'
);
rollback to savepoint archive_reason_secret_collision_raw;

savepoint archive_reason_secret_collision_normalized;
select throws_ok(
  $$ select public.archive_license_entitlement(
    '23000000-0000-4000-8000-000000000003', 1, E'\tserial\t 001\n'
  ) $$,
  'P0001', 'LICENSE_SECRET_COLLISION',
  'license archive rejects a reason normalized to stored secret plaintext'
);
rollback to savepoint archive_reason_secret_collision_normalized;

select throws_ok(
  $$ select public.archive_license_entitlement(
    '23000000-0000-4000-8000-000000000003', 1, ''
  ) $$,
  '22023', 'REASON_REQUIRED',
  'license archive requires a reason'
);

select lives_ok(
  $$ select public.archive_license_entitlement(
    '23000000-0000-4000-8000-000000000003',
    1,
    'Contract retired'
  ) $$,
  'admin archives an unallocated license with a reason'
);

select results_eq(
  $$
    select record_status::text, archived_at is not null
    from public.license_entitlements
    where id = '23000000-0000-4000-8000-000000000003'
  $$,
  $$ values ('archived'::text, true) $$,
  'license archive preserves the row with archived state'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'archive'
      and entity_type = 'license_entitlement'
      and entity_id = '23000000-0000-4000-8000-000000000003'
  ),
  'Contract retired',
  'license archive writes its reason to audit'
);

select lives_ok(
  $$ select public.update_system_settings(
    1,
    jsonb_build_object(
      'over_allocation_policy', 'allow_with_reason',
      'reason', 'Temporary exception policy'
    )
  ) $$,
  'admin updates validated settings with optimistic locking'
);

select results_eq(
  $$ select over_allocation_policy, version from public.system_settings where id = 1 $$,
  $$ values ('allow_with_reason'::text, 2::integer) $$,
  'settings update persists the validated policy and increments version'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'system_settings'
      and entity_id is null
  ),
  'Temporary exception policy',
  'settings policy transition writes its reason to audit'
);

select throws_ok(
  $$ select public.update_system_settings(
    1, jsonb_build_object('organization_name', 'Stale')
  ) $$,
  '40001', 'VERSION_CONFLICT',
  'settings update rejects a stale singleton version'
);

select throws_ok(
  $$ select public.update_system_settings(
    2, jsonb_build_object('over_allocation_policy', 'permit', 'reason', 'Invalid')
  ) $$,
  '22023', 'INVALID_SETTINGS',
  'settings update rejects an unknown policy value'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

select lives_ok(
  $$
    select public.set_notification_state(
      recipient_id => current_setting('test.notification_id')::uuid,
      is_read => true,
      is_dismissed => false
    )
  $$,
  'recipient marks own notification read'
);

select results_eq(
  $$
    select is_read, read_at is not null, is_dismissed, dismissed_at is null
    from public.notification_recipients
    where id = current_setting('test.notification_id')::uuid
  $$,
  $$ values (true, true, false, true) $$,
  'notification state keeps booleans and timestamps consistent'
);

reset role;

select is(
  (
    select count(*)::integer
    from audit.audit_events
    where action = 'update'
      and entity_type = 'notification_recipient'
      and entity_id = current_setting('test.notification_id')::uuid
      and actor_profile_id = '24000000-0000-4000-8000-000000000002'
  ),
  1,
  'notification state mutation writes an audit event'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

select throws_ok(
  $$ select public.set_notification_state(
    '25000000-0000-4000-8000-000000000003',
    true,
    true
  ) $$,
  '42501', 'ACCESS_DENIED',
  'recipient cannot update another recipient row'
);

select results_eq(
  $$
    select report_row->>'asset_code'
    from public.export_report('asset_inventory', '{}'::jsonb) as report_row
    where report_row->>'asset_code' = 'TKC-001'
  $$,
  $$ values ('TKC-001'::text) $$,
  'active user exports safe asset inventory rows through the audited boundary'
);

reset role;

select is(
  (
    select count(*)::integer
    from audit.audit_events
    where action = 'export'
      and entity_type = 'report'
      and actor_profile_id = '24000000-0000-4000-8000-000000000002'
      and metadata->>'report_type' = 'asset_inventory'
  ),
  1,
  'report export writes an audit event'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

select throws_ok(
  $$ select public.export_report('vault_dump', '{}'::jsonb) $$,
  '22023', 'INVALID_REPORT_TYPE',
  'report export rejects an unknown report type'
);

select throws_ok(
  $$ select public.export_report(
    'asset_inventory', jsonb_build_object('secret', 'TEST-KEY-001')
  ) $$,
  '22023', 'INVALID_FILTERS',
  'report export rejects non-allowlisted filters'
);

select is(
  (
    select count(*)
    from public.export_report(branch.report_type, branch.filters)
  ),
  0::bigint,
  pg_catalog.format(
    'export_report dispatches the %s allowlist branch with literal filtering',
    branch.report_type
  )
)
from (
  values
    (
      'asset_inventory',
      '{"site_id":"00000000-0000-4000-8000-000000000099"}'::jsonb
    ),
    (
      'license_inventory',
      '{"software_product_id":"00000000-0000-4000-8000-000000000099"}'::jsonb
    ),
    (
      'license_compliance',
      '{"software_product_id":"00000000-0000-4000-8000-000000000099"}'::jsonb
    ),
    ('license_expiry', '{"end_date_from":"9999-01-01"}'::jsonb),
    (
      'active_allocations',
      '{"license_entitlement_id":"00000000-0000-4000-8000-000000000099"}'::jsonb
    ),
    ('data_quality', '{"entity_type":"__NO_MATCH__"}'::jsonb)
) as branch(report_type, filters);

reset role;
select private.test_open_concurrent_session(
  'admin_role_session',
  current_setting('test.concurrent_admin_a')::uuid
);
select private.test_open_concurrent_session(
  'admin_status_session',
  current_setting('test.concurrent_admin_a')::uuid
);

select set_config(
  'test.admin_status_backend_pid',
  (
    select response.backend_pid::text
    from extensions.dblink(
      'admin_status_session',
      'select pg_catalog.pg_backend_pid()'
    ) as response(backend_pid integer)
  ),
  true
);

select is(
  (
    select response.profile_id
    from extensions.dblink(
      'admin_role_session',
      pg_catalog.format(
        'select (public.set_user_role(%L::uuid, ''user''::public.app_role, %L)).id::text',
        current_setting('test.concurrent_admin_b'),
        'Concurrent role change'
      )
    )
      as response(profile_id text)
  ),
  current_setting('test.concurrent_admin_b'),
  'first last-admin mutation completes while its transaction stays open'
);

select extensions.dblink_send_query(
  'admin_status_session',
  pg_catalog.format(
    'select (public.set_user_status(%L::uuid, ''inactive''::public.account_status, %L)).id::text',
    current_setting('test.concurrent_admin_a'),
    'Concurrent status change'
  )
);
select pg_catalog.pg_sleep(0.25);

select ok(
  private.test_backend_reaches_wait(
    current_setting('test.admin_status_backend_pid')::integer,
    'advisory',
    'Lock'
  ),
  'role and status mutations wait on the shared transaction advisory lock'
);

select extensions.dblink_exec('admin_role_session', 'commit');

select count(*)
from extensions.dblink_get_result('admin_status_session', false)
  as response(profile_id text);

select is(
  pg_catalog.split_part(
    extensions.dblink_error_message('admin_status_session'),
    E'\n', 1
  ),
  'ERROR:  LAST_ADMIN_PROTECTED',
  'waiting last-admin mutation rejects with the exact protected error'
);

select count(*)
from extensions.dblink_get_result('admin_status_session', false)
  as response(profile_id text);

select extensions.dblink_exec('admin_status_session', 'commit', false);

select is(
  (
    select count(*)
    from public.profiles
    where id in (
        current_setting('test.concurrent_admin_a')::uuid,
        current_setting('test.concurrent_admin_b')::uuid
      )
      and app_role = 'admin'
      and account_status = 'active'
  ),
  1::bigint,
  'concurrent role and status changes preserve one active Admin'
);

select extensions.dblink_disconnect('admin_role_session');
select extensions.dblink_disconnect('admin_status_session');

-- Restore the fixture actor only after asserting the unsafe old interleaving.
-- Later schedules exercise independent locking boundaries with an active Admin.
do $admin_fixture_repair$
begin
  perform extensions.dblink_connect(
    'admin_fixture_repair',
    'host=supabase_db_software-asset-management port=5432 dbname=postgres user=postgres password=postgres'
  );
  perform extensions.dblink_exec(
    'admin_fixture_repair',
    pg_catalog.format(
      $remote$
        update public.profiles
        set app_role = 'admin'::public.app_role,
            account_status = 'active'::public.account_status,
            deactivated_at = null,
            deactivated_by = null
        where id = %L::uuid
      $remote$,
      current_setting('test.concurrent_admin_a')
    )
  );
  perform extensions.dblink_disconnect('admin_fixture_repair');
end;
$admin_fixture_repair$;

select private.test_open_concurrent_session(
  'asset_archive_session',
  current_setting('test.concurrent_admin_a')::uuid
);
select private.test_open_concurrent_session(
  'asset_allocate_session',
  current_setting('test.concurrent_admin_a')::uuid
);

select set_config(
  'test.asset_allocate_backend_pid',
  (
    select response.backend_pid::text
    from extensions.dblink(
      'asset_allocate_session',
      'select pg_catalog.pg_backend_pid()'
    ) as response(backend_pid integer)
  ),
  true
);

select is(
  (
    select response.asset_id
    from extensions.dblink(
      'asset_archive_session',
      pg_catalog.format(
        'select (public.archive_asset(%L::uuid, 1, %L, true)).id::text',
        current_setting('test.concurrent_asset_id'),
        'Concurrent asset archive'
      )
    )
      as response(asset_id text)
  ),
  current_setting('test.concurrent_asset_id'),
  'asset archive completes eligibility check while its transaction stays open'
);

select extensions.dblink_send_query(
  'asset_allocate_session',
  pg_catalog.format(
    'select (public.allocate_license(%L::jsonb)).id::text',
    pg_catalog.jsonb_build_object(
      'license_entitlement_id',
      current_setting('test.concurrent_asset_license_id'),
      'target_type', 'asset',
      'asset_id', current_setting('test.concurrent_asset_id'),
      'quantity', 1
    )::text
  )
);
select pg_catalog.pg_sleep(0.25);

select ok(
  private.test_backend_reaches_wait(
    current_setting('test.asset_allocate_backend_pid')::integer,
    null,
    'Lock'
  ),
  'late allocation waits on the asset row locked by archive'
);

select extensions.dblink_exec('asset_archive_session', 'commit');

select count(*)
from extensions.dblink_get_result('asset_allocate_session', false)
  as response(allocation_id text);

select is(
  pg_catalog.split_part(
    extensions.dblink_error_message('asset_allocate_session'),
    E'\n', 1
  ),
  'ERROR:  INVALID_LICENSE_TARGET',
  'late allocation rejects with the exact invalid target error'
);

select count(*)
from extensions.dblink_get_result('asset_allocate_session', false)
  as response(allocation_id text);

select extensions.dblink_exec('asset_allocate_session', 'commit', false);

select is(
  (
    select count(*)
    from public.license_allocations as allocation
    join public.assets as asset on asset.id = allocation.asset_id
    where allocation.asset_id =
        current_setting('test.concurrent_asset_id')::uuid
      and allocation.allocation_status = 'active'
      and asset.archived_at is not null
  ),
  0::bigint,
  'archive/allocation interleaving cannot commit an active allocation on the archived asset'
);

select extensions.dblink_disconnect('asset_archive_session');
select extensions.dblink_disconnect('asset_allocate_session');

select set_config(
  'test.private_secret_count',
  (select count(*)::text from private.license_secrets),
  true
);

select set_config(
  'test.vault_license_secret_count',
  (
    select count(*)::text
    from vault.decrypted_secrets
    where name like 'sam_license_%'
  ),
  true
);

create or replace function private.test_fail_license_secret_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using
    errcode = 'P0001',
    message = 'INJECTED_SECRET_REFERENCE_FAILURE';
end;
$$;

create trigger test_fail_license_secret_insert_trg
before insert on private.license_secrets
for each row execute function private.test_fail_license_secret_insert();

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"24000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select throws_ok(
  $$
    select public.create_license_entitlement(
      jsonb_build_object(
        'license_reference', 'ROLLBACK-LICENSE',
        'software_product_id', current_setting('test.product_id'),
        'owned_quantity', 1,
        'license_metric', 'device'
      ),
      jsonb_build_object('license_key', 'ROLLBACK-SECRET')
    )
  $$,
  'P0001', 'INJECTED_SECRET_REFERENCE_FAILURE',
  'injected private-reference failure aborts license creation'
);

reset role;

select is(
  (
    select count(*)::integer
    from public.license_entitlements
    where license_reference = 'ROLLBACK-LICENSE'
  ),
  0,
  'injected secret failure rolls back the entitlement row'
);

select is(
  (select count(*)::text from private.license_secrets),
  current_setting('test.private_secret_count'),
  'injected secret failure rolls back the private reference row'
);

select is(
  (
    select count(*)::text
    from vault.decrypted_secrets
    where name like 'sam_license_%'
  ),
  current_setting('test.vault_license_secret_count'),
  'injected secret failure leaves no orphaned named Vault secret'
);

select
  current_setting('test.concurrent_admin_a') as concurrent_admin_a,
  current_setting('test.concurrent_admin_b') as concurrent_admin_b,
  current_setting('test.concurrent_publisher_id') as concurrent_publisher_id,
  current_setting('test.concurrent_product_id') as concurrent_product_id,
  current_setting('test.concurrent_asset_id') as concurrent_asset_id,
  current_setting('test.concurrent_asset_license_id') as concurrent_asset_license_id,
  current_setting('test.concurrent_license_a') as concurrent_license_a,
  current_setting('test.concurrent_license_b') as concurrent_license_b,
  current_setting('test.concurrent_pepper_id') as concurrent_pepper_id,
  current_setting('test.concurrent_pepper_created') as concurrent_pepper_created,
  current_setting('test.concurrent_license_vault_id') as concurrent_license_vault_id
\gset cleanup_

select * from finish();
rollback;

select
  set_config('test.concurrent_admin_a', :'cleanup_concurrent_admin_a', false)
    as concurrent_admin_a,
  set_config('test.concurrent_admin_b', :'cleanup_concurrent_admin_b', false)
    as concurrent_admin_b,
  set_config('test.concurrent_publisher_id', :'cleanup_concurrent_publisher_id', false)
    as concurrent_publisher_id,
  set_config('test.concurrent_product_id', :'cleanup_concurrent_product_id', false)
    as concurrent_product_id,
  set_config('test.concurrent_asset_id', :'cleanup_concurrent_asset_id', false)
    as concurrent_asset_id,
  set_config('test.concurrent_asset_license_id', :'cleanup_concurrent_asset_license_id', false)
    as concurrent_asset_license_id,
  set_config('test.concurrent_license_a', :'cleanup_concurrent_license_a', false)
    as concurrent_license_a,
  set_config('test.concurrent_license_b', :'cleanup_concurrent_license_b', false)
    as concurrent_license_b,
  set_config('test.concurrent_pepper_id', :'cleanup_concurrent_pepper_id', false)
    as concurrent_pepper_id,
  set_config('test.concurrent_pepper_created', :'cleanup_concurrent_pepper_created', false)
    as concurrent_pepper_created,
  set_config('test.concurrent_license_vault_id', :'cleanup_concurrent_license_vault_id', false)
    as concurrent_license_vault_id
\gset restored_

\if :cleanup_dblink_preexisting
\else
create extension dblink with schema extensions;
\endif

do $concurrency_cleanup$
begin
  perform extensions.dblink_connect(
    'concurrency_cleanup',
    'host=supabase_db_software-asset-management port=5432 dbname=postgres user=supabase_admin password=postgres'
  );
  perform extensions.dblink_exec(
    'concurrency_cleanup',
    pg_catalog.format(
      $remote$
        begin;
        set local session_replication_role = replica;

        delete from audit.audit_events as event
        where event.actor_profile_id in (%L::uuid, %L::uuid)
          or event.entity_id in (
            %L::uuid, %L::uuid, %L::uuid, %L::uuid,
            %L::uuid, %L::uuid, %L::uuid, %L::uuid
          )
          or event.entity_id in (
            select allocation.id
            from public.license_allocations as allocation
            where allocation.license_entitlement_id in (
                %L::uuid, %L::uuid, %L::uuid
              )
              or allocation.asset_id = %L::uuid
          );

        set local session_replication_role = origin;

        delete from public.license_allocations as allocation
        where allocation.license_entitlement_id in (
            %L::uuid, %L::uuid, %L::uuid
          )
          or allocation.asset_id = %L::uuid;

        delete from public.license_site_scopes as scope
        where scope.license_entitlement_id in (
          %L::uuid, %L::uuid, %L::uuid
        );

        delete from private.license_secrets as secret
        where secret.license_entitlement_id in (
          %L::uuid, %L::uuid, %L::uuid
        );

        delete from public.license_entitlements as entitlement
        where entitlement.id in (%L::uuid, %L::uuid, %L::uuid);

        delete from public.assets as asset
        where asset.id = %L::uuid;

        delete from public.software_products as product
        where product.id = %L::uuid;

        delete from public.publishers as publisher
        where publisher.id = %L::uuid;

        delete from public.profiles as profile
        where profile.id in (%L::uuid, %L::uuid);

        delete from auth.users as account
        where account.id in (%L::uuid, %L::uuid);

        delete from vault.secrets as secret
        where secret.id = %L::uuid
          and secret.name = %L;

        commit;
      $remote$,
      current_setting('test.concurrent_admin_a'),
      current_setting('test.concurrent_admin_b'),
      current_setting('test.concurrent_publisher_id'),
      current_setting('test.concurrent_product_id'),
      current_setting('test.concurrent_asset_id'),
      current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_admin_a'),
      current_setting('test.concurrent_admin_b'),
      current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_asset_id'),
      current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_asset_id'),
      current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_asset_license_id'),
      current_setting('test.concurrent_license_a'),
      current_setting('test.concurrent_license_b'),
      current_setting('test.concurrent_asset_id'),
      current_setting('test.concurrent_product_id'),
      current_setting('test.concurrent_publisher_id'),
      current_setting('test.concurrent_admin_a'),
      current_setting('test.concurrent_admin_b'),
      current_setting('test.concurrent_admin_a'),
      current_setting('test.concurrent_admin_b'),
      current_setting('test.concurrent_license_vault_id'),
      'sam_license_' || current_setting('test.concurrent_license_b') ||
        '_license_key'
    )
  );

  if current_setting('test.concurrent_pepper_created')::boolean then
    perform extensions.dblink_exec(
      'concurrency_cleanup',
      pg_catalog.format(
        $remote$
          delete from vault.secrets as secret
          where secret.id = %L::uuid
            and secret.name = 'sam_license_fingerprint_pepper'
        $remote$,
        current_setting('test.concurrent_pepper_id')
      )
    );
  end if;

  perform extensions.dblink_disconnect('concurrency_cleanup');
end;
$concurrency_cleanup$;

do $concurrency_cleanup_assertions$
begin
  if exists (
    select 1
    from audit.audit_events as event
    where event.actor_profile_id in (
        current_setting('test.concurrent_admin_a')::uuid,
        current_setting('test.concurrent_admin_b')::uuid
      )
      or event.entity_id in (
        current_setting('test.concurrent_publisher_id')::uuid,
        current_setting('test.concurrent_product_id')::uuid,
        current_setting('test.concurrent_asset_id')::uuid,
        current_setting('test.concurrent_asset_license_id')::uuid,
        current_setting('test.concurrent_license_a')::uuid,
        current_setting('test.concurrent_license_b')::uuid,
        current_setting('test.concurrent_admin_a')::uuid,
        current_setting('test.concurrent_admin_b')::uuid
      )
  ) or exists (
    select 1
    from public.license_allocations as allocation
    where allocation.license_entitlement_id in (
        current_setting('test.concurrent_asset_license_id')::uuid,
        current_setting('test.concurrent_license_a')::uuid,
        current_setting('test.concurrent_license_b')::uuid
      )
      or allocation.asset_id = current_setting('test.concurrent_asset_id')::uuid
  ) or exists (
    select 1
    from public.license_site_scopes as scope
    where scope.license_entitlement_id in (
      current_setting('test.concurrent_asset_license_id')::uuid,
      current_setting('test.concurrent_license_a')::uuid,
      current_setting('test.concurrent_license_b')::uuid
    )
  ) or exists (
    select 1
    from private.license_secrets as secret
    where secret.license_entitlement_id in (
      current_setting('test.concurrent_asset_license_id')::uuid,
      current_setting('test.concurrent_license_a')::uuid,
      current_setting('test.concurrent_license_b')::uuid
    )
  ) or exists (
    select 1
    from public.license_entitlements as entitlement
    where entitlement.id in (
      current_setting('test.concurrent_asset_license_id')::uuid,
      current_setting('test.concurrent_license_a')::uuid,
      current_setting('test.concurrent_license_b')::uuid
    )
  ) or exists (
    select 1 from public.assets as asset
    where asset.id = current_setting('test.concurrent_asset_id')::uuid
  ) or exists (
    select 1 from public.software_products as product
    where product.id = current_setting('test.concurrent_product_id')::uuid
  ) or exists (
    select 1 from public.publishers as publisher
    where publisher.id = current_setting('test.concurrent_publisher_id')::uuid
  ) or exists (
    select 1 from public.profiles as profile
    where profile.id in (
      current_setting('test.concurrent_admin_a')::uuid,
      current_setting('test.concurrent_admin_b')::uuid
    )
  ) or exists (
    select 1 from auth.users as account
    where account.id in (
      current_setting('test.concurrent_admin_a')::uuid,
      current_setting('test.concurrent_admin_b')::uuid
    )
  ) or exists (
    select 1 from vault.secrets as secret
    where secret.id = current_setting('test.concurrent_license_vault_id')::uuid
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'CONCURRENCY_FIXTURE_CLEANUP_FAILED';
  end if;

  if current_setting('test.concurrent_pepper_created')::boolean then
    if exists (
      select 1 from vault.secrets as secret
      where secret.id = current_setting('test.concurrent_pepper_id')::uuid
        and secret.name = 'sam_license_fingerprint_pepper'
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'CONCURRENCY_PEPPER_CLEANUP_FAILED';
    end if;
  elsif not exists (
    select 1 from vault.secrets as secret
    where secret.id = current_setting('test.concurrent_pepper_id')::uuid
      and secret.name = 'sam_license_fingerprint_pepper'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'CONCURRENCY_PEPPER_PRESERVATION_FAILED';
  end if;
end;
$concurrency_cleanup_assertions$;

\if :cleanup_dblink_preexisting
\else
drop extension dblink;
\endif
