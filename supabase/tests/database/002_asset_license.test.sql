begin;

select plan(131);

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
  owned_quantity, record_status, scope_mode
)
values (
  '23000000-0000-4000-8000-000000000003',
  'ARCHIVE-LICENSE',
  '21000000-0000-4000-8000-000000000001',
  '14000000-0000-4000-8000-000000000001',
  1,
  'active',
  'all_sites'
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
do $$
begin
  perform vault.create_secret(
    'TDD-ONLY-FINGERPRINT-PEPPER',
    'sam_license_fingerprint_pepper',
    'Disposable pgTAP pepper'
  );
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

select is(
  (
    select is_read
    from public.set_notification_state(
      current_setting('test.notification_id')::uuid,
      true,
      false
    )
  ),
  true,
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

reset role;
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

select * from finish();
rollback;
