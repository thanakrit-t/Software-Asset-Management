create or replace function private.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select case when private.is_active_user() then auth.uid() else null end;
$$;

revoke all on function private.current_profile_id() from public, anon, authenticated;

create view public.asset_current_people_v
with (security_invoker = true)
as
select
  assignment.asset_id,
  max(person.display_name) filter (where assignment.assignment_role = 'primary_user') as primary_user_name,
  max(person.display_name) filter (where assignment.assignment_role = 'responsible_person') as responsible_person_name
from public.asset_person_assignments as assignment
join public.people as person on person.id = assignment.person_id
where assignment.valid_to is null
  and assignment.archived_at is null
  and person.archived_at is null
group by assignment.asset_id;

create view public.asset_inventory_v
with (security_invoker = true)
as
select
  asset.id,
  asset.asset_code,
  asset.computer_name,
  asset.manufacturer,
  asset.model,
  asset.serial_number,
  asset.purchase_date,
  asset.risk_access_level,
  asset.remark,
  asset.version,
  asset.archived_at,
  site.id as site_id,
  site.code as site_code,
  coalesce(site.name_th, site.name_en) as site_name,
  location.id as location_id,
  location.name as location_name,
  department.id as department_id,
  department.name as department_name,
  asset_type.code as asset_type_code,
  asset_status.code as asset_status_code,
  product.id as operating_system_product_id,
  product.name as operating_system_name,
  product.version_edition as operating_system_version,
  people.primary_user_name,
  people.responsible_person_name
from public.assets as asset
join public.sites as site on site.id = asset.site_id
join public.asset_types as asset_type on asset_type.id = asset.asset_type_id
join public.asset_statuses as asset_status on asset_status.id = asset.asset_status_id
left join public.locations as location on location.id = asset.location_id
left join public.departments as department on department.id = asset.department_id
left join public.software_products as product on product.id = asset.operating_system_product_id
left join public.asset_current_people_v as people on people.asset_id = asset.id;

create view public.active_allocations_v
with (security_invoker = true)
as
select
  allocation.id,
  allocation.license_entitlement_id,
  allocation.target_type,
  allocation.asset_id,
  allocation.person_id,
  allocation.site_id,
  allocation.quantity,
  allocation.allocated_at,
  allocation.installed_at,
  allocation.override_used,
  allocation.override_reason,
  allocation.remark,
  case allocation.target_type
    when 'asset' then coalesce(asset.computer_name, asset.asset_code)
    when 'person' then person.display_name
    when 'site' then coalesce(site.name_th, site.name_en)
  end as target_display_name
from public.license_allocations as allocation
left join public.assets as asset on asset.id = allocation.asset_id
left join public.people as person on person.id = allocation.person_id
left join public.sites as site on site.id = allocation.site_id
where allocation.allocation_status = 'active';

create view public.license_compliance_v
with (security_invoker = true)
as
select
  entitlement.id,
  entitlement.software_product_id,
  entitlement.license_reference,
  entitlement.owned_quantity,
  coalesce(sum(allocation.quantity) filter (where allocation.allocation_status = 'active'), 0)::integer as allocated_quantity,
  case
    when entitlement.owned_quantity is null then null
    else entitlement.owned_quantity - coalesce(sum(allocation.quantity) filter (where allocation.allocation_status = 'active'), 0)::integer
  end as available_quantity,
  case
    when entitlement.owned_quantity is null then 'untracked'
    when coalesce(sum(allocation.quantity) filter (where allocation.allocation_status = 'active'), 0) > entitlement.owned_quantity then 'over_allocated'
    else 'compliant'
  end as compliance_status
from public.license_entitlements as entitlement
left join public.license_allocations as allocation
  on allocation.license_entitlement_id = entitlement.id
group by entitlement.id;

create view public.license_expiry_v
with (security_invoker = true)
as
select
  entitlement.id,
  entitlement.start_date,
  entitlement.end_date,
  case when entitlement.end_date is null then null else entitlement.end_date - business.today end as days_remaining,
  threshold.days_before_expiry as threshold_days,
  case
    when entitlement.record_status = 'archived' then 'archived'
    when entitlement.record_status = 'deactivated' then 'deactivated'
    when metric.is_perpetual then 'perpetual'
    when entitlement.end_date < business.today then 'expired'
    when threshold.days_before_expiry is not null then 'expiring_' || threshold.days_before_expiry::text
    else 'active'
  end as lifecycle_status
from public.license_entitlements as entitlement
join public.license_metrics as metric on metric.id = entitlement.license_metric_id
cross join lateral (
  select (now() at time zone settings.timezone)::date as today
  from public.system_settings as settings
  where settings.id = 1
) as business
left join lateral (
  select expiration.days_before_expiry
  from public.expiration_thresholds as expiration
  where expiration.is_active
    and expiration.archived_at is null
    and entitlement.end_date is not null
    and entitlement.end_date >= business.today
    and entitlement.end_date - business.today <= expiration.days_before_expiry
  order by expiration.days_before_expiry
  limit 1
) as threshold on true;

