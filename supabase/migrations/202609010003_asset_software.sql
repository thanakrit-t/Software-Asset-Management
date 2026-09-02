create table public.publishers (
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
  constraint publishers_code_not_blank_ck check (btrim(code) <> ''),
  constraint publishers_version_ck check (version > 0)
);

create unique index publishers_code_uq
on public.publishers (upper(code))
where archived_at is null;

create table public.software_products (
  id uuid primary key default gen_random_uuid(),
  publisher_id uuid not null references public.publishers(id),
  category_id uuid not null references public.software_categories(id),
  name text not null,
  version_edition text not null default '',
  support_status text not null default 'unknown',
  end_of_life_date date,
  remark text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint software_products_name_not_blank_ck check (btrim(name) <> ''),
  constraint software_products_support_status_ck check (support_status in ('supported', 'eol', 'unknown')),
  constraint software_products_version_ck check (version > 0)
);

create unique index software_products_business_key_uq
on public.software_products (
  publisher_id,
  lower(name),
  lower(version_edition)
)
where archived_at is null;

create table public.assets (
  id uuid primary key default gen_random_uuid(),
  asset_code text,
  migration_reference text,
  computer_name text,
  asset_type_id uuid not null references public.asset_types(id),
  asset_status_id uuid not null references public.asset_statuses(id),
  site_id uuid not null references public.sites(id),
  location_id uuid references public.locations(id),
  department_id uuid references public.departments(id),
  manufacturer text,
  model text,
  serial_number text,
  purchase_date date,
  internet_level_id uuid references public.internet_levels(id),
  risk_access_level text,
  operating_system_product_id uuid references public.software_products(id),
  computer_name_duplicate_approved_at timestamptz,
  computer_name_duplicate_approved_by uuid references public.profiles(id),
  computer_name_duplicate_reason text,
  remark text,
  migration_batch_id uuid,
  migration_source_row_id uuid,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint assets_asset_code_not_blank_ck check (asset_code is null or btrim(asset_code) <> ''),
  constraint assets_migration_reference_not_blank_ck check (migration_reference is null or btrim(migration_reference) <> ''),
  constraint assets_computer_name_override_ck check (
    computer_name_duplicate_approved_at is null or
    (computer_name_duplicate_approved_by is not null and btrim(computer_name_duplicate_reason) <> '')
  ),
  constraint assets_version_ck check (version > 0)
);

create unique index assets_asset_code_uq
on public.assets (upper(asset_code))
where asset_code is not null and archived_at is null;

create unique index assets_migration_reference_uq
on public.assets (migration_reference)
where migration_reference is not null and archived_at is null;

create unique index assets_site_computer_name_uq
on public.assets (site_id, upper(computer_name))
where computer_name is not null
  and archived_at is null
  and computer_name_duplicate_approved_at is null;

create index assets_site_idx on public.assets (site_id);
create index assets_asset_type_idx on public.assets (asset_type_id);
create index assets_asset_status_idx on public.assets (asset_status_id);
create index assets_department_idx on public.assets (department_id);
create index assets_asset_code_trgm_idx on public.assets using gin (asset_code extensions.gin_trgm_ops);
create index assets_computer_name_trgm_idx on public.assets using gin (computer_name extensions.gin_trgm_ops);

create table public.asset_network_interfaces (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete restrict,
  interface_type text not null,
  interface_name text,
  mac_address text,
  ip_address inet,
  address_mode text not null default 'unknown',
  raw_ip_text text,
  vlan text,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint asset_network_interfaces_type_ck check (interface_type in ('lan', 'wifi', 'other')),
  constraint asset_network_interfaces_address_mode_ck check (address_mode in ('static', 'dhcp', 'not_connected', 'unknown')),
  constraint asset_network_interfaces_mac_ck check (
    mac_address is null or mac_address ~ '^[0-9A-F]{2}(:[0-9A-F]{2}){5}$'
  ),
  constraint asset_network_interfaces_version_ck check (version > 0)
);

create unique index asset_network_interfaces_mac_uq
on public.asset_network_interfaces (mac_address)
where mac_address is not null and archived_at is null;

create unique index asset_network_interfaces_primary_uq
on public.asset_network_interfaces (asset_id, interface_type)
where is_primary and archived_at is null;

create index asset_network_interfaces_ip_idx
on public.asset_network_interfaces (ip_address);

create table public.asset_person_assignments (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete restrict,
  person_id uuid not null references public.people(id) on delete restrict,
  assignment_role text not null,
  valid_from date not null,
  valid_to date,
  remark text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint asset_person_assignments_role_ck check (assignment_role in ('primary_user', 'responsible_person', 'additional_user')),
  constraint asset_person_assignments_dates_ck check (valid_to is null or valid_to >= valid_from),
  constraint asset_person_assignments_version_ck check (version > 0)
);

create unique index asset_person_assignments_current_role_uq
on public.asset_person_assignments (asset_id, assignment_role)
where valid_to is null
  and archived_at is null
  and assignment_role in ('primary_user', 'responsible_person');

create table public.asset_software_installations (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete restrict,
  software_product_id uuid not null references public.software_products(id) on delete restrict,
  license_allocation_id uuid,
  installed_version text,
  installed_at date,
  installation_status text not null default 'unknown',
  source text not null default 'manual',
  removed_at date,
  remark text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint asset_software_installations_status_ck check (installation_status in ('installed', 'removed', 'unknown')),
  constraint asset_software_installations_source_ck check (source in ('manual', 'migration', 'discovery')),
  constraint asset_software_installations_removed_ck check (
    (installation_status = 'removed' and removed_at is not null) or
    (installation_status <> 'removed')
  ),
  constraint asset_software_installations_version_ck check (version > 0)
);

create unique index asset_software_installations_active_uq
on public.asset_software_installations (asset_id, software_product_id)
where installation_status = 'installed' and archived_at is null;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'publishers', 'software_products', 'assets', 'asset_network_interfaces',
    'asset_person_assignments', 'asset_software_installations'
  ]
  loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function private.touch_updated_row()',
      table_name || '_touch_updated_trg',
      table_name
    );
  end loop;
end;
$$;

create trigger publishers_prevent_code_change_trg
before update of code on public.publishers
for each row execute function private.prevent_code_change();

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
