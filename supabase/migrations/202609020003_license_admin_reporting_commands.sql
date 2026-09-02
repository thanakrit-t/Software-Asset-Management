create extension if not exists supabase_vault with schema vault;

alter table public.notification_recipients
  drop constraint notification_recipients_pkey,
  add column id uuid not null default gen_random_uuid(),
  add column is_read boolean not null default false,
  add column is_dismissed boolean not null default false;

update public.notification_recipients
set is_read = read_at is not null,
    is_dismissed = dismissed_at is not null;

alter table public.notification_recipients
  add constraint notification_recipients_pkey primary key (id),
  add constraint notification_recipients_notification_profile_uq
    unique (notification_id, profile_id);

create or replace view public.notification_feed_v
with (security_invoker = true)
as
select
  notification.id,
  notification.notification_type,
  notification.severity,
  notification.title,
  notification.message,
  notification.event_date,
  notification.resolved_at,
  notification.created_at,
  recipient.delivered_at,
  recipient.read_at,
  recipient.dismissed_at,
  recipient.id as recipient_id,
  recipient.is_read,
  recipient.is_dismissed
from public.notifications as notification
join public.notification_recipients as recipient
  on recipient.notification_id = notification.id
where recipient.profile_id = auth.uid();

create type public.license_secret_reveal as (
  secret_type text,
  secret_value text,
  correlation_id uuid,
  revealed_at timestamptz
);

create or replace function private.jsonb_has_only_keys(
  payload jsonb,
  allowed_keys text[]
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    pg_catalog.jsonb_typeof(payload) = 'object'
    and not exists (
      select 1
      from pg_catalog.jsonb_object_keys(payload) as supplied(key)
      where not (supplied.key = any (allowed_keys))
    ),
    false
  );
$$;

create or replace function private.normalize_license_secret(
  secret_type text,
  secret_value text
)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  ascii_upper text;
begin
  if secret_type not in ('license_key', 'serial_number') then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_TYPE';
  end if;

  ascii_upper := pg_catalog.translate(
    secret_value,
    'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  );

  if secret_type = 'license_key' then
    return pg_catalog.regexp_replace(
      ascii_upper,
      '[[:space:]-]+',
      '',
      'g'
    );
  end if;

  return pg_catalog.btrim(
    pg_catalog.regexp_replace(
      ascii_upper,
      '[[:space:]]+',
      ' ',
      'g'
    )
  );
end;
$$;

create or replace function public.update_license_entitlement(
  entitlement_id uuid,
  expected_version integer,
  payload jsonb
)
returns public.license_entitlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.license_entitlements%rowtype;
  result public.license_entitlements%rowtype;
  resolved_software_product_id uuid;
  resolved_vendor_id uuid;
  resolved_license_metric_id uuid;
  resolved_classification_id uuid;
  resolved_purchase_form_id uuid;
  resolved_owner_person_id uuid;
  requested_record_status public.license_record_status;
  requested_scope_mode public.license_scope_mode;
  active_quantity integer;
  transition_reason text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select *
  into before_row
  from public.license_entitlements as entitlement
  where entitlement.id = update_license_entitlement.entitlement_id
    and entitlement.version = update_license_entitlement.expected_version
    and entitlement.archived_at is null
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if not private.jsonb_has_only_keys(
    payload,
    array[
      'license_reference', 'software_product_id', 'vendor_id',
      'license_metric_id', 'license_metric', 'product_classification_id',
      'purchase_form_id', 'owned_quantity', 'record_status', 'scope_mode',
      'purchase_date', 'start_date', 'end_date', 'invoice_reference',
      'po_reference', 'contract_reference', 'owner_person_id', 'owner_name',
      'legacy_install_date', 'remark', 'reason'
    ]::text[]
  ) then
    raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
  end if;

  if payload ? 'license_metric_id' and payload ? 'license_metric' then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
  end if;

  resolved_software_product_id := before_row.software_product_id;
  resolved_vendor_id := before_row.vendor_id;
  resolved_license_metric_id := before_row.license_metric_id;
  resolved_classification_id := before_row.product_classification_id;
  resolved_purchase_form_id := before_row.purchase_form_id;
  resolved_owner_person_id := before_row.owner_person_id;
  requested_record_status := before_row.record_status;
  requested_scope_mode := before_row.scope_mode;

  if payload ? 'software_product_id' then
    select product.id
    into resolved_software_product_id
    from public.software_products as product
    where product.id = (payload->>'software_product_id')::uuid
      and product.archived_at is null;

    if resolved_software_product_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  end if;

  if payload ? 'license_metric_id' then
    select metric.id
    into resolved_license_metric_id
    from public.license_metrics as metric
    where metric.id = (payload->>'license_metric_id')::uuid
      and metric.is_active
      and metric.archived_at is null;

    if resolved_license_metric_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  elsif payload ? 'license_metric' then
    select metric.id
    into resolved_license_metric_id
    from public.license_metrics as metric
    where metric.is_active
      and metric.archived_at is null
      and (
        pg_catalog.lower(metric.code) =
          pg_catalog.lower(payload->>'license_metric')
        or metric.target_mode::text =
          pg_catalog.lower(payload->>'license_metric')
      )
    order by
      (
        pg_catalog.lower(metric.code) =
          pg_catalog.lower(payload->>'license_metric')
      ) desc,
      metric.sort_order
    limit 1;

    if resolved_license_metric_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  end if;

  if payload ? 'vendor_id' then
    resolved_vendor_id := null;
    if payload->>'vendor_id' is not null then
      select vendor.id
      into resolved_vendor_id
      from public.vendors as vendor
      where vendor.id = (payload->>'vendor_id')::uuid
        and vendor.is_active
        and vendor.archived_at is null;

      if resolved_vendor_id is null then
        raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
      end if;
    end if;
  end if;

  if payload ? 'product_classification_id' then
    resolved_classification_id := null;
    if payload->>'product_classification_id' is not null then
      select classification.id
      into resolved_classification_id
      from public.product_classifications as classification
      where classification.id =
          (payload->>'product_classification_id')::uuid
        and classification.is_active
        and classification.archived_at is null;

      if resolved_classification_id is null then
        raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
      end if;
    end if;
  end if;

  if payload ? 'purchase_form_id' then
    resolved_purchase_form_id := null;
    if payload->>'purchase_form_id' is not null then
      select purchase_form.id
      into resolved_purchase_form_id
      from public.purchase_forms as purchase_form
      where purchase_form.id = (payload->>'purchase_form_id')::uuid
        and purchase_form.is_active
        and purchase_form.archived_at is null;

      if resolved_purchase_form_id is null then
        raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
      end if;
    end if;
  end if;

  if payload ? 'owner_person_id' then
    resolved_owner_person_id := null;
    if payload->>'owner_person_id' is not null then
      select person.id
      into resolved_owner_person_id
      from public.people as person
      where person.id = (payload->>'owner_person_id')::uuid
        and person.archived_at is null;

      if resolved_owner_person_id is null then
        raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
      end if;
    end if;
  end if;

  if payload ? 'record_status' then
    if payload->>'record_status' not in ('draft', 'active', 'deactivated')
    then
      raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
    end if;

    requested_record_status :=
      (payload->>'record_status')::public.license_record_status;

    if requested_record_status is distinct from before_row.record_status then
      if pg_catalog.btrim(coalesce(payload->>'reason', '')) = '' then
        raise exception using errcode = '22023', message = 'REASON_REQUIRED';
      end if;
      transition_reason := pg_catalog.btrim(payload->>'reason');
    end if;
  end if;

  if payload ? 'scope_mode' then
    if payload->>'scope_mode' not in ('all_sites', 'selected_sites') then
      raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
    end if;
    requested_scope_mode :=
      (payload->>'scope_mode')::public.license_scope_mode;
  end if;

  select coalesce(pg_catalog.sum(allocation.quantity), 0)::integer
  into active_quantity
  from public.license_allocations as allocation
  where allocation.license_entitlement_id =
      update_license_entitlement.entitlement_id
    and allocation.allocation_status = 'active';

  if payload ? 'owned_quantity'
    and (payload->>'owned_quantity')::integer < active_quantity then
    raise exception using errcode = 'P0001', message = 'OWNED_BELOW_ALLOCATED';
  end if;

  perform private.assert_no_license_secret_collision(
    array[
      payload->>'license_reference',
      payload->>'invoice_reference',
      payload->>'po_reference',
      payload->>'contract_reference',
      payload->>'owner_name',
      payload->>'remark',
      payload->>'reason'
    ]::text[],
    array[]::bytea[]
  );

  update public.license_entitlements
  set license_reference = case
        when payload ? 'license_reference'
          then nullif(pg_catalog.btrim(payload->>'license_reference'), '')
        else license_reference
      end,
      software_product_id = resolved_software_product_id,
      vendor_id = resolved_vendor_id,
      license_metric_id = resolved_license_metric_id,
      product_classification_id = resolved_classification_id,
      purchase_form_id = resolved_purchase_form_id,
      owned_quantity = case
        when payload ? 'owned_quantity'
          then (payload->>'owned_quantity')::integer
        else owned_quantity
      end,
      record_status = requested_record_status,
      scope_mode = requested_scope_mode,
      purchase_date = case
        when payload ? 'purchase_date' then (payload->>'purchase_date')::date
        else purchase_date
      end,
      start_date = case
        when payload ? 'start_date' then (payload->>'start_date')::date
        else start_date
      end,
      end_date = case
        when payload ? 'end_date' then (payload->>'end_date')::date
        else end_date
      end,
      invoice_reference = case
        when payload ? 'invoice_reference'
          then nullif(pg_catalog.btrim(payload->>'invoice_reference'), '')
        else invoice_reference
      end,
      po_reference = case
        when payload ? 'po_reference'
          then nullif(pg_catalog.btrim(payload->>'po_reference'), '')
        else po_reference
      end,
      contract_reference = case
        when payload ? 'contract_reference'
          then nullif(pg_catalog.btrim(payload->>'contract_reference'), '')
        else contract_reference
      end,
      owner_person_id = resolved_owner_person_id,
      owner_name = case
        when payload ? 'owner_name'
          then nullif(pg_catalog.btrim(payload->>'owner_name'), '')
        else owner_name
      end,
      legacy_install_date = case
        when payload ? 'legacy_install_date'
          then (payload->>'legacy_install_date')::date
        else legacy_install_date
      end,
      remark = case
        when payload ? 'remark'
          then nullif(pg_catalog.btrim(payload->>'remark'), '')
        else remark
      end,
      updated_by = auth.uid()
  where id = entitlement_id
    and version = expected_version
    and archived_at is null
  returning * into result;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'update', 'license_entitlement', result.id,
    'License entitlement updated',
    pg_catalog.to_jsonb(before_row) -
      array['created_by', 'updated_by']::text[],
    pg_catalog.to_jsonb(result) -
      array['created_by', 'updated_by']::text[],
    transition_reason
  );

  return result;
