begin;

select plan(30);

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

select * from finish();
rollback;
