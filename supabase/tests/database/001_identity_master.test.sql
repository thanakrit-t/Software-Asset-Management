begin;

select plan(67);

select has_schema('private', 'private schema exists');
select has_schema('audit', 'audit schema exists');
select has_schema('migration', 'migration schema exists');
select has_type('public', 'app_role', 'application role enum exists');
select has_type('public', 'account_status', 'account status enum exists');

select has_table('public', 'profiles', 'profiles table exists');
select col_is_pk('public', 'profiles', 'id', 'profiles id is the primary key');
select has_table('public', 'people', 'people table exists');
select has_table('public', 'sites', 'sites table exists');
select has_table('public', 'locations', 'locations table exists');
select has_table('public', 'departments', 'departments table exists');
select has_table('public', 'asset_types', 'asset types table exists');
select has_table('public', 'asset_statuses', 'asset statuses table exists');
select has_table('public', 'internet_levels', 'internet levels table exists');
select has_table('public', 'software_categories', 'software categories table exists');
select has_table('public', 'license_metrics', 'license metrics table exists');
select has_table('public', 'product_classifications', 'product classifications table exists');
select has_table('public', 'purchase_forms', 'purchase forms table exists');
select has_table('public', 'expiration_thresholds', 'expiration thresholds table exists');

select results_eq(
  $$ select code::text from public.sites order by code $$,
  $$ values ('BANGKOK_OFFICE'::text), ('FACTORY'::text) $$,
  'initial sites are deterministic'
);

select results_eq(
  $$ select distinct timezone from public.sites $$,
  $$ values ('Asia/Bangkok'::text) $$,
  'initial sites use the organization timezone'
);

select throws_ok(
  $$
    insert into public.sites (code, name_th, name_en)
    values ('factory', 'โรงงานซ้ำ', 'Duplicate Factory')
  $$,
  '23505',
  null,
  'active site codes are unique without case sensitivity'
);

insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
values (
  '10000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'new.user@thaikurabo.example',
  crypt('local-test-only', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Untrusted Admin","app_role":"admin"}'::jsonb,
  now(),
  now(),
  '',
  '',
  '',
  ''
);

select is(
  (select app_role::text from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'user',
  'new profiles always default to user regardless of user metadata'
);

select is(
  (select account_status::text from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'active',
  'new profiles default to active'
);

select is(
  (select display_name from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'new.user',
  'profile bootstrap derives a safe display name from email'
);

delete from public.profiles
where id = '10000000-0000-4000-8000-000000000001';

select is(
  private.sync_missing_auth_profiles(),
  1,
  'missing Auth profiles are backfilled'
);

select is(
  (select app_role::text from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'user',
  'backfilled profiles default to user'
);

select is(
  (select account_status::text from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'active',
  'backfilled profiles default to active'
);

select is(
  (select display_name from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'new.user',
  'backfilled profiles derive a safe display name from email'
);

select is(
  private.sync_missing_auth_profiles(),
  0,
  'profile backfill is idempotent'
);

insert into public.publishers (id, code, name_th, name_en)
values (
  '18000000-0000-4000-8000-000000000001',
  'MASTER_TEST',
  'ทดสอบข้อมูลหลัก',
  'Master Test'
);

insert into public.departments (id, code, name)
values (
  '18100000-0000-4000-8000-000000000001',
  'DISPATCH_DEPARTMENT',
  'Dispatcher Department'
);

insert into public.locations (id, site_id, code, name)
values (
  '18200000-0000-4000-8000-000000000001',
  '01000000-0000-4000-8000-000000000002',
  'DISPATCH_LOCATION',
  'Dispatcher Location'
);

insert into public.publishers (id, code, name_th, name_en)
values (
  '18300000-0000-4000-8000-000000000001',
  'DISPATCH_PUBLISHER',
  'ผู้เผยแพร่ทดสอบ',
  'Dispatcher Publisher'
);

insert into public.vendors (id, code, name_th, name_en)
values (
  '18400000-0000-4000-8000-000000000001',
  'DISPATCH_VENDOR',
  'ผู้ขายทดสอบ',
  'Dispatcher Vendor'
);

update public.profiles
set app_role = 'admin'
where id = '10000000-0000-4000-8000-000000000001';

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select results_eq(
  pg_catalog.format(
    'select (public.update_master_data(%L, %L::uuid, 1, %L::jsonb)->>''sort_order'')::integer',
    branch.entity_type,
    branch.entity_id,
    pg_catalog.jsonb_build_object('sort_order', branch.expected_sort)::text
  ),
  pg_catalog.format('values (%s::integer)', branch.expected_sort),
  pg_catalog.format(
    'update_master_data dispatches the %s branch with literal behavior',
    branch.entity_type
  )
)
from (
  values
    ('site', '01000000-0000-4000-8000-000000000001', 101),
    ('department', '18100000-0000-4000-8000-000000000001', 102),
    ('location', '18200000-0000-4000-8000-000000000001', 103),
    ('asset_type', '10000000-0000-4000-8000-000000000001', 104),
    ('asset_status', '11000000-0000-4000-8000-000000000001', 105),
    ('internet_level', '12000000-0000-4000-8000-000000000001', 106),
    ('software_category', '13000000-0000-4000-8000-000000000001', 107),
    ('license_metric', '14000000-0000-4000-8000-000000000001', 108),
    ('product_classification', '15000000-0000-4000-8000-000000000001', 109),
    ('purchase_form', '16000000-0000-4000-8000-000000000001', 110),
    ('expiration_threshold', '17000000-0000-4000-8000-000000000001', 111),
    ('publisher', '18300000-0000-4000-8000-000000000001', 112),
    ('vendor', '18400000-0000-4000-8000-000000000001', 113)
) as branch(entity_type, entity_id, expected_sort);

select results_eq(
  pg_catalog.format(
    'select (archived->>''is_active'')::boolean, archived->>''archived_at'' is not null from (select public.archive_master_data(%L, %L::uuid, 2, %L) as archived) as result',
    branch.entity_type,
    branch.entity_id,
    'Dispatcher smoke archive'
  ),
  $$ values (false, true) $$,
  pg_catalog.format(
    'archive_master_data dispatches the %s branch with literal behavior',
    branch.entity_type
  )
)
from (
  values
    ('site', '01000000-0000-4000-8000-000000000001'),
    ('department', '18100000-0000-4000-8000-000000000001'),
    ('location', '18200000-0000-4000-8000-000000000001'),
    ('asset_type', '10000000-0000-4000-8000-000000000001'),
    ('asset_status', '11000000-0000-4000-8000-000000000001'),
    ('internet_level', '12000000-0000-4000-8000-000000000001'),
    ('software_category', '13000000-0000-4000-8000-000000000001'),
    ('license_metric', '14000000-0000-4000-8000-000000000001'),
    ('product_classification', '15000000-0000-4000-8000-000000000001'),
    ('purchase_form', '16000000-0000-4000-8000-000000000001'),
    ('expiration_threshold', '17000000-0000-4000-8000-000000000001'),
    ('publisher', '18300000-0000-4000-8000-000000000001'),
    ('vendor', '18400000-0000-4000-8000-000000000001')
) as branch(entity_type, entity_id);

select lives_ok(
  $$
    select public.update_master_data(
      'publisher',
      '18000000-0000-4000-8000-000000000001',
      1,
      jsonb_build_object('name_en', 'Master Test Updated')
    )
  $$,
  'admin updates an allowlisted master-data entity with optimistic locking'
);

select results_eq(
  $$
    select name_en, version
    from public.publishers
    where id = '18000000-0000-4000-8000-000000000001'
  $$,
  $$ values ('Master Test Updated'::text, 2::integer) $$,
  'master-data update persists the safe field and increments version'
);

select throws_ok(
  $$
    select public.update_master_data(
      'publisher',
      '18000000-0000-4000-8000-000000000001',
      2,
      jsonb_build_object('code', 'MUTATED')
    )
  $$,
  '22023', 'INVALID_PAYLOAD',
  'master-data update rejects immutable or unallowlisted fields'
);

select throws_ok(
  $$
    select public.update_master_data(
      'unknown',
      '18000000-0000-4000-8000-000000000001',
      2,
      '{}'::jsonb
    )
  $$,
  '22023', 'INVALID_MASTER_ENTITY',
  'master-data update rejects unknown entity types'
);

select throws_ok(
  $$
    select public.archive_master_data(
      'unknown',
      '18000000-0000-4000-8000-000000000001',
      2,
      'Unknown archive'
    )
  $$,
  '22023', 'INVALID_MASTER_ENTITY',
  'master-data archive rejects unknown entity types'
);

select throws_ok(
  $$
    select public.update_master_data(
      'publisher',
      '18000000-0000-4000-8000-000000000001',
      1,
      jsonb_build_object('name_en', 'Stale Update')
    )
  $$,
  '40001', 'VERSION_CONFLICT',
  'master-data update rejects a stale version'
);

select is(
  (
    select count(*)::integer
    from public.audit_log_admin_v
    where action = 'update'
      and entity_type = 'publisher'
      and entity_id = '18000000-0000-4000-8000-000000000001'
      and new_values->>'name_en' = 'Master Test Updated'
  ),
  1,
  'master-data update writes an audit event'
);

select throws_ok(
  $$
    select public.archive_master_data(
      'publisher',
      '18000000-0000-4000-8000-000000000001',
      2,
      ''
    )
  $$,
  '22023', 'REASON_REQUIRED',
  'master-data archive requires a reason'
);

select lives_ok(
  $$
    select public.archive_master_data(
      'publisher',
      '18000000-0000-4000-8000-000000000001',
      2,
      'Publisher retired'
    )
  $$,
  'admin archives an allowlisted master-data entity'
);

select results_eq(
  $$
    select is_active, archived_at is not null
    from public.publishers
    where id = '18000000-0000-4000-8000-000000000001'
  $$,
  $$ values (false, true) $$,
  'master-data archive preserves and deactivates the row'
);

select is(
  (
    select reason
    from public.audit_log_admin_v
    where action = 'archive'
      and entity_type = 'publisher'
      and entity_id = '18000000-0000-4000-8000-000000000001'
  ),
  'Publisher retired',
  'master-data archive writes its reason to audit'
);

select * from finish();
rollback;
