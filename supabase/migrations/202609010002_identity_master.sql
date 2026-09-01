create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  person_id uuid,
  display_name text not null,
  username extensions.citext,
  email extensions.citext not null,
  app_role public.app_role not null default 'user',
  account_status public.account_status not null default 'active',
  last_login_at timestamptz,
  failed_login_count integer not null default 0,
  locked_until timestamptz,
  deactivated_at timestamptz,
  deactivated_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  constraint profiles_username_uq unique (username),
  constraint profiles_email_uq unique (email),
  constraint profiles_failed_login_count_ck check (failed_login_count >= 0),
  constraint profiles_version_ck check (version > 0)
);

create table public.sites (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  timezone text not null default 'Asia/Bangkok',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint sites_code_not_blank_ck check (btrim(code) <> ''),
  constraint sites_name_th_not_blank_ck check (btrim(name_th) <> ''),
  constraint sites_version_ck check (version > 0)
);

create unique index sites_code_uq
on public.sites (upper(code))
where archived_at is null;

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  name_th text,
  name_en text,
  parent_department_id uuid references public.departments(id),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint departments_code_not_blank_ck check (btrim(code) <> ''),
  constraint departments_name_not_blank_ck check (btrim(name) <> ''),
  constraint departments_parent_not_self_ck check (parent_department_id is distinct from id),
  constraint departments_version_ck check (version > 0)
);

create unique index departments_code_uq
on public.departments (upper(code))
where archived_at is null;

create table public.locations (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.sites(id),
  code text not null,
  name text not null,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint locations_code_not_blank_ck check (btrim(code) <> ''),
  constraint locations_name_not_blank_ck check (btrim(name) <> ''),
  constraint locations_version_ck check (version > 0)
);

create unique index locations_site_code_uq
on public.locations (site_id, upper(code))
where archived_at is null;

create table public.people (
  id uuid primary key default gen_random_uuid(),
  employee_code text,
  display_name text not null,
  email extensions.citext,
  department_id uuid references public.departments(id),
  primary_site_id uuid references public.sites(id),
  employment_status text not null default 'unknown',
  remark text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint people_display_name_not_blank_ck check (btrim(display_name) <> ''),
  constraint people_employment_status_ck check (employment_status in ('active', 'inactive', 'unknown')),
  constraint people_version_ck check (version > 0)
);

create unique index people_employee_code_uq
on public.people (upper(employee_code))
where employee_code is not null and archived_at is null;

alter table public.profiles
  add constraint profiles_person_id_fk
  foreign key (person_id) references public.people(id);

create unique index profiles_person_id_uq
on public.profiles (person_id)
where person_id is not null;

create table public.asset_types (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint asset_types_code_not_blank_ck check (btrim(code) <> ''),
  constraint asset_types_version_ck check (version > 0)
);

create unique index asset_types_code_uq
on public.asset_types (upper(code))
where archived_at is null;

create table public.asset_statuses (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  is_operational boolean not null default false,
  is_retired boolean not null default false,
  requires_allocation_warning boolean not null default false,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint asset_statuses_code_not_blank_ck check (btrim(code) <> ''),
  constraint asset_statuses_version_ck check (version > 0)
);

create unique index asset_statuses_code_uq
on public.asset_statuses (upper(code))
where archived_at is null;

create table public.internet_levels (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  risk_level smallint not null default 0,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint internet_levels_code_not_blank_ck check (btrim(code) <> ''),
  constraint internet_levels_risk_level_ck check (risk_level between 0 and 5),
  constraint internet_levels_version_ck check (version > 0)
);

create unique index internet_levels_code_uq
on public.internet_levels (upper(code))
where archived_at is null;

create table public.software_categories (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint software_categories_code_not_blank_ck check (btrim(code) <> ''),
  constraint software_categories_version_ck check (version > 0)
);

create unique index software_categories_code_uq
on public.software_categories (upper(code))
where archived_at is null;

create table public.license_metrics (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  target_mode public.license_target_mode not null,
  is_perpetual boolean not null default false,
  allows_multi_seat_allocation boolean not null default false,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint license_metrics_code_not_blank_ck check (btrim(code) <> ''),
  constraint license_metrics_version_ck check (version > 0)
);

create unique index license_metrics_code_uq
on public.license_metrics (upper(code))
where archived_at is null;

create table public.product_classifications (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint product_classifications_code_not_blank_ck check (btrim(code) <> ''),
  constraint product_classifications_version_ck check (version > 0)
);

create unique index product_classifications_code_uq
on public.product_classifications (upper(code))
where archived_at is null;

create table public.purchase_forms (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint purchase_forms_code_not_blank_ck check (btrim(code) <> ''),
  constraint purchase_forms_version_ck check (version > 0)
);

create unique index purchase_forms_code_uq
on public.purchase_forms (upper(code))
where archived_at is null;

create table public.expiration_thresholds (
  id uuid primary key default gen_random_uuid(),
  days_before_expiry integer not null,
  severity text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint expiration_thresholds_days_ck check (days_before_expiry > 0),
  constraint expiration_thresholds_severity_ck check (severity in ('info', 'warning', 'critical')),
  constraint expiration_thresholds_version_ck check (version > 0)
);

create unique index expiration_thresholds_days_uq
on public.expiration_thresholds (days_before_expiry)
where archived_at is null;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    display_name,
    email,
    app_role,
    account_status
  )
  values (
    new.id,
    coalesce(nullif(split_part(new.email, '@', 1), ''), 'User'),
    new.email,
    'user'::public.app_role,
    'active'::public.account_status
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();

create or replace function private.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles as profile
    where profile.id = auth.uid()
      and profile.account_status = 'active'::public.account_status
  );
$$;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles as profile
    where profile.id = auth.uid()
      and profile.account_status = 'active'::public.account_status
      and profile.app_role = 'admin'::public.app_role
  );
$$;

revoke all on function private.handle_new_auth_user() from public, anon, authenticated;
revoke all on function private.is_active_user() from public, anon, authenticated;
revoke all on function private.is_admin() from public, anon, authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'sites', 'departments', 'locations', 'people',
    'asset_types', 'asset_statuses', 'internet_levels',
    'software_categories', 'license_metrics',
    'product_classifications', 'purchase_forms', 'expiration_thresholds'
  ]
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function private.touch_updated_row()',
      table_name || '_touch_updated_trg',
      table_name
    );
  end loop;

  foreach table_name in array array[
    'sites', 'departments', 'locations', 'asset_types', 'asset_statuses',
    'internet_levels', 'software_categories', 'license_metrics',
    'product_classifications', 'purchase_forms'
  ]
  loop
    execute format(
      'create trigger %I before update of code on public.%I for each row execute function private.prevent_code_change()',
      table_name || '_prevent_code_change_trg',
      table_name
    );
  end loop;
end;
$$;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
