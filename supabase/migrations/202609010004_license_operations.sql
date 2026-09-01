create type public.license_record_status as enum ('draft', 'active', 'deactivated', 'archived');
create type public.license_scope_mode as enum ('all_sites', 'selected_sites');
create type public.allocation_target_type as enum ('asset', 'person', 'site');
create type public.allocation_status as enum ('active', 'released');
create type migration.import_batch_status as enum (
  'draft', 'extracted', 'validated', 'dry_run_complete',
  'approved', 'committed', 'failed', 'cancelled'
);

create table public.vendors (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name_th text not null,
  name_en text,
  contact_name text,
  email extensions.citext,
  phone text,
  remark text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  archived_at timestamptz,
  archived_by uuid references public.profiles(id),
  constraint vendors_code_not_blank_ck check (btrim(code) <> ''),
  constraint vendors_version_ck check (version > 0)
);

create unique index vendors_code_uq
on public.vendors (upper(code))
where archived_at is null;

create table public.license_entitlements (
  id uuid primary key default gen_random_uuid(),
  license_reference text,
  software_product_id uuid not null references public.software_products(id),
  vendor_id uuid references public.vendors(id),
  license_metric_id uuid not null references public.license_metrics(id),
  product_classification_id uuid references public.product_classifications(id),
  purchase_form_id uuid references public.purchase_forms(id),
  owned_quantity integer,
  record_status public.license_record_status not null default 'draft',
  scope_mode public.license_scope_mode not null default 'all_sites',
  purchase_date date,
  start_date date,
  end_date date,
  invoice_reference text,
  po_reference text,
  contract_reference text,
  owner_person_id uuid references public.people(id),
  owner_name text,
  legacy_install_date date,
  license_key_masked text,
  serial_number_masked text,
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
  constraint license_entitlements_owned_quantity_ck check (owned_quantity is null or owned_quantity >= 0),
  constraint license_entitlements_dates_ck check (start_date is null or end_date is null or start_date <= end_date),
  constraint license_entitlements_archived_ck check (record_status <> 'archived' or archived_at is not null),
  constraint license_entitlements_version_ck check (version > 0)
);

create unique index license_entitlements_reference_uq
on public.license_entitlements (upper(license_reference))
where license_reference is not null and archived_at is null;

create index license_entitlements_product_idx
on public.license_entitlements (software_product_id);

create table public.license_site_scopes (
  license_entitlement_id uuid not null references public.license_entitlements(id) on delete cascade,
  site_id uuid not null references public.sites(id) on delete restrict,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  primary key (license_entitlement_id, site_id)
);

create table public.license_allocations (
  id uuid primary key default gen_random_uuid(),
  license_entitlement_id uuid not null references public.license_entitlements(id) on delete restrict,
  target_type public.allocation_target_type not null,
  asset_id uuid references public.assets(id) on delete restrict,
  person_id uuid references public.people(id) on delete restrict,
  site_id uuid references public.sites(id) on delete restrict,
  quantity integer not null default 1,
  allocation_status public.allocation_status not null default 'active',
  allocated_at date not null default current_date,
  installed_at date,
  released_at date,
  released_by uuid references public.profiles(id),
  release_reason text,
  override_used boolean not null default false,
  override_reason text,
  remark text,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  constraint license_allocations_quantity_ck check (quantity > 0),
  constraint license_allocations_target_ck check (
    (target_type = 'asset' and asset_id is not null and person_id is null and site_id is null) or
    (target_type = 'person' and person_id is not null and asset_id is null and site_id is null) or
    (target_type = 'site' and site_id is not null and asset_id is null and person_id is null)
  ),
  constraint license_allocations_release_ck check (
    (allocation_status = 'active' and released_at is null and released_by is null and release_reason is null) or
    (allocation_status = 'released' and released_at is not null and released_by is not null and btrim(release_reason) <> '')
  ),
  constraint license_allocations_override_ck check (
    (not override_used and override_reason is null) or
    (override_used and btrim(override_reason) <> '')
  ),
  constraint license_allocations_version_ck check (version > 0)
);

create unique index license_allocations_active_asset_uq
on public.license_allocations (license_entitlement_id, asset_id)
where allocation_status = 'active' and asset_id is not null;

create unique index license_allocations_active_person_uq
on public.license_allocations (license_entitlement_id, person_id)
where allocation_status = 'active' and person_id is not null;

create unique index license_allocations_active_site_uq
on public.license_allocations (license_entitlement_id, site_id)
where allocation_status = 'active' and site_id is not null;

alter table public.asset_software_installations
  add constraint asset_software_installations_allocation_fk
  foreign key (license_allocation_id)
  references public.license_allocations(id)
  on delete restrict;

create table private.license_secrets (
  license_entitlement_id uuid primary key references public.license_entitlements(id) on delete cascade,
  license_key_vault_secret_id uuid,
  license_key_fingerprint bytea,
  serial_vault_secret_id uuid,
  serial_fingerprint bytea,
  encryption_version smallint not null default 1,
  rotated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint license_secrets_encryption_version_ck check (encryption_version > 0)
);