create view public.license_safe_v
with (security_invoker = true)
as
select
  entitlement.id,
  entitlement.license_reference,
  entitlement.software_product_id,
  product.name as product_name,
  product.version_edition,
  publisher.name_en as publisher_name,
  entitlement.vendor_id,
  entitlement.license_metric_id,
  entitlement.owned_quantity,
  compliance.allocated_quantity,
  compliance.available_quantity,
  compliance.compliance_status,
  expiry.lifecycle_status,
  expiry.days_remaining,
  entitlement.record_status,
  entitlement.scope_mode,
  entitlement.purchase_date,
  entitlement.start_date,
  entitlement.end_date,
  entitlement.license_key_masked,
  entitlement.serial_number_masked,
  entitlement.remark,
  entitlement.version,
  entitlement.archived_at
from public.license_entitlements as entitlement
join public.software_products as product on product.id = entitlement.software_product_id
join public.publishers as publisher on publisher.id = product.publisher_id
join public.license_compliance_v as compliance on compliance.id = entitlement.id
join public.license_expiry_v as expiry on expiry.id = entitlement.id;

create view public.dashboard_summary_v
with (security_invoker = true)
as
select
  (select count(*)::integer from public.assets where archived_at is null) as active_asset_count,
  (select count(*)::integer from public.license_entitlements where archived_at is null) as license_count,
  (select coalesce(sum(owned_quantity), 0)::integer from public.license_entitlements where archived_at is null) as owned_quantity,
  (select coalesce(sum(allocated_quantity), 0)::integer from public.license_compliance_v) as allocated_quantity,
  (select count(*)::integer from public.license_compliance_v where compliance_status = 'over_allocated') as over_allocated_count,
  (select count(*)::integer from public.license_expiry_v where lifecycle_status = 'expired') as expired_count;

create view public.data_quality_v
with (security_invoker = true)
as
select 'asset'::text as entity_type, asset.id as entity_id, 'MISSING_ASSET_CODE'::text as issue_code,
  'Asset code is missing'::text as description
from public.assets as asset
where asset.asset_code is null and asset.migration_reference is null and asset.archived_at is null
union all
select 'license', entitlement.id, 'UNTRACKED_QUANTITY', 'Owned quantity is not tracked'
from public.license_entitlements as entitlement
where entitlement.owned_quantity is null and entitlement.archived_at is null;

create view public.notification_feed_v
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
  recipient.dismissed_at
from public.notifications as notification
join public.notification_recipients as recipient
  on recipient.notification_id = notification.id
where recipient.profile_id = auth.uid();

create view public.audit_log_admin_v
with (security_invoker = true)
as
select
  event.id,
  event.occurred_at,
  event.actor_profile_id,
  event.actor_type,
  event.action,
  event.entity_type,
  event.entity_id,
  event.description,
  event.old_values,
  event.new_values,
  event.reason,
  event.correlation_id,
  event.metadata
from audit.audit_events as event
where (select private.is_admin());

create or replace function public.allocate_license(payload jsonb)
returns public.license_allocations
language plpgsql
security definer
set search_path = ''
as $$
declare
  entitlement public.license_entitlements%rowtype;
  metric public.license_metrics%rowtype;
  result public.license_allocations%rowtype;
  requested_target public.allocation_target_type;
  requested_quantity integer;
  target_site_id uuid;
  active_quantity integer;
  policy text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  requested_target := (payload->>'target_type')::public.allocation_target_type;
  requested_quantity := coalesce((payload->>'quantity')::integer, 1);
  if requested_quantity <= 0 then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_TARGET';
  end if;

  select * into entitlement
  from public.license_entitlements
  where id = (payload->>'license_entitlement_id')::uuid
  for update;

  if not found or entitlement.record_status <> 'active' or entitlement.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'LICENSE_NOT_ACTIVE';
  end if;

  select * into strict metric
  from public.license_metrics
  where id = entitlement.license_metric_id;

  if (metric.target_mode = 'device' and requested_target <> 'asset')
    or (metric.target_mode = 'named_user' and requested_target <> 'person')
    or (metric.target_mode = 'site' and requested_target <> 'site') then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_TARGET';
  end if;

  case requested_target
    when 'asset' then
      select site_id into target_site_id from public.assets
      where id = (payload->>'asset_id')::uuid and archived_at is null;
    when 'person' then
      select primary_site_id into target_site_id from public.people
      where id = (payload->>'person_id')::uuid and archived_at is null;
    when 'site' then
      select id into target_site_id from public.sites
      where id = (payload->>'site_id')::uuid and archived_at is null and is_active;
  end case;

  if target_site_id is null then
    raise exception using errcode = '22023', message = 'INVALID_LICENSE_TARGET';
  end if;

  if entitlement.scope_mode = 'selected_sites' and not exists (
    select 1 from public.license_site_scopes as scope
    where scope.license_entitlement_id = entitlement.id
      and scope.site_id = target_site_id
  ) then
    raise exception using errcode = '22023', message = 'INVALID_SITE_SCOPE';
  end if;

  select coalesce(sum(quantity), 0)::integer into active_quantity
  from public.license_allocations
  where license_entitlement_id = entitlement.id
    and allocation_status = 'active';

  select over_allocation_policy into policy
  from public.system_settings where id = 1;

  if entitlement.owned_quantity is not null
    and active_quantity + requested_quantity > entitlement.owned_quantity
    and not (
      policy = 'allow_with_reason'
      and coalesce((payload->>'override_used')::boolean, false)
      and btrim(coalesce(payload->>'override_reason', '')) <> ''
    ) then
    raise exception using errcode = 'P0001', message = 'INSUFFICIENT_LICENSE';
  end if;

  insert into public.license_allocations (
    license_entitlement_id, target_type, asset_id, person_id, site_id,
    quantity, allocated_at, installed_at, override_used, override_reason,
    remark, created_by, updated_by
  )
  values (
    entitlement.id,
    requested_target,
    (payload->>'asset_id')::uuid,
    (payload->>'person_id')::uuid,
    (payload->>'site_id')::uuid,
    requested_quantity,
    coalesce((payload->>'allocated_at')::date, current_date),
    (payload->>'installed_at')::date,
    coalesce((payload->>'override_used')::boolean, false),
    payload->>'override_reason',
    payload->>'remark',
    auth.uid(),
    auth.uid()
  )
  returning * into result;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values, reason
  ) values (
    auth.uid(), 'user', 'allocate', 'license_allocation', result.id,
    'License allocation created',
    jsonb_build_object(
      'license_entitlement_id', entitlement.id,
      'target_type', result.target_type,
      'quantity', result.quantity
    ),
    result.override_reason
  );

  return result;
