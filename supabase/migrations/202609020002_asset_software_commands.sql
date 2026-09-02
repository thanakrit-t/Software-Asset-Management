create or replace function public.create_asset(payload jsonb)
returns public.assets
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_asset_type_id uuid;
  resolved_asset_status_id uuid;
  resolved_site_id uuid;
  resolved_location_id uuid;
  resolved_department_id uuid;
  resolved_internet_level_id uuid;
  resolved_operating_system_product_id uuid;
  result public.assets%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select asset_type.id into resolved_asset_type_id
  from public.asset_types as asset_type
  where asset_type.id = (payload->>'asset_type_id')::uuid
    and asset_type.is_active
    and asset_type.archived_at is null;

  select asset_status.id into resolved_asset_status_id
  from public.asset_statuses as asset_status
  where asset_status.id = (payload->>'asset_status_id')::uuid
    and asset_status.is_active
    and asset_status.archived_at is null;

  select site.id into resolved_site_id
  from public.sites as site
  where site.id = (payload->>'site_id')::uuid
    and site.is_active
    and site.archived_at is null;

  if resolved_asset_type_id is null
    or resolved_asset_status_id is null
    or resolved_site_id is null then
    raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
  end if;

  if payload ? 'location_id' and payload->>'location_id' is not null then
    select location.id into resolved_location_id
    from public.locations as location
    where location.id = (payload->>'location_id')::uuid
      and location.site_id = resolved_site_id
      and location.is_active
      and location.archived_at is null;

    if resolved_location_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;
  end if;

  if payload ? 'department_id' and payload->>'department_id' is not null then
    select department.id into resolved_department_id
    from public.departments as department
    where department.id = (payload->>'department_id')::uuid
      and department.is_active
      and department.archived_at is null;

    if resolved_department_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;
  end if;

  if payload ? 'internet_level_id' and payload->>'internet_level_id' is not null then
    select internet_level.id into resolved_internet_level_id
    from public.internet_levels as internet_level
    where internet_level.id = (payload->>'internet_level_id')::uuid
      and internet_level.is_active
      and internet_level.archived_at is null;

    if resolved_internet_level_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;
  end if;

  if payload ? 'operating_system_product_id'
    and payload->>'operating_system_product_id' is not null then
    select product.id into resolved_operating_system_product_id
    from public.software_products as product
    where product.id = (payload->>'operating_system_product_id')::uuid
      and product.archived_at is null;

    if resolved_operating_system_product_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;
  end if;

  insert into public.assets (
    asset_code, computer_name, asset_type_id, asset_status_id, site_id,
    location_id, department_id, manufacturer, model, serial_number,
    purchase_date, internet_level_id, risk_access_level,
    operating_system_product_id, remark, created_by, updated_by
  ) values (
    nullif(btrim(payload->>'asset_code'), ''),
    nullif(btrim(payload->>'computer_name'), ''),
    resolved_asset_type_id,
    resolved_asset_status_id,
    resolved_site_id,
    resolved_location_id,
    resolved_department_id,
    nullif(btrim(payload->>'manufacturer'), ''),
    nullif(btrim(payload->>'model'), ''),
    nullif(btrim(payload->>'serial_number'), ''),
    (payload->>'purchase_date')::date,
    resolved_internet_level_id,
    nullif(btrim(payload->>'risk_access_level'), ''),
    resolved_operating_system_product_id,
    nullif(btrim(payload->>'remark'), ''),
    auth.uid(),
    auth.uid()
  )
  returning * into result;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values
  ) values (
    auth.uid(), 'user', 'create', 'asset', result.id,
    'Asset created',
    to_jsonb(result) - array['created_by','updated_by']
  );

  return result;
end;
$$;