end;
$$;

create or replace function public.archive_license_entitlement(
  entitlement_id uuid,
  expected_version integer,
  reason text
)
returns public.license_entitlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.license_entitlements%rowtype;
  result public.license_entitlements%rowtype;
  active_quantity integer;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select *
  into before_row
  from public.license_entitlements as entitlement
  where entitlement.id = archive_license_entitlement.entitlement_id
    and entitlement.version = archive_license_entitlement.expected_version
    and entitlement.archived_at is null
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if pg_catalog.btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'REASON_REQUIRED';
  end if;

  select coalesce(pg_catalog.sum(allocation.quantity), 0)::integer
  into active_quantity
  from public.license_allocations as allocation
  where allocation.license_entitlement_id =
      archive_license_entitlement.entitlement_id
    and allocation.allocation_status = 'active';

  if active_quantity > 0 then
    raise exception using errcode = 'P0001', message = 'ACTIVE_ALLOCATIONS_EXIST';
  end if;

  perform private.assert_no_license_secret_collision(
    array[reason]::text[],
    array[]::bytea[]
  );

  update public.license_entitlements
  set record_status = 'archived',
      archived_at = pg_catalog.now(),
      archived_by = auth.uid(),
      updated_by = auth.uid()
  where id = entitlement_id
    and version = expected_version
    and archived_at is null
  returning * into result;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'archive', 'license_entitlement', result.id,
    'License entitlement archived',
    pg_catalog.to_jsonb(before_row) -
      array['created_by', 'updated_by']::text[],
    pg_catalog.to_jsonb(result) -
      array['created_by', 'updated_by']::text[],
    pg_catalog.btrim(reason)
  );

  return result;
end;
$$;

create or replace function private.license_fingerprint_pepper()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  pepper text;
begin
  select secret.decrypted_secret
  into pepper
  from vault.decrypted_secrets as secret
  where secret.name = 'sam_license_fingerprint_pepper'
  order by secret.created_at desc
  limit 1;

  if pg_catalog.btrim(coalesce(pepper, '')) = '' then
    raise exception using
      errcode = 'P0001',
      message = 'SECRET_PEPPER_NOT_CONFIGURED';
  end if;

  return pepper;