create index license_secrets_license_key_fingerprint_idx
on private.license_secrets (license_key_fingerprint)
where license_key_fingerprint is not null;

create index license_secrets_serial_fingerprint_idx
on private.license_secrets (serial_fingerprint)
where serial_fingerprint is not null;

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  notification_type text not null,
  severity text not null,
  title text not null,
  message text not null,
  license_entitlement_id uuid references public.license_entitlements(id) on delete restrict,
  asset_id uuid references public.assets(id) on delete restrict,
  license_allocation_id uuid references public.license_allocations(id) on delete restrict,
  deduplication_key text not null,
  event_date date not null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notifications_type_ck check (notification_type in ('expiring', 'expired', 'full', 'over_allocated', 'asset_retired_with_allocation', 'job_failure')),
  constraint notifications_severity_ck check (severity in ('info', 'warning', 'critical')),
  constraint notifications_title_not_blank_ck check (btrim(title) <> ''),
  constraint notifications_message_not_blank_ck check (btrim(message) <> ''),
  constraint notifications_deduplication_key_uq unique (deduplication_key)
);

create table public.notification_recipients (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  delivered_at timestamptz,
  read_at timestamptz,
  dismissed_at timestamptz,
  primary key (notification_id, profile_id),
  constraint notification_recipients_dates_ck check (
    read_at is null or delivered_at is null or read_at >= delivered_at
  )
);

create table audit.audit_events (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  actor_profile_id uuid references public.profiles(id),
  actor_type text not null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  description text not null,
  old_values jsonb,
  new_values jsonb,
  reason text,
  ip_address inet,
  user_agent text,
  correlation_id uuid,
  metadata jsonb,
  constraint audit_events_actor_type_ck check (actor_type in ('user', 'system', 'migration')),
  constraint audit_events_description_not_blank_ck check (btrim(description) <> '')
);

create index audit_events_occurred_at_idx on audit.audit_events (occurred_at desc);
create index audit_events_entity_idx on audit.audit_events (entity_type, entity_id);
create index audit_events_actor_idx on audit.audit_events (actor_profile_id, occurred_at desc);

create or replace function private.prevent_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = '42501', message = 'Audit events are append-only';
end;
$$;

create trigger audit_events_append_only_trg
before update or delete on audit.audit_events
for each row execute function private.prevent_audit_mutation();

create table public.system_settings (
  id smallint primary key default 1,
  organization_name text not null default 'Thai Kurabo',
  timezone text not null default 'Asia/Bangkok',
  date_format text not null default 'DD/MM/YYYY',
  session_timeout_minutes integer not null default 60,
  max_login_failures integer not null default 5,
  secret_visible_suffix_length smallint not null default 5,
  over_allocation_policy text not null default 'block',
  default_page_size smallint not null default 25,
  audit_retention_months integer not null default 84,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id),
  version integer not null default 1,
  constraint system_settings_single_row_ck check (id = 1),
  constraint system_settings_session_timeout_ck check (session_timeout_minutes > 0),
  constraint system_settings_max_login_failures_ck check (max_login_failures > 0),
  constraint system_settings_suffix_length_ck check (secret_visible_suffix_length between 0 and 8),
  constraint system_settings_over_allocation_ck check (over_allocation_policy in ('block', 'allow_with_reason')),
  constraint system_settings_page_size_ck check (default_page_size between 10 and 100),
  constraint system_settings_audit_retention_ck check (audit_retention_months > 0),
  constraint system_settings_version_ck check (version > 0)
);

insert into public.system_settings (id) values (1);

create table migration.import_batches (
  id uuid primary key default gen_random_uuid(),
  batch_name text not null,
  environment text not null,
  status migration.import_batch_status not null default 'draft',
  started_at timestamptz,
  completed_at timestamptz,
  started_by uuid references public.profiles(id),
  approved_at timestamptz,
  approved_by uuid references public.profiles(id),
  approval_note text,
  created_at timestamptz not null default now(),
  constraint import_batches_name_not_blank_ck check (btrim(batch_name) <> ''),
  constraint import_batches_dates_ck check (completed_at is null or started_at is null or completed_at >= started_at),
  constraint import_batches_approval_ck check (
    (approved_at is null and approved_by is null) or
    (approved_at is not null and approved_by is not null)
  )
);

create table migration.source_files (
  id uuid primary key default gen_random_uuid(),
  import_batch_id uuid not null references migration.import_batches(id) on delete cascade,
  file_name text not null,
  sha256_checksum bytea not null,
  file_size_bytes bigint not null,
  source_modified_at timestamptz,
  archived_location text,
  extracted_at timestamptz,
  constraint source_files_size_ck check (file_size_bytes >= 0),
  constraint source_files_batch_checksum_uq unique (import_batch_id, sha256_checksum)
);