create or replace function public.update_asset(
  asset_id uuid,
  expected_version integer,
  payload jsonb
)
returns public.assets
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.assets%rowtype;
  result public.assets%rowtype;
  resolved_asset_type_id uuid;
  resolved_asset_status_id uuid;
  resolved_site_id uuid;
  resolved_location_id uuid;
  resolved_department_id uuid;
  resolved_internet_level_id uuid;
  resolved_operating_system_product_id uuid;
  transition_reason text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select * into before_row
  from public.assets as asset
  where asset.id = update_asset.asset_id
    and asset.version = update_asset.expected_version
    and asset.archived_at is null
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  resolved_asset_type_id := before_row.asset_type_id;
  resolved_asset_status_id := before_row.asset_status_id;
  resolved_site_id := before_row.site_id;
  resolved_location_id := before_row.location_id;
  resolved_department_id := before_row.department_id;
  resolved_internet_level_id := before_row.internet_level_id;
  resolved_operating_system_product_id := before_row.operating_system_product_id;

  if payload ? 'asset_type_id' then
    select asset_type.id into resolved_asset_type_id
    from public.asset_types as asset_type
    where asset_type.id = (payload->>'asset_type_id')::uuid
      and asset_type.is_active
      and asset_type.archived_at is null;

    if resolved_asset_type_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;
  end if;

  if payload ? 'asset_status_id' then
    select asset_status.id into resolved_asset_status_id
    from public.asset_statuses as asset_status
    where asset_status.id = (payload->>'asset_status_id')::uuid
      and asset_status.is_active
      and asset_status.archived_at is null;

    if resolved_asset_status_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;

    if resolved_asset_status_id is distinct from before_row.asset_status_id then
      if btrim(coalesce(payload->>'reason', '')) = '' then
        raise exception using errcode = '22023', message = 'REASON_REQUIRED';
      end if;
      transition_reason := btrim(payload->>'reason');
    end if;
  end if;

  if payload ? 'site_id' then
    select site.id into resolved_site_id
    from public.sites as site
    where site.id = (payload->>'site_id')::uuid
      and site.is_active
      and site.archived_at is null;

    if resolved_site_id is null then
      raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
    end if;
  end if;

  if payload ? 'location_id' then
    resolved_location_id := null;
    if payload->>'location_id' is not null then
      select location.id into resolved_location_id
      from public.locations as location
      where location.id = (payload->>'location_id')::uuid
        and location.site_id = resolved_site_id
        and location.is_active
        and location.archived_at is null;

      if resolved_location_id is null then
        raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
      end if;
    end if;
  elsif payload ? 'site_id' and resolved_location_id is not null and not exists (
    select 1
    from public.locations as location
    where location.id = resolved_location_id
      and location.site_id = resolved_site_id
  ) then
    raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
  end if;

  if payload ? 'department_id' then
    resolved_department_id := null;
    if payload->>'department_id' is not null then
      select department.id into resolved_department_id
      from public.departments as department
      where department.id = (payload->>'department_id')::uuid
        and department.is_active
        and department.archived_at is null;

      if resolved_department_id is null then
        raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
      end if;
    end if;
  end if;

  if payload ? 'internet_level_id' then
    resolved_internet_level_id := null;
    if payload->>'internet_level_id' is not null then
      select internet_level.id into resolved_internet_level_id
      from public.internet_levels as internet_level
      where internet_level.id = (payload->>'internet_level_id')::uuid
        and internet_level.is_active
        and internet_level.archived_at is null;

      if resolved_internet_level_id is null then
        raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
      end if;
    end if;
  end if;

  if payload ? 'operating_system_product_id' then
    resolved_operating_system_product_id := null;
    if payload->>'operating_system_product_id' is not null then
      select product.id into resolved_operating_system_product_id
      from public.software_products as product
      where product.id = (payload->>'operating_system_product_id')::uuid
        and product.archived_at is null;

      if resolved_operating_system_product_id is null then
        raise exception using errcode = '22023', message = 'INVALID_ASSET_REFERENCE';
      end if;
    end if;
  end if;

  update public.assets
  set asset_code = case
        when payload ? 'asset_code' then nullif(btrim(payload->>'asset_code'), '')
        else asset_code
      end,
      computer_name = coalesce(nullif(btrim(payload->>'computer_name'), ''), computer_name),
      asset_type_id = resolved_asset_type_id,
      asset_status_id = resolved_asset_status_id,
      site_id = resolved_site_id,
      location_id = resolved_location_id,
      department_id = resolved_department_id,
      manufacturer = case when payload ? 'manufacturer' then nullif(btrim(payload->>'manufacturer'), '') else manufacturer end,
      model = case when payload ? 'model' then nullif(btrim(payload->>'model'), '') else model end,
      serial_number = case when payload ? 'serial_number' then nullif(btrim(payload->>'serial_number'), '') else serial_number end,
      purchase_date = case when payload ? 'purchase_date' then (payload->>'purchase_date')::date else purchase_date end,
      internet_level_id = resolved_internet_level_id,
      risk_access_level = case when payload ? 'risk_access_level' then nullif(btrim(payload->>'risk_access_level'), '') else risk_access_level end,
      operating_system_product_id = resolved_operating_system_product_id,
      remark = case when payload ? 'remark' then nullif(btrim(payload->>'remark'), '') else remark end,
      updated_by = auth.uid()
  where id = asset_id
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
    auth.uid(), 'user', 'update', 'asset', result.id,
    'Asset updated',
    to_jsonb(before_row) - array['created_by','updated_by'],
    to_jsonb(result) - array['created_by','updated_by'],
    transition_reason
  );

  return result;