exception
  when unique_violation then
    raise exception using errcode = '23505', message = 'ALLOCATION_DUPLICATE';
end;
$$;

create or replace function public.release_license_allocation(
  allocation_id uuid,
  expected_version integer,
  reason text
)
returns public.license_allocations
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.license_allocations%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;
  if btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'OVERRIDE_REASON_REQUIRED';
  end if;

  update public.license_allocations
  set allocation_status = 'released',
      released_at = current_date,
      released_by = auth.uid(),
      release_reason = reason,
      updated_by = auth.uid()
  where id = allocation_id
    and version = expected_version
    and allocation_status = 'active'
  returning * into result;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values, reason
  ) values (
    auth.uid(), 'user', 'release', 'license_allocation', result.id,
    'License allocation released',
    jsonb_build_object('allocation_status', 'released'),
    reason
  );
  return result;
end;
$$;

create or replace function public.set_user_role(
  profile_id uuid,
  new_role public.app_role,
  reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing public.profiles%rowtype;
  result public.profiles%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;
  if btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'OVERRIDE_REASON_REQUIRED';
  end if;
  select * into existing from public.profiles where id = profile_id for update;
  if existing.app_role = 'admin' and new_role <> 'admin' and (
    select count(*) from public.profiles
    where app_role = 'admin' and account_status = 'active'
  ) <= 1 then
    raise exception using errcode = 'P0001', message = 'LAST_ADMIN_PROTECTED';
  end if;
  update public.profiles set app_role = new_role, updated_by = auth.uid()
  where id = profile_id returning * into result;
  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'role_change', 'profile', profile_id,
    'User role changed',
    jsonb_build_object('app_role', existing.app_role),
    jsonb_build_object('app_role', result.app_role),
    reason
  );
  return result;
end;
$$;

create or replace function public.set_user_status(
  profile_id uuid,
  new_status public.account_status,
  reason text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing public.profiles%rowtype;
  result public.profiles%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;
  if btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'OVERRIDE_REASON_REQUIRED';
  end if;
  select * into existing from public.profiles where id = profile_id for update;
  if existing.app_role = 'admin' and existing.account_status = 'active'
    and new_status <> 'active' and (
      select count(*) from public.profiles
      where app_role = 'admin' and account_status = 'active'
    ) <= 1 then
    raise exception using errcode = 'P0001', message = 'LAST_ADMIN_PROTECTED';
  end if;
  update public.profiles
  set account_status = new_status,
      deactivated_at = case when new_status = 'inactive' then now() else null end,
      deactivated_by = case when new_status = 'inactive' then auth.uid() else null end,
      updated_by = auth.uid()
  where id = profile_id returning * into result;
  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values, reason
  ) values (
    auth.uid(), 'user', 'status_change', 'profile', profile_id,
    'User account status changed',
    jsonb_build_object('account_status', existing.account_status),
    jsonb_build_object('account_status', result.account_status),
    reason
  );
  return result;
end;
$$;

revoke all on function public.allocate_license(jsonb) from public, anon;
revoke all on function public.release_license_allocation(uuid, integer, text) from public, anon;
revoke all on function public.set_user_role(uuid, public.app_role, text) from public, anon;
revoke all on function public.set_user_status(uuid, public.account_status, text) from public, anon;
