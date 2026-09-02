begin;

select plan(65);

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

select set_config('test.asset_id', '22000000-0000-4000-8000-000000000001', true);
select set_config('test.product_id', '21000000-0000-4000-8000-000000000001', true);

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

select * from finish();
rollback;
