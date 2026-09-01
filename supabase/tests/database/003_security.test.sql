begin;

select plan(13);

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
values
  (
    '30000000-0000-4000-8000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'admin@test.local',
    crypt('local-test-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
  ),
  (
    '30000000-0000-4000-8000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated', 'user@test.local',
    crypt('local-test-only', gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''
  );

update public.profiles
set app_role = 'admin'
where id = '30000000-0000-4000-8000-000000000001';

insert into public.publishers (id, code, name_th, name_en)
values ('31000000-0000-4000-8000-000000000001', 'SECURITY_TEST', 'ทดสอบ', 'Security Test');

insert into public.software_products (
  id, publisher_id, category_id, name, version_edition, support_status
)
values (
  '32000000-0000-4000-8000-000000000001',
  '31000000-0000-4000-8000-000000000001',
  '13000000-0000-4000-8000-000000000001',
  'Security Product', '1', 'supported'
);

insert into public.assets (
  id, asset_code, computer_name, asset_type_id, asset_status_id, site_id
)
values (
  '33000000-0000-4000-8000-000000000001', 'SEC-001', 'SEC-PC-001',
  '10000000-0000-4000-8000-000000000001',
  '11000000-0000-4000-8000-000000000001',
  '01000000-0000-4000-8000-000000000001'
);

insert into public.license_entitlements (
  id, license_reference, software_product_id, license_metric_id,
  owned_quantity, record_status, scope_mode
)
values (
  '34000000-0000-4000-8000-000000000001', 'SEC-LIC-001',
  '32000000-0000-4000-8000-000000000001',
  '14000000-0000-4000-8000-000000000001',
  2, 'active', 'all_sites'
);

set local role anon;

select throws_ok(
  $$ select * from public.asset_inventory_v $$,
  '42501',
  null,
  'anon cannot read safe asset views'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);

select lives_ok(
  $$ select * from public.asset_inventory_v $$,
  'active users can read safe asset views'
);

select throws_ok(
  $$
    insert into public.assets (
      asset_code, asset_type_id, asset_status_id, site_id
    ) values (
      'FORBIDDEN',
      '10000000-0000-4000-8000-000000000001',
      '11000000-0000-4000-8000-000000000001',
      '01000000-0000-4000-8000-000000000001'
    )
  $$,
  '42501',
  null,
  'authenticated users have no direct operational DML'
);

select is(
  (select count(*)::integer from public.audit_log_admin_v),
  0,
  'users cannot read admin audit events'
);

select throws_ok(
  $$ select * from private.license_secrets $$,
  '42501',
  null,
  'users cannot access the private secret schema'
);

select throws_ok(
  $$ select * from migration.import_batches $$,
  '42501',
  null,
  'users cannot access migration staging'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"30000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select lives_ok(
  $$
    select public.allocate_license(
      jsonb_build_object(
        'license_entitlement_id', '34000000-0000-4000-8000-000000000001',
        'target_type', 'asset',
        'asset_id', '33000000-0000-4000-8000-000000000001',
        'quantity', 1,
        'allocated_at', current_date
      )
    )
  $$,
  'admin can allocate through the approved RPC'
);

select is(
  (select allocated_quantity from public.license_compliance_v where id = '34000000-0000-4000-8000-000000000001'),
  1,
  'allocated quantity comes from active allocations'
);

select is(
  (select available_quantity from public.license_compliance_v where id = '34000000-0000-4000-8000-000000000001'),
  1,
  'available quantity is owned minus allocated'
);

select is(
  (select compliance_status from public.license_compliance_v where id = '34000000-0000-4000-8000-000000000001'),
  'compliant',
  'license is compliant within owned quantity'
);

select lives_ok(
  $$
    select public.release_license_allocation(
      (select id from public.license_allocations where license_entitlement_id = '34000000-0000-4000-8000-000000000001'),
      1,
      'Security test release'
    )
  $$,
  'admin can release through the approved RPC'
);

select is(
  (select allocated_quantity from public.license_compliance_v where id = '34000000-0000-4000-8000-000000000001'),
  0,
  'released allocations no longer count as active'
);

select is(
  (select count(*)::integer from public.license_allocations where license_entitlement_id = '34000000-0000-4000-8000-000000000001'),
  1,
  'release preserves allocation history'
);

select * from finish();
rollback;