create table migration.asset_staging_rows (
  id uuid primary key default gen_random_uuid(),
  source_file_id uuid not null references migration.source_files(id) on delete cascade,
  sheet_name text not null,
  source_row_number integer not null,
  source_row_hash bytea not null,
  raw_data jsonb not null,
  normalized_asset_code text,
  normalized_computer_name text,
  normalized_site_code text,
  normalized_location_code text,
  normalized_department_code text,
  normalized_mac_address text,
  normalized_ip_address inet,
  secret_present boolean not null default false,
  secret_fingerprint bytea,
  secret_masked_hint text,
  secret_write_status text,
  validation_status text not null default 'pending',
  validation_messages jsonb not null default '[]'::jsonb,
  constraint asset_staging_rows_source_coordinate_uq unique (source_file_id, sheet_name, source_row_number),
  constraint asset_staging_rows_row_number_ck check (source_row_number > 0),
  constraint asset_staging_rows_no_plaintext_secret_ck check (
    not (raw_data ?| array['license_key', 'serial_number', 'os_key', 'product_key'])
  )
);

create table migration.license_staging_rows (
  id uuid primary key default gen_random_uuid(),
  source_file_id uuid not null references migration.source_files(id) on delete cascade,
  sheet_name text not null,
  source_row_number integer not null,
  source_row_hash bytea not null,
  raw_data jsonb not null,
  normalized_publisher text,
  normalized_vendor text,
  normalized_product_name text,
  normalized_version text,
  normalized_classification text,
  normalized_purchase_form text,
  normalized_owned_quantity integer,
  normalized_purchase_date date,
  normalized_start_date date,
  normalized_end_date date,
  normalized_record_status text,
  license_key_present boolean not null default false,
  license_key_fingerprint bytea,
  license_key_masked_hint text,
  serial_present boolean not null default false,
  serial_fingerprint bytea,
  serial_masked_hint text,
  secret_write_status text,
  validation_status text not null default 'pending',
  validation_messages jsonb not null default '[]'::jsonb,
  constraint license_staging_rows_source_coordinate_uq unique (source_file_id, sheet_name, source_row_number),
  constraint license_staging_rows_row_number_ck check (source_row_number > 0),
  constraint license_staging_rows_quantity_ck check (normalized_owned_quantity is null or normalized_owned_quantity >= 0),
  constraint license_staging_rows_no_plaintext_secret_ck check (
    not (raw_data ?| array['license_key', 'serial_number', 'os_key', 'product_key'])
  )
);

create table migration.row_results (
  id uuid primary key default gen_random_uuid(),
  import_batch_id uuid not null references migration.import_batches(id) on delete cascade,
  staging_entity_type text not null,
  staging_row_id uuid not null,
  result_status text not null,
  target_entity_type text,
  target_entity_id uuid,
  decision_reason text,
  decided_by uuid references public.profiles(id),
  decided_at timestamptz,
  errors jsonb not null default '[]'::jsonb,
  warnings jsonb not null default '[]'::jsonb,
  constraint row_results_entity_ck check (staging_entity_type in ('asset', 'license')),
  constraint row_results_status_ck check (result_status in ('imported', 'merged', 'skipped', 'error')),
  constraint row_results_batch_row_uq unique (import_batch_id, staging_entity_type, staging_row_id)
);

create table migration.mapping_rules (
  id uuid primary key default gen_random_uuid(),
  rule_type text not null,
  source_value text not null,
  normalized_value text,
  target_id uuid,
  priority integer not null default 0,
  effective_batch_id uuid references migration.import_batches(id),
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  version integer not null default 1,
  constraint mapping_rules_target_ck check (normalized_value is not null or target_id is not null),
  constraint mapping_rules_version_ck check (version > 0)
);

create table migration.reconciliation_runs (
  id uuid primary key default gen_random_uuid(),
  import_batch_id uuid not null references migration.import_batches(id) on delete cascade,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  checked_by uuid references public.profiles(id),
  approved_at timestamptz,
  approved_by uuid references public.profiles(id),
  status text not null default 'pending',
  constraint reconciliation_runs_status_ck check (status in ('pending', 'matched', 'mismatch', 'approved'))
);

create table migration.reconciliation_totals (
  reconciliation_run_id uuid not null references migration.reconciliation_runs(id) on delete cascade,
  metric text not null,
  site_id uuid references public.sites(id),
  source_total numeric not null,
  target_total numeric not null,
  difference numeric generated always as (target_total - source_total) stored,
  tolerance numeric not null default 0,
  status text not null,
  primary key (reconciliation_run_id, metric, site_id),
  constraint reconciliation_totals_tolerance_ck check (tolerance >= 0),
  constraint reconciliation_totals_status_ck check (status in ('matched', 'mismatch', 'approved'))
);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'vendors', 'license_entitlements', 'license_allocations', 'system_settings'
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

create trigger vendors_prevent_code_change_trg
before update of code on public.vendors
for each row execute function private.prevent_code_change();

revoke all on schema private, audit, migration from public, anon, authenticated;
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all tables in schema private, audit, migration from public, anon, authenticated;
revoke all on all sequences in schema private, audit, migration from public, anon, authenticated;
revoke all on all functions in schema private, audit, migration from public, anon, authenticated;