end;
$$;

create or replace function private.fingerprint_license_secret(
  secret_type text,
  secret_value text
)
returns bytea
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_value text;
begin
  normalized_value := private.normalize_license_secret(
    secret_type,
    secret_value
  );

  if pg_catalog.btrim(coalesce(normalized_value, '')) = '' then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_VALUE';
  end if;

  return extensions.hmac(
    normalized_value,
    private.license_fingerprint_pepper(),
    'sha256'
  );
end;
$$;

create or replace function private.assert_no_license_secret_collision(
  candidates text[],
  additional_fingerprints bytea[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  candidate_value text;
  license_key_candidate_fingerprint bytea;
  serial_candidate_fingerprint bytea;
begin
  foreach candidate_value in array coalesce(candidates, array[]::text[])
  loop
    if pg_catalog.regexp_replace(
      coalesce(candidate_value, ''),
      '[[:space:]]',
      '',
      'g'
    ) = '' then
      continue;
    end if;

    license_key_candidate_fingerprint :=
      private.fingerprint_license_secret('license_key', candidate_value);
    serial_candidate_fingerprint :=
      private.fingerprint_license_secret('serial_number', candidate_value);

    if exists (
      select 1
      from private.license_secrets as stored_secret
      where stored_secret.license_key_fingerprint =
          license_key_candidate_fingerprint
        or stored_secret.serial_fingerprint = serial_candidate_fingerprint
    )
    or license_key_candidate_fingerprint = any (
      coalesce(additional_fingerprints, array[]::bytea[])
    )
    or serial_candidate_fingerprint = any (
      coalesce(additional_fingerprints, array[]::bytea[])
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'LICENSE_SECRET_COLLISION';
    end if;
  end loop;
end;
$$;

create or replace function private.mask_license_secret(secret_value text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  trimmed_value text;
  configured_suffix_length integer;
  visible_suffix_length integer;
begin
  trimmed_value := pg_catalog.btrim(secret_value);
  if trimmed_value = '' then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_VALUE';
  end if;

  select settings.secret_visible_suffix_length
  into configured_suffix_length
  from public.system_settings as settings
  where settings.id = 1;

  visible_suffix_length := least(
    coalesce(configured_suffix_length, 0),
    greatest(pg_catalog.char_length(trimmed_value) - 1, 0)
  );

  return '*****' || pg_catalog.right(trimmed_value, visible_suffix_length);
end;
$$;

create or replace function public.create_license_entitlement(
  payload jsonb,
  secret_payload jsonb
)
returns public.license_entitlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_secrets jsonb := coalesce(secret_payload, '{}'::jsonb);
  new_entitlement_id uuid := extensions.gen_random_uuid();
  resolved_software_product_id uuid;
  resolved_vendor_id uuid;
  resolved_license_metric_id uuid;
  resolved_classification_id uuid;
  resolved_purchase_form_id uuid;
  resolved_owner_person_id uuid;
  requested_record_status public.license_record_status;
  requested_scope_mode public.license_scope_mode;
  license_key_value text;
  serial_value text;
  license_key_fingerprint bytea;
  serial_fingerprint bytea;
  license_key_vault_id uuid;
  serial_vault_id uuid;
  result public.license_entitlements%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  if not private.jsonb_has_only_keys(
    payload,
    array[
      'license_reference', 'software_product_id', 'vendor_id',
      'license_metric_id', 'license_metric', 'product_classification_id',
      'purchase_form_id', 'owned_quantity', 'record_status', 'scope_mode',
      'purchase_date', 'start_date', 'end_date', 'invoice_reference',
      'po_reference', 'contract_reference', 'owner_person_id', 'owner_name',
      'legacy_install_date', 'remark'
    ]::text[]
  ) then
    raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
  end if;

  if not private.jsonb_has_only_keys(
    requested_secrets,
    array['license_key', 'serial_number']::text[]
  ) then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_PAYLOAD';
  end if;

  if payload ? 'license_metric_id' and payload ? 'license_metric' then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
  end if;

  select product.id
  into resolved_software_product_id
  from public.software_products as product
  where product.id = (payload->>'software_product_id')::uuid
    and product.archived_at is null;

  if resolved_software_product_id is null then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
  end if;

  if payload ? 'license_metric_id' then
    select metric.id
    into resolved_license_metric_id
    from public.license_metrics as metric
    where metric.id = (payload->>'license_metric_id')::uuid
      and metric.is_active
      and metric.archived_at is null;
  elsif payload ? 'license_metric' then
    select metric.id
    into resolved_license_metric_id
    from public.license_metrics as metric
    where metric.is_active
      and metric.archived_at is null
      and (
        pg_catalog.lower(metric.code) =
          pg_catalog.lower(payload->>'license_metric')
        or metric.target_mode::text =
          pg_catalog.lower(payload->>'license_metric')
      )
    order by
      (
        pg_catalog.lower(metric.code) =
          pg_catalog.lower(payload->>'license_metric')
      ) desc,
      metric.sort_order
    limit 1;
  end if;

  if resolved_license_metric_id is null then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
  end if;

  if payload ? 'vendor_id' and payload->>'vendor_id' is not null then
    select vendor.id
    into resolved_vendor_id
    from public.vendors as vendor
    where vendor.id = (payload->>'vendor_id')::uuid
      and vendor.is_active
      and vendor.archived_at is null;

    if resolved_vendor_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  end if;

  if payload ? 'product_classification_id'
    and payload->>'product_classification_id' is not null then
    select classification.id
    into resolved_classification_id
    from public.product_classifications as classification
    where classification.id =
        (payload->>'product_classification_id')::uuid
      and classification.is_active
      and classification.archived_at is null;

    if resolved_classification_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  end if;

  if payload ? 'purchase_form_id'
    and payload->>'purchase_form_id' is not null then
    select purchase_form.id
    into resolved_purchase_form_id
    from public.purchase_forms as purchase_form
    where purchase_form.id = (payload->>'purchase_form_id')::uuid
      and purchase_form.is_active
      and purchase_form.archived_at is null;

    if resolved_purchase_form_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  end if;

  if payload ? 'owner_person_id'
    and payload->>'owner_person_id' is not null then
    select person.id
    into resolved_owner_person_id
    from public.people as person
    where person.id = (payload->>'owner_person_id')::uuid
      and person.archived_at is null;

    if resolved_owner_person_id is null then
      raise exception using errcode = '22023', message = 'INVALID_LICENSE_REFERENCE';
    end if;
  end if;

  if payload ? 'record_status'
    and payload->>'record_status' not in ('draft', 'active', 'deactivated') then
    raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
  end if;

  if payload ? 'scope_mode'
    and payload->>'scope_mode' not in ('all_sites', 'selected_sites') then
    raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
  end if;

  requested_record_status := coalesce(
    (payload->>'record_status')::public.license_record_status,
    'draft'::public.license_record_status
  );
  requested_scope_mode := coalesce(
    (payload->>'scope_mode')::public.license_scope_mode,
    'all_sites'::public.license_scope_mode
  );

  if requested_secrets ? 'license_key' then
    license_key_value := requested_secrets->>'license_key';
    license_key_fingerprint := private.fingerprint_license_secret(
      'license_key',
      license_key_value
    );
  end if;

  if requested_secrets ? 'serial_number' then
    serial_value := requested_secrets->>'serial_number';
    serial_fingerprint := private.fingerprint_license_secret(
      'serial_number',
      serial_value
    );
  end if;

  perform private.assert_no_license_secret_collision(
    array[
      payload->>'license_reference',
      payload->>'invoice_reference',
      payload->>'po_reference',
      payload->>'contract_reference',
      payload->>'owner_name',
      payload->>'remark'
    ]::text[],
    array[license_key_fingerprint, serial_fingerprint]::bytea[]
  );

  insert into public.license_entitlements (
    id, license_reference, software_product_id, vendor_id,
    license_metric_id, product_classification_id, purchase_form_id,
    owned_quantity, record_status, scope_mode, purchase_date, start_date,
    end_date, invoice_reference, po_reference, contract_reference,
    owner_person_id, owner_name, legacy_install_date,
    license_key_masked, serial_number_masked, remark,
    created_by, updated_by
  ) values (
    new_entitlement_id,
    nullif(pg_catalog.btrim(payload->>'license_reference'), ''),
    resolved_software_product_id,
    resolved_vendor_id,
    resolved_license_metric_id,
    resolved_classification_id,
    resolved_purchase_form_id,
    (payload->>'owned_quantity')::integer,
    requested_record_status,
    requested_scope_mode,
    (payload->>'purchase_date')::date,
    (payload->>'start_date')::date,
    (payload->>'end_date')::date,
    nullif(pg_catalog.btrim(payload->>'invoice_reference'), ''),
    nullif(pg_catalog.btrim(payload->>'po_reference'), ''),
    nullif(pg_catalog.btrim(payload->>'contract_reference'), ''),
    resolved_owner_person_id,
    nullif(pg_catalog.btrim(payload->>'owner_name'), ''),
    (payload->>'legacy_install_date')::date,
    case
      when license_key_value is null then null
      else private.mask_license_secret(license_key_value)
    end,
    case
      when serial_value is null then null
      else private.mask_license_secret(serial_value)
    end,
    nullif(pg_catalog.btrim(payload->>'remark'), ''),
    auth.uid(),
    auth.uid()
  )
  returning * into result;

  if license_key_value is not null then
    license_key_vault_id := vault.create_secret(
      license_key_value,
      pg_catalog.format(
        'sam_license_%s_license_key',
        new_entitlement_id
      ),
      'SAM license key'
    );
  end if;

  if serial_value is not null then
    serial_vault_id := vault.create_secret(
      serial_value,
      pg_catalog.format(
        'sam_license_%s_serial_number',
        new_entitlement_id
      ),
      'SAM license serial number'
    );
  end if;

  if license_key_value is not null or serial_value is not null then
    insert into private.license_secrets (
      license_entitlement_id,
      license_key_vault_secret_id,
      license_key_fingerprint,
      serial_vault_secret_id,
      serial_fingerprint
    ) values (
      new_entitlement_id,
      license_key_vault_id,
      license_key_fingerprint,
      serial_vault_id,
      serial_fingerprint
    );
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values
  ) values (
    auth.uid(), 'user', 'create', 'license_entitlement', result.id,
    'License entitlement created',
    pg_catalog.to_jsonb(result) -
      array['created_by', 'updated_by']::text[]
  );

  return result;
exception
  when unique_violation then
    raise exception using errcode = '23505', message = 'DUPLICATE_RECORD';
end;
$$;

create or replace function public.rotate_license_secret(
  entitlement_id uuid,
  secret_type text,
  value text,
  reason text
)
returns public.license_entitlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  secret_ref private.license_secrets%rowtype;
  result public.license_entitlements%rowtype;
  selected_vault_id uuid;
  new_fingerprint bytea;
  new_mask text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  if secret_type not in ('license_key', 'serial_number') then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_TYPE';
  end if;

  if pg_catalog.btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'REASON_REQUIRED';
  end if;

  if pg_catalog.btrim(coalesce(value, '')) = '' then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_VALUE';
  end if;

  perform entitlement.id
  from public.license_entitlements as entitlement
  where entitlement.id = rotate_license_secret.entitlement_id
    and entitlement.archived_at is null
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'LICENSE_NOT_FOUND';
  end if;

  select *
  into secret_ref
  from private.license_secrets as stored_secret
  where stored_secret.license_entitlement_id =
      rotate_license_secret.entitlement_id
  for update;

  if not found then
    raise exception using errcode = 'P0001', message = 'SECRET_NOT_CONFIGURED';
  end if;

  selected_vault_id := case secret_type
    when 'license_key' then secret_ref.license_key_vault_secret_id
    else secret_ref.serial_vault_secret_id
  end;

  if selected_vault_id is null then
    raise exception using errcode = 'P0001', message = 'SECRET_NOT_CONFIGURED';
  end if;

  new_fingerprint := private.fingerprint_license_secret(secret_type, value);
  perform private.assert_no_license_secret_collision(
    array[reason]::text[],
    array[new_fingerprint]::bytea[]
  );
  new_mask := private.mask_license_secret(value);

  perform vault.update_secret(
    selected_vault_id,
    value,
    null,
    null,
    null
  );

  update private.license_secrets
  set license_key_fingerprint = case
        when secret_type = 'license_key'
          then new_fingerprint
        else license_key_fingerprint
      end,
      serial_fingerprint = case
        when secret_type = 'serial_number'
          then new_fingerprint
        else serial_fingerprint
      end,
      rotated_at = pg_catalog.now(),
      updated_at = pg_catalog.now()
  where license_entitlement_id = entitlement_id;

  update public.license_entitlements
  set license_key_masked = case
        when secret_type = 'license_key' then new_mask
        else license_key_masked
      end,
      serial_number_masked = case
        when secret_type = 'serial_number' then new_mask
        else serial_number_masked
      end,
      updated_by = auth.uid()
  where id = entitlement_id
    and archived_at is null
  returning * into result;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values, reason
  ) values (
    auth.uid(), 'user', 'rotate_secret', 'license_entitlement', result.id,
    'License secret rotated',
    pg_catalog.jsonb_build_object('secret_type', secret_type),
    pg_catalog.btrim(reason)
  );

  return result;
end;
$$;

create or replace function public.reveal_license_secret(
  entitlement_id uuid,
  secret_type text,
  correlation_id uuid
)
returns public.license_secret_reveal
language plpgsql
security definer
set search_path = ''
as $$
declare
  selected_vault_id uuid;
  plaintext text;
  reveal_timestamp timestamptz := pg_catalog.now();
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  if correlation_id is null then
    raise exception using errcode = '22023', message = 'CORRELATION_ID_REQUIRED';
  end if;

  if secret_type not in ('license_key', 'serial_number') then
    raise exception using errcode = '22023', message = 'INVALID_SECRET_TYPE';
  end if;

  select case secret_type
      when 'license_key' then secret_ref.license_key_vault_secret_id
      else secret_ref.serial_vault_secret_id
    end
  into selected_vault_id
  from public.license_entitlements as entitlement
  join private.license_secrets as secret_ref
    on secret_ref.license_entitlement_id = entitlement.id
  where entitlement.id = reveal_license_secret.entitlement_id
    and entitlement.archived_at is null;

  if selected_vault_id is null then
    raise exception using errcode = 'P0001', message = 'SECRET_NOT_CONFIGURED';
  end if;

  select secret.decrypted_secret
  into plaintext
  from vault.decrypted_secrets as secret
  where secret.id = selected_vault_id;

  if plaintext is null then
    raise exception using errcode = 'P0001', message = 'SECRET_NOT_CONFIGURED';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values, correlation_id
  ) values (
    auth.uid(), 'user', 'reveal_secret', 'license_entitlement',
    entitlement_id, 'License secret revealed',
    pg_catalog.jsonb_build_object('secret_type', secret_type),
    correlation_id
  );

  return row(
    secret_type,
    plaintext,
    correlation_id,
    reveal_timestamp
  )::public.license_secret_reveal;
end;
$$;

create or replace function public.update_master_data(
  entity_type text,
  entity_id uuid,
  expected_version integer,
  payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  table_name text;
  allowed_keys text[];
  update_clause text;
  before_values jsonb;
  result jsonb;
  transition_reason text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  case entity_type
    when 'site' then
      table_name := 'sites';
      allowed_keys := array[
        'name_th', 'name_en', 'timezone', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         timezone = case when $3 ? ''timezone'' then btrim($3->>''timezone'') else timezone end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'department' then
      table_name := 'departments';
      allowed_keys := array[
        'name', 'name_th', 'name_en', 'parent_department_id',
        'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name = case when $3 ? ''name'' then btrim($3->>''name'') else name end,
         name_th = case when $3 ? ''name_th'' then nullif(btrim($3->>''name_th''), '''') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         parent_department_id = case when $3 ? ''parent_department_id'' then ($3->>''parent_department_id'')::uuid else parent_department_id end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'location' then
      table_name := 'locations';
      allowed_keys := array[
        'site_id', 'name', 'description', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'site_id = case when $3 ? ''site_id'' then ($3->>''site_id'')::uuid else site_id end,
         name = case when $3 ? ''name'' then btrim($3->>''name'') else name end,
         description = case when $3 ? ''description'' then nullif(btrim($3->>''description''), '''') else description end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'asset_type' then
      table_name := 'asset_types';
      allowed_keys := array[
        'name_th', 'name_en', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'asset_status' then
      table_name := 'asset_statuses';
      allowed_keys := array[
        'name_th', 'name_en', 'is_operational', 'is_retired',
        'requires_allocation_warning', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         is_operational = case when $3 ? ''is_operational'' then ($3->>''is_operational'')::boolean else is_operational end,
         is_retired = case when $3 ? ''is_retired'' then ($3->>''is_retired'')::boolean else is_retired end,
         requires_allocation_warning = case when $3 ? ''requires_allocation_warning'' then ($3->>''requires_allocation_warning'')::boolean else requires_allocation_warning end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'internet_level' then
      table_name := 'internet_levels';
      allowed_keys := array[
        'name_th', 'name_en', 'risk_level', 'description',
        'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         risk_level = case when $3 ? ''risk_level'' then ($3->>''risk_level'')::smallint else risk_level end,
         description = case when $3 ? ''description'' then nullif(btrim($3->>''description''), '''') else description end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'software_category' then
      table_name := 'software_categories';
      allowed_keys := array[
        'name_th', 'name_en', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'license_metric' then
      table_name := 'license_metrics';
      allowed_keys := array[
        'name_th', 'name_en', 'target_mode', 'is_perpetual',
        'allows_multi_seat_allocation', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         target_mode = case when $3 ? ''target_mode'' then ($3->>''target_mode'')::public.license_target_mode else target_mode end,
         is_perpetual = case when $3 ? ''is_perpetual'' then ($3->>''is_perpetual'')::boolean else is_perpetual end,
         allows_multi_seat_allocation = case when $3 ? ''allows_multi_seat_allocation'' then ($3->>''allows_multi_seat_allocation'')::boolean else allows_multi_seat_allocation end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'product_classification' then
      table_name := 'product_classifications';
      allowed_keys := array[
        'name_th', 'name_en', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'purchase_form' then
      table_name := 'purchase_forms';
      allowed_keys := array[
        'name_th', 'name_en', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'expiration_threshold' then
      table_name := 'expiration_thresholds';
      allowed_keys := array[
        'days_before_expiry', 'severity', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'days_before_expiry = case when $3 ? ''days_before_expiry'' then ($3->>''days_before_expiry'')::integer else days_before_expiry end,
         severity = case when $3 ? ''severity'' then btrim($3->>''severity'') else severity end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'publisher' then
      table_name := 'publishers';
      allowed_keys := array[
        'name_th', 'name_en', 'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    when 'vendor' then
      table_name := 'vendors';
      allowed_keys := array[
        'name_th', 'name_en', 'contact_name', 'email', 'phone', 'remark',
        'sort_order', 'is_active', 'reason'
      ];
      update_clause :=
        'name_th = case when $3 ? ''name_th'' then btrim($3->>''name_th'') else name_th end,
         name_en = case when $3 ? ''name_en'' then nullif(btrim($3->>''name_en''), '''') else name_en end,
         contact_name = case when $3 ? ''contact_name'' then nullif(btrim($3->>''contact_name''), '''') else contact_name end,
         email = case when $3 ? ''email'' then nullif(btrim($3->>''email''), '''') else email end,
         phone = case when $3 ? ''phone'' then nullif(btrim($3->>''phone''), '''') else phone end,
         remark = case when $3 ? ''remark'' then nullif(btrim($3->>''remark''), '''') else remark end,
         sort_order = case when $3 ? ''sort_order'' then ($3->>''sort_order'')::integer else sort_order end,
         is_active = case when $3 ? ''is_active'' then ($3->>''is_active'')::boolean else is_active end';
    else
      raise exception using errcode = '22023', message = 'INVALID_MASTER_ENTITY';
  end case;

  execute pg_catalog.format(
    'select to_jsonb(row_value)
       from public.%I as row_value
      where row_value.id = $1
        and row_value.version = $2
        and row_value.archived_at is null
      for update',
    table_name
  )
  into before_values
  using entity_id, expected_version;

  if before_values is null then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if not private.jsonb_has_only_keys(payload, allowed_keys) then
    raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
  end if;

  if payload ? 'is_active'
    and (payload->>'is_active')::boolean is distinct from
      (before_values->>'is_active')::boolean then
    if pg_catalog.btrim(coalesce(payload->>'reason', '')) = '' then
      raise exception using errcode = '22023', message = 'REASON_REQUIRED';
    end if;
    transition_reason := pg_catalog.btrim(payload->>'reason');
  end if;

  execute pg_catalog.format(
    'update public.%I as target
        set %s,
            updated_by = auth.uid()
      where target.id = $1
        and target.version = $2
        and target.archived_at is null
      returning to_jsonb(target)',
    table_name,
    update_clause
  )
  into result
  using entity_id, expected_version, payload;

  if result is null then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'update', entity_type, entity_id,
    'Master data updated',
    before_values - array['created_by', 'updated_by']::text[],
    result - array['created_by', 'updated_by']::text[],
    transition_reason
  );

  return result;
end;
$$;

create or replace function public.archive_master_data(
  entity_type text,
  entity_id uuid,
  expected_version integer,
  reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  table_name text;
  before_values jsonb;
  result jsonb;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  case entity_type
    when 'site' then table_name := 'sites';
    when 'department' then table_name := 'departments';
    when 'location' then table_name := 'locations';
    when 'asset_type' then table_name := 'asset_types';
    when 'asset_status' then table_name := 'asset_statuses';
    when 'internet_level' then table_name := 'internet_levels';
    when 'software_category' then table_name := 'software_categories';
    when 'license_metric' then table_name := 'license_metrics';
    when 'product_classification' then table_name := 'product_classifications';
    when 'purchase_form' then table_name := 'purchase_forms';
    when 'expiration_threshold' then table_name := 'expiration_thresholds';
    when 'publisher' then table_name := 'publishers';
    when 'vendor' then table_name := 'vendors';
    else
      raise exception using errcode = '22023', message = 'INVALID_MASTER_ENTITY';
  end case;

  execute pg_catalog.format(
    'select to_jsonb(row_value)
       from public.%I as row_value
      where row_value.id = $1
        and row_value.version = $2
        and row_value.archived_at is null
      for update',
    table_name
  )
  into before_values
  using entity_id, expected_version;

  if before_values is null then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if pg_catalog.btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'REASON_REQUIRED';
  end if;

  execute pg_catalog.format(
    'update public.%I as target
        set is_active = false,
            archived_at = now(),
            archived_by = auth.uid(),
            updated_by = auth.uid()
      where target.id = $1
        and target.version = $2
        and target.archived_at is null
      returning to_jsonb(target)',
    table_name
  )
  into result
  using entity_id, expected_version;

  if result is null then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'archive', entity_type, entity_id,
    'Master data archived',
    before_values - array['created_by', 'updated_by']::text[],
    result - array['created_by', 'updated_by']::text[],
    pg_catalog.btrim(reason)
  );

  return result;
end;
$$;

create or replace function public.set_notification_state(
  recipient_id uuid,
  requested_is_read boolean,
  requested_is_dismissed boolean
)
returns public.notification_recipients
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.notification_recipients%rowtype;
  result public.notification_recipients%rowtype;
begin
  if not private.is_active_user() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select *
  into before_row
  from public.notification_recipients as recipient
  where recipient.id = set_notification_state.recipient_id
    and recipient.profile_id = auth.uid()
  for update;

  if not found then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  update public.notification_recipients
  set is_read = requested_is_read,
      read_at = case
        when requested_is_read then pg_catalog.now()
        else null
      end,
      is_dismissed = requested_is_dismissed,
      dismissed_at = case
        when requested_is_dismissed then pg_catalog.now()
        else null
      end
  where id = recipient_id
    and profile_id = auth.uid()
  returning * into result;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values
  ) values (
    auth.uid(), 'user', 'update', 'notification_recipient', result.id,
    'Notification state updated',
    pg_catalog.jsonb_build_object(
      'is_read', before_row.is_read,
      'is_dismissed', before_row.is_dismissed
    ),
    pg_catalog.jsonb_build_object(
      'is_read', result.is_read,
      'is_dismissed', result.is_dismissed
    )
  );

  return result;
end;
$$;

create or replace function public.update_system_settings(
  expected_version integer,
  payload jsonb
)
returns public.system_settings
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.system_settings%rowtype;
  result public.system_settings%rowtype;
  transition_reason text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select *
  into before_row
  from public.system_settings as settings
  where settings.id = 1
    and settings.version = update_system_settings.expected_version
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if not private.jsonb_has_only_keys(
    payload,
    array[
      'organization_name', 'timezone', 'date_format',
      'session_timeout_minutes', 'max_login_failures',
      'secret_visible_suffix_length', 'over_allocation_policy',
      'default_page_size', 'audit_retention_months', 'reason'
    ]::text[]
  ) then
    raise exception using errcode = '22023', message = 'INVALID_PAYLOAD';
  end if;

  if payload ? 'over_allocation_policy'
    and payload->>'over_allocation_policy'
      not in ('block', 'allow_with_reason') then
    raise exception using errcode = '22023', message = 'INVALID_SETTINGS';
  end if;

  if payload ? 'timezone' and not exists (
    select 1
    from pg_catalog.pg_timezone_names as timezone_name
    where timezone_name.name = payload->>'timezone'
  ) then
    raise exception using errcode = '22023', message = 'INVALID_SETTINGS';
  end if;

  if payload ? 'over_allocation_policy'
    and payload->>'over_allocation_policy' is distinct from
      before_row.over_allocation_policy then
    if pg_catalog.btrim(coalesce(payload->>'reason', '')) = '' then
      raise exception using errcode = '22023', message = 'REASON_REQUIRED';
    end if;
    transition_reason := pg_catalog.btrim(payload->>'reason');
  end if;

  update public.system_settings
  set organization_name = case
        when payload ? 'organization_name'
          then pg_catalog.btrim(payload->>'organization_name')
        else organization_name
      end,
      timezone = case
        when payload ? 'timezone' then payload->>'timezone'
        else timezone
      end,
      date_format = case
        when payload ? 'date_format'
          then pg_catalog.btrim(payload->>'date_format')
        else date_format
      end,
      session_timeout_minutes = case
        when payload ? 'session_timeout_minutes'
          then (payload->>'session_timeout_minutes')::integer
        else session_timeout_minutes
      end,
      max_login_failures = case
        when payload ? 'max_login_failures'
          then (payload->>'max_login_failures')::integer
        else max_login_failures
      end,
      secret_visible_suffix_length = case
        when payload ? 'secret_visible_suffix_length'
          then (payload->>'secret_visible_suffix_length')::smallint
        else secret_visible_suffix_length
      end,
      over_allocation_policy = case
        when payload ? 'over_allocation_policy'
          then payload->>'over_allocation_policy'
        else over_allocation_policy
      end,
      default_page_size = case
        when payload ? 'default_page_size'
          then (payload->>'default_page_size')::smallint
        else default_page_size
      end,
      audit_retention_months = case
        when payload ? 'audit_retention_months'
          then (payload->>'audit_retention_months')::integer
        else audit_retention_months
      end,
      updated_by = auth.uid()
  where id = 1
    and version = expected_version
  returning * into result;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'update', 'system_settings',
    'System settings updated',
    pg_catalog.to_jsonb(before_row) -
      array['created_by', 'updated_by']::text[],
    pg_catalog.to_jsonb(result) -
      array['created_by', 'updated_by']::text[],
    transition_reason
  );

  return result;
end;
$$;

create or replace function public.export_report(
  report_type text,
  filters jsonb
)
returns setof jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_filters jsonb := coalesce(filters, '{}'::jsonb);
  allowed_filter_keys text[];
  filter_key_names jsonb;
begin
  if not private.is_active_user() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  case report_type
    when 'asset_inventory' then
      allowed_filter_keys := array[
        'site_id', 'asset_status_code', 'include_archived'
      ];
    when 'license_inventory' then
      allowed_filter_keys := array[
        'software_product_id', 'record_status',
        'compliance_status', 'include_archived'
      ];
    when 'license_compliance' then
      allowed_filter_keys := array[
        'software_product_id', 'compliance_status'
      ];
    when 'license_expiry' then
      allowed_filter_keys := array[
        'lifecycle_status', 'end_date_from', 'end_date_to'
      ];
    when 'active_allocations' then
      allowed_filter_keys := array[
        'license_entitlement_id', 'target_type', 'site_id'
      ];
    when 'data_quality' then
      allowed_filter_keys := array['entity_type', 'issue_code'];
    else
      raise exception using errcode = '22023', message = 'INVALID_REPORT_TYPE';
  end case;

  if not private.jsonb_has_only_keys(
    requested_filters,
    allowed_filter_keys
  ) then
    raise exception using errcode = '22023', message = 'INVALID_FILTERS';
  end if;

  select coalesce(pg_catalog.jsonb_agg(supplied.key order by supplied.key), '[]'::jsonb)
  into filter_key_names
  from pg_catalog.jsonb_object_keys(requested_filters) as supplied(key);

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type,
    description, metadata
  ) values (
    auth.uid(), 'user', 'export', 'report',
    'Report exported',
    pg_catalog.jsonb_build_object(
      'report_type', report_type,
      'filter_keys', filter_key_names
    )
  );

  case report_type
    when 'asset_inventory' then
      return query
      select pg_catalog.jsonb_build_object(
        'id', asset.id,
        'asset_code', asset.asset_code,
        'computer_name', asset.computer_name,
        'manufacturer', asset.manufacturer,
        'model', asset.model,
        'serial_number', asset.serial_number,
        'purchase_date', asset.purchase_date,
        'site_id', asset.site_id,
        'site_code', asset.site_code,
        'site_name', asset.site_name,
        'location_id', asset.location_id,
        'location_name', asset.location_name,
        'department_id', asset.department_id,
        'department_name', asset.department_name,
        'asset_type_code', asset.asset_type_code,
        'asset_status_code', asset.asset_status_code,
        'operating_system_name', asset.operating_system_name,
        'operating_system_version', asset.operating_system_version,
        'primary_user_name', asset.primary_user_name,
        'responsible_person_name', asset.responsible_person_name,
        'version', asset.version,
        'archived_at', asset.archived_at
      )
      from public.asset_inventory_v as asset
      where (
          not (requested_filters ? 'site_id')
          or asset.site_id = (requested_filters->>'site_id')::uuid
        )
        and (
          not (requested_filters ? 'asset_status_code')
          or asset.asset_status_code =
            requested_filters->>'asset_status_code'
        )
        and (
          coalesce(
            (requested_filters->>'include_archived')::boolean,
            false
          )
          or asset.archived_at is null
        );
    when 'license_inventory' then
      return query
      select pg_catalog.jsonb_build_object(
        'id', license.id,
        'license_reference', license.license_reference,
        'software_product_id', license.software_product_id,
        'product_name', license.product_name,
        'version_edition', license.version_edition,
        'publisher_name', license.publisher_name,
        'vendor_id', license.vendor_id,
        'license_metric_id', license.license_metric_id,
        'owned_quantity', license.owned_quantity,
        'allocated_quantity', license.allocated_quantity,
        'available_quantity', license.available_quantity,
        'compliance_status', license.compliance_status,
        'lifecycle_status', license.lifecycle_status,
        'days_remaining', license.days_remaining,
        'record_status', license.record_status,
        'scope_mode', license.scope_mode,
        'purchase_date', license.purchase_date,
        'start_date', license.start_date,
        'end_date', license.end_date,
        'license_key_masked', license.license_key_masked,
        'serial_number_masked', license.serial_number_masked,
        'remark', license.remark,
        'version', license.version,
        'archived_at', license.archived_at
      )
      from public.license_safe_v as license
      where (
          not (requested_filters ? 'software_product_id')
          or license.software_product_id =
            (requested_filters->>'software_product_id')::uuid
        )
        and (
          not (requested_filters ? 'record_status')
          or license.record_status::text =
            requested_filters->>'record_status'
        )
        and (
          not (requested_filters ? 'compliance_status')
          or license.compliance_status =
            requested_filters->>'compliance_status'
        )
        and (
          coalesce(
            (requested_filters->>'include_archived')::boolean,
            false
          )
          or license.archived_at is null
        );
    when 'license_compliance' then
      return query
      select pg_catalog.jsonb_build_object(
        'id', compliance.id,
        'software_product_id', compliance.software_product_id,
        'license_reference', compliance.license_reference,
        'owned_quantity', compliance.owned_quantity,
        'allocated_quantity', compliance.allocated_quantity,
        'available_quantity', compliance.available_quantity,
        'compliance_status', compliance.compliance_status
      )
      from public.license_compliance_v as compliance
      where (
          not (requested_filters ? 'software_product_id')
          or compliance.software_product_id =
            (requested_filters->>'software_product_id')::uuid
        )
        and (
          not (requested_filters ? 'compliance_status')
          or compliance.compliance_status =
            requested_filters->>'compliance_status'
        );
    when 'license_expiry' then
      return query
      select pg_catalog.jsonb_build_object(
        'id', expiry.id,
        'start_date', expiry.start_date,
        'end_date', expiry.end_date,
        'days_remaining', expiry.days_remaining,
        'threshold_days', expiry.threshold_days,
        'lifecycle_status', expiry.lifecycle_status
      )
      from public.license_expiry_v as expiry
      where (
          not (requested_filters ? 'lifecycle_status')
          or expiry.lifecycle_status =
            requested_filters->>'lifecycle_status'
        )
        and (
          not (requested_filters ? 'end_date_from')
          or expiry.end_date >=
            (requested_filters->>'end_date_from')::date
        )
        and (
          not (requested_filters ? 'end_date_to')
          or expiry.end_date <=
            (requested_filters->>'end_date_to')::date
        );
    when 'active_allocations' then
      return query
      select pg_catalog.jsonb_build_object(
        'id', allocation.id,
        'license_entitlement_id', allocation.license_entitlement_id,
        'target_type', allocation.target_type,
        'asset_id', allocation.asset_id,
        'person_id', allocation.person_id,
        'site_id', allocation.site_id,
        'quantity', allocation.quantity,
        'allocated_at', allocation.allocated_at,
        'installed_at', allocation.installed_at,
        'target_display_name', allocation.target_display_name
      )
      from public.active_allocations_v as allocation
      where (
          not (requested_filters ? 'license_entitlement_id')
          or allocation.license_entitlement_id =
            (requested_filters->>'license_entitlement_id')::uuid
        )
        and (
          not (requested_filters ? 'target_type')
          or allocation.target_type::text =
            requested_filters->>'target_type'
        )
        and (
          not (requested_filters ? 'site_id')
          or allocation.site_id =
            (requested_filters->>'site_id')::uuid
        );
    when 'data_quality' then
      return query
      select pg_catalog.jsonb_build_object(
        'entity_type', issue.entity_type,
        'entity_id', issue.entity_id,
        'issue_code', issue.issue_code,
        'description', issue.description
      )
      from public.data_quality_v as issue
      where (
          not (requested_filters ? 'entity_type')
          or issue.entity_type = requested_filters->>'entity_type'
        )
        and (
          not (requested_filters ? 'issue_code')
          or issue.issue_code = requested_filters->>'issue_code'
        );
  end case;

  return;
end;
$$;

revoke all on function private.jsonb_has_only_keys(jsonb, text[])
from public, anon, authenticated;
revoke all on function private.normalize_license_secret(text, text)
from public, anon, authenticated;
revoke all on function private.license_fingerprint_pepper()
from public, anon, authenticated;
revoke all on function private.fingerprint_license_secret(text, text)
from public, anon, authenticated;
revoke all on function private.assert_no_license_secret_collision(text[], bytea[])
from public, anon, authenticated;
revoke all on function private.mask_license_secret(text)
from public, anon, authenticated;

revoke all on schema vault from public, anon, authenticated;
revoke all on all tables in schema vault from public, anon, authenticated;
revoke execute on function vault.create_secret(text, text, text, uuid)
from public, anon, authenticated;
revoke execute on function vault.update_secret(uuid, text, text, text, uuid)
from public, anon, authenticated;

revoke all on function public.create_license_entitlement(jsonb, jsonb)
from public, anon, authenticated;
revoke all on function public.update_license_entitlement(uuid, integer, jsonb)
from public, anon, authenticated;
revoke all on function public.archive_license_entitlement(uuid, integer, text)
from public, anon, authenticated;
revoke all on function public.rotate_license_secret(uuid, text, text, text)
from public, anon, authenticated;
revoke all on function public.reveal_license_secret(uuid, text, uuid)
from public, anon, authenticated;
revoke all on function public.update_master_data(text, uuid, integer, jsonb)
from public, anon, authenticated;
revoke all on function public.archive_master_data(text, uuid, integer, text)
from public, anon, authenticated;
revoke all on function public.set_notification_state(uuid, boolean, boolean)
from public, anon, authenticated;
revoke all on function public.update_system_settings(integer, jsonb)
from public, anon, authenticated;
revoke all on function public.export_report(text, jsonb)
from public, anon, authenticated;

grant execute on function public.create_license_entitlement(jsonb, jsonb)
to authenticated;
grant execute on function public.update_license_entitlement(uuid, integer, jsonb)
to authenticated;
grant execute on function public.archive_license_entitlement(uuid, integer, text)
to authenticated;
grant execute on function public.rotate_license_secret(uuid, text, text, text)
to authenticated;
grant execute on function public.reveal_license_secret(uuid, text, uuid)
to authenticated;
grant execute on function public.update_master_data(text, uuid, integer, jsonb)
to authenticated;
grant execute on function public.archive_master_data(text, uuid, integer, text)
to authenticated;
grant execute on function public.set_notification_state(uuid, boolean, boolean)
to authenticated;
grant execute on function public.update_system_settings(integer, jsonb)
to authenticated;
grant execute on function public.export_report(text, jsonb)
to authenticated;

revoke insert, update, delete, truncate, references, trigger
on public.notification_recipients from authenticated;
grant select on public.notification_feed_v to authenticated;