end;
$$;

create or replace function public.archive_asset(
  asset_id uuid,
  expected_version integer,
  reason text,
  acknowledge_allocations boolean
)
returns public.assets
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.assets%rowtype;
  result public.assets%rowtype;
  active_allocation_count integer;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select * into before_row
  from public.assets as asset
  where asset.id = archive_asset.asset_id
    and asset.version = archive_asset.expected_version
    and asset.archived_at is null
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'REASON_REQUIRED';
  end if;

  select count(*)::integer into active_allocation_count
  from public.license_allocations as allocation
  where allocation.asset_id = archive_asset.asset_id
    and allocation.allocation_status = 'active';

  if active_allocation_count > 0 and not coalesce(acknowledge_allocations, false) then
    raise exception using errcode = 'P0001', message = 'ACTIVE_ALLOCATIONS_EXIST';
  end if;

  update public.assets
  set archived_at = now(),
      archived_by = auth.uid(),
      updated_by = auth.uid()
  where id = asset_id
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
    auth.uid(), 'user', 'archive', 'asset', result.id,
    'Asset archived',
    to_jsonb(before_row) - array['created_by','updated_by'],
    to_jsonb(result) - array['created_by','updated_by'],
    reason
  );

  return result;
end;
$$;

create or replace function public.create_software_product(payload jsonb)
returns public.software_products
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_publisher_id uuid;
  resolved_category_id uuid;
  result public.software_products%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select publisher.id into resolved_publisher_id
  from public.publishers as publisher
  where publisher.id = (payload->>'publisher_id')::uuid
    and publisher.is_active
    and publisher.archived_at is null;

  select category.id into resolved_category_id
  from public.software_categories as category
  where category.id = (payload->>'category_id')::uuid
    and category.is_active
    and category.archived_at is null;

  if resolved_publisher_id is null or resolved_category_id is null then
    raise exception using errcode = '22023', message = 'INVALID_SOFTWARE_REFERENCE';
  end if;

  insert into public.software_products (
    publisher_id, category_id, name, version_edition, support_status,
    end_of_life_date, remark, created_by, updated_by
  ) values (
    resolved_publisher_id,
    resolved_category_id,
    btrim(payload->>'name'),
    coalesce(btrim(payload->>'version_edition'), ''),
    coalesce(nullif(btrim(payload->>'support_status'), ''), 'unknown'),
    (payload->>'end_of_life_date')::date,
    nullif(btrim(payload->>'remark'), ''),
    auth.uid(),
    auth.uid()
  )
  returning * into result;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, new_values
  ) values (
    auth.uid(), 'user', 'create', 'software_product', result.id,
    'Software product created',
    to_jsonb(result) - array['created_by','updated_by']
  );

  return result;
exception
  when unique_violation then
    raise exception using errcode = '23505', message = 'DUPLICATE_RECORD';
end;
$$;

create or replace function public.update_software_product(
  product_id uuid,
  expected_version integer,
  payload jsonb
)
returns public.software_products
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.software_products%rowtype;
  result public.software_products%rowtype;
  resolved_publisher_id uuid;
  resolved_category_id uuid;
  transition_reason text;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select * into before_row
  from public.software_products as product
  where product.id = update_software_product.product_id
    and product.version = update_software_product.expected_version
    and product.archived_at is null
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  resolved_publisher_id := before_row.publisher_id;
  resolved_category_id := before_row.category_id;

  if payload ? 'publisher_id' then
    select publisher.id into resolved_publisher_id
    from public.publishers as publisher
    where publisher.id = (payload->>'publisher_id')::uuid
      and publisher.is_active
      and publisher.archived_at is null;

    if resolved_publisher_id is null then
      raise exception using errcode = '22023', message = 'INVALID_SOFTWARE_REFERENCE';
    end if;
  end if;

  if payload ? 'category_id' then
    select category.id into resolved_category_id
    from public.software_categories as category
    where category.id = (payload->>'category_id')::uuid
      and category.is_active
      and category.archived_at is null;

    if resolved_category_id is null then
      raise exception using errcode = '22023', message = 'INVALID_SOFTWARE_REFERENCE';
    end if;
  end if;

  if payload ? 'support_status'
    and coalesce(nullif(btrim(payload->>'support_status'), ''), 'unknown')
      is distinct from before_row.support_status then
    if btrim(coalesce(payload->>'reason', '')) = '' then
      raise exception using errcode = '22023', message = 'REASON_REQUIRED';
    end if;
    transition_reason := btrim(payload->>'reason');
  end if;

  update public.software_products
  set publisher_id = resolved_publisher_id,
      category_id = resolved_category_id,
      name = coalesce(nullif(btrim(payload->>'name'), ''), name),
      version_edition = case
        when payload ? 'version_edition' then coalesce(btrim(payload->>'version_edition'), '')
        else version_edition
      end,
      support_status = case
        when payload ? 'support_status' then coalesce(nullif(btrim(payload->>'support_status'), ''), 'unknown')
        else support_status
      end,
      end_of_life_date = case
        when payload ? 'end_of_life_date' then (payload->>'end_of_life_date')::date
        else end_of_life_date
      end,
      remark = case when payload ? 'remark' then nullif(btrim(payload->>'remark'), '') else remark end,
      updated_by = auth.uid()
  where id = product_id
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
    auth.uid(), 'user', 'update', 'software_product', result.id,
    'Software product updated',
    to_jsonb(before_row) - array['created_by','updated_by'],
    to_jsonb(result) - array['created_by','updated_by'],
    transition_reason
  );

  return result;
end;
$$;

create or replace function public.archive_software_product(
  product_id uuid,
  expected_version integer,
  reason text
)
returns public.software_products
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.software_products%rowtype;
  result public.software_products%rowtype;
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select * into before_row
  from public.software_products as product
  where product.id = archive_software_product.product_id
    and product.version = archive_software_product.expected_version
    and product.archived_at is null
  for update;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  if btrim(coalesce(reason, '')) = '' then
    raise exception using errcode = '22023', message = 'REASON_REQUIRED';
  end if;

  update public.software_products
  set archived_at = now(),
      archived_by = auth.uid(),
      updated_by = auth.uid()
  where id = product_id
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
    auth.uid(), 'user', 'archive', 'software_product', result.id,
    'Software product archived',
    to_jsonb(before_row) - array['created_by','updated_by'],
    to_jsonb(result) - array['created_by','updated_by'],
    reason
  );

  return result;
end;
$$;

revoke all on function public.create_asset(jsonb) from public, anon;
grant execute on function public.create_asset(jsonb) to authenticated;

revoke all on function public.update_asset(uuid, integer, jsonb) from public, anon;
grant execute on function public.update_asset(uuid, integer, jsonb) to authenticated;

revoke all on function public.archive_asset(uuid, integer, text, boolean) from public, anon;
grant execute on function public.archive_asset(uuid, integer, text, boolean) to authenticated;

revoke all on function public.create_software_product(jsonb) from public, anon;
grant execute on function public.create_software_product(jsonb) to authenticated;

revoke all on function public.update_software_product(uuid, integer, jsonb) from public, anon;
grant execute on function public.update_software_product(uuid, integer, jsonb) to authenticated;

revoke all on function public.archive_software_product(uuid, integer, text) from public, anon;
grant execute on function public.archive_software_product(uuid, integer, text) to authenticated;
