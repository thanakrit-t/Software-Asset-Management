create or replace function public.begin_import_batch(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_batch_id uuid := extensions.gen_random_uuid();
  source jsonb;
  source_count integer;
  asset_count integer;
  license_count integer;
  source_checksum bytea;
begin
  if not private.migration_caller_allowed() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  if pg_catalog.jsonb_typeof(payload) <> 'object'
    or pg_catalog.btrim(coalesce(payload->>'batch_name', '')) = ''
    or pg_catalog.btrim(coalesce(payload->>'environment', '')) = ''
    or pg_catalog.jsonb_typeof(payload->'sources') <> 'array' then
    raise exception using errcode = '22023', message = 'INVALID_IMPORT_DESCRIPTOR';
  end if;

  source_count := pg_catalog.jsonb_array_length(payload->'sources');
  select
    count(*) filter (where item->>'kind' = 'asset'),
    count(*) filter (where item->>'kind' = 'license')
  into asset_count, license_count
  from pg_catalog.jsonb_array_elements(payload->'sources') as descriptor(item);

  if source_count not between 1 and 2
    or asset_count > 1
    or license_count > 1
    or asset_count + license_count <> source_count then
    raise exception using errcode = '22023', message = 'INVALID_IMPORT_DESCRIPTOR';
  end if;

  for source in select item from pg_catalog.jsonb_array_elements(payload->'sources') as descriptor(item)
  loop
    if (source->>'kind' = 'asset' and source->>'file_name' <> '02 203Total License(TKC) Update 2026-08-28.xlsx')
      or (source->>'kind' = 'license' and source->>'file_name' <> '03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx')
      or coalesce(source->>'sha256', '') !~ '^[0-9a-fA-F]{64}$'
      or coalesce(source->>'file_size_bytes', '') !~ '^[0-9]+$' then
      raise exception using errcode = '22023', message = 'UNAPPROVED_SOURCE_FILE';
    end if;

    source_checksum := pg_catalog.decode(pg_catalog.lower(source->>'sha256'), 'hex');
    if exists (
      select 1
      from migration.source_files as prior_source
      join migration.import_batches as prior_batch
        on prior_batch.id = prior_source.import_batch_id
      where prior_source.sha256_checksum = source_checksum
        and prior_batch.status = 'committed'::migration.import_batch_status
    ) then
      raise exception using errcode = 'P0001', message = 'SOURCE_ALREADY_PUBLISHED';
    end if;
  end loop;

  insert into migration.import_batches (
    id, batch_name, environment, status, started_at, started_by
  ) values (
    new_batch_id, payload->>'batch_name', payload->>'environment',
    'draft', now(), auth.uid()
  );

  for source in select item from pg_catalog.jsonb_array_elements(payload->'sources') as descriptor(item)
  loop
    insert into migration.source_files (
      import_batch_id, file_name, sha256_checksum, file_size_bytes,
      source_modified_at, extracted_at
    ) values (
      new_batch_id, source->>'file_name',
      pg_catalog.decode(pg_catalog.lower(source->>'sha256'), 'hex'),
      (source->>'file_size_bytes')::bigint,
      nullif(source->>'source_modified_at', '')::timestamptz,
      now()
    );
  end loop;

  return new_batch_id;
end;
$$;

revoke all on function public.begin_import_batch(jsonb) from public, anon;
grant execute on function public.begin_import_batch(jsonb) to authenticated, service_role;

alter function public.publish_import_batch(uuid, integer, boolean)
rename to publish_import_batch_core;

revoke all on function public.publish_import_batch_core(uuid, integer, boolean)
from public, anon, authenticated, service_role;

create or replace function private.publish_asset_relations(import_batch_id uuid)
returns public.import_publish_summary
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.import_publish_summary;
  asset_row record;
  network_row record;
  person_row record;
  software_row record;
  actor_id uuid;
  resolved_location_id uuid;
  resolved_publisher_id uuid;
  resolved_product_id uuid;
  resolved_person_id uuid;
  resolved_interface_id uuid;
  normalized_mac text;
  normalized_ip pg_catalog.inet;
  resolved_assignment_role text;
  location_label text;
  operating_system_label text;
begin
  result.products_created := 0;

  for asset_row in
    select
      asset.id,
      asset.site_id,
      asset.created_by,
      staged.raw_data
    from public.assets as asset
    join migration.asset_staging_rows as staged
      on staged.id = asset.migration_source_row_id
    where asset.migration_batch_id = publish_asset_relations.import_batch_id
    order by staged.sheet_name, staged.source_row_number
  loop
    actor_id := asset_row.created_by;
    location_label := nullif(pg_catalog.btrim(asset_row.raw_data->>'location'), '');
    operating_system_label := nullif(pg_catalog.btrim(asset_row.raw_data->>'operating_system'), '');

    if location_label is not null then
      select location.id into resolved_location_id
      from public.locations as location
      where location.site_id = asset_row.site_id
        and location.name = location_label
        and location.archived_at is null
      order by location.created_at, location.id
      limit 1;

      if resolved_location_id is null then
        insert into public.locations (
          site_id, code, name, description, created_by, updated_by
        ) values (
          asset_row.site_id,
          'MIG_' || pg_catalog.upper(pg_catalog.substr(
            pg_catalog.encode(extensions.digest(location_label, 'sha256'), 'hex'), 1, 20
          )),
          location_label,
          'Created from approved Asset workbook',
          actor_id,
          actor_id
        )
        returning id into resolved_location_id;
      end if;

      update public.assets
      set location_id = resolved_location_id,
          updated_by = actor_id
      where id = asset_row.id;
    end if;

    if operating_system_label is not null
      or (
        pg_catalog.jsonb_typeof(asset_row.raw_data->'installed_software') = 'array'
        and pg_catalog.jsonb_array_length(asset_row.raw_data->'installed_software') > 0
      ) then
      select publisher.id into resolved_publisher_id
      from public.publishers as publisher
      where publisher.code = 'MIGRATION_UNKNOWN'
        and publisher.archived_at is null
      order by publisher.created_at, publisher.id
      limit 1;

      if resolved_publisher_id is null then
        insert into public.publishers (
          code, name_th, name_en, created_by, updated_by
        ) values (
          'MIGRATION_UNKNOWN',
          'ไม่ทราบผู้ผลิตจากข้อมูลย้ายระบบ',
          'Unknown publisher from migration',
          actor_id,
          actor_id
        )
        returning id into resolved_publisher_id;
      end if;
    end if;

    if operating_system_label is not null then
      resolved_product_id := null;
      select product.id into resolved_product_id
      from public.software_products as product
      where product.publisher_id = resolved_publisher_id
        and pg_catalog.lower(product.name) = pg_catalog.lower(operating_system_label)
        and product.version_edition = ''
        and product.archived_at is null
      order by product.created_at, product.id
      limit 1;

      if resolved_product_id is null then
        insert into public.software_products (
          publisher_id, category_id, name, version_edition,
          support_status, remark, created_by, updated_by
        ) values (
          resolved_publisher_id,
          '13000000-0000-4000-8000-000000000001',
          operating_system_label,
          '',
          'unknown',
          'Created from approved Asset workbook operating system',
          actor_id,
          actor_id
        )
        returning id into resolved_product_id;
        result.products_created := result.products_created + 1;
      end if;

      update public.assets
      set operating_system_product_id = resolved_product_id,
          updated_by = actor_id
      where id = asset_row.id;
    end if;

    for network_row in
      with observations as (
        select
          case
            when pg_catalog.lower(coalesce(item.value->>'interface_name', '')) in ('lan', 'wifi')
              then pg_catalog.lower(item.value->>'interface_name')
            else 'other'
          end as interface_type,
          item.value->>'kind' as observation_kind,
          item.value->>'value' as observation_value,
          item.ordinality,
          pg_catalog.row_number() over (
            partition by
              pg_catalog.lower(coalesce(item.value->>'interface_name', 'other')),
              item.value->>'kind'
            order by item.ordinality
          ) as interface_slot
        from pg_catalog.jsonb_array_elements(
          case
            when pg_catalog.jsonb_typeof(asset_row.raw_data->'network_data') = 'array'
              then asset_row.raw_data->'network_data'
            else '[]'::jsonb
          end
        ) with ordinality as item(value, ordinality)
        where item.value->>'kind' in ('mac', 'ip')
      )
      select
        interface_type,
        interface_slot,
        pg_catalog.max(observation_value) filter (where observation_kind = 'mac') as mac_value,
        pg_catalog.max(observation_value) filter (where observation_kind = 'ip') as ip_value,
        pg_catalog.min(ordinality) as first_ordinality
      from observations
      group by interface_type, interface_slot
      order by first_ordinality
    loop
      normalized_mac := pg_catalog.upper(pg_catalog.replace(
        pg_catalog.btrim(coalesce(network_row.mac_value, '')), '-', ':'
      ));
      if normalized_mac !~ '^[0-9A-F]{2}(:[0-9A-F]{2}){5}$' then
        normalized_mac := null;
      end if;
      if normalized_mac is not null and exists (
        select 1 from public.asset_network_interfaces as interface
        where interface.mac_address = normalized_mac
          and interface.asset_id <> asset_row.id
          and interface.archived_at is null
      ) then
        normalized_mac := null;
      end if;

      normalized_ip := null;
      if nullif(pg_catalog.btrim(coalesce(network_row.ip_value, '')), '') is not null
        and pg_catalog.pg_input_is_valid(network_row.ip_value, 'inet') then
        normalized_ip := network_row.ip_value::pg_catalog.inet;
      end if;

      if normalized_mac is null and normalized_ip is null then
        continue;
      end if;

      resolved_interface_id := null;
      select interface.id into resolved_interface_id
      from public.asset_network_interfaces as interface
      where interface.asset_id = asset_row.id
        and interface.archived_at is null
        and (
          (normalized_mac is not null and interface.mac_address = normalized_mac)
          or (normalized_ip is not null and interface.ip_address = normalized_ip)
        )
      order by interface.created_at, interface.id
      limit 1;

      if resolved_interface_id is null then
        insert into public.asset_network_interfaces (
          asset_id, interface_type, interface_name, mac_address, ip_address,
          address_mode, raw_ip_text, is_primary, created_by, updated_by
        ) values (
          asset_row.id,
          network_row.interface_type,
          network_row.interface_type || '-' || network_row.interface_slot,
          normalized_mac,
          normalized_ip,
          case when normalized_ip is null then 'unknown' else 'static' end,
          nullif(pg_catalog.btrim(coalesce(network_row.ip_value, '')), ''),
          not exists (
            select 1 from public.asset_network_interfaces as interface
            where interface.asset_id = asset_row.id
              and interface.interface_type = network_row.interface_type
              and interface.is_primary
              and interface.archived_at is null
          ),
          actor_id,
          actor_id
        );
      else
        update public.asset_network_interfaces
        set interface_type = network_row.interface_type,
            interface_name = network_row.interface_type || '-' || network_row.interface_slot,
            mac_address = coalesce(normalized_mac, mac_address),
            ip_address = coalesce(normalized_ip, ip_address),
            address_mode = case when coalesce(normalized_ip, ip_address) is null then 'unknown' else 'static' end,
            raw_ip_text = nullif(pg_catalog.btrim(coalesce(network_row.ip_value, '')), ''),
            updated_by = actor_id
        where id = resolved_interface_id;
      end if;
    end loop;

    for person_row in
      select
        nullif(pg_catalog.btrim(item.value->>'person_label'), '') as person_label,
        item.value->>'assignment_kind' as assignment_kind,
        pg_catalog.row_number() over (
          partition by item.value->>'assignment_kind'
          order by item.ordinality
        ) as assignment_index
      from pg_catalog.jsonb_array_elements(
        case
          when pg_catalog.jsonb_typeof(asset_row.raw_data->'people_assignments') = 'array'
            then asset_row.raw_data->'people_assignments'
          else '[]'::jsonb
        end
      ) with ordinality as item(value, ordinality)
      where nullif(pg_catalog.btrim(item.value->>'person_label'), '') is not null
      order by item.ordinality
    loop
      resolved_person_id := null;
      select person.id into resolved_person_id
      from public.people as person
      where person.primary_site_id = asset_row.site_id
        and person.display_name = person_row.person_label
        and person.archived_at is null
      order by person.created_at, person.id
      limit 1;

      if resolved_person_id is null then
        insert into public.people (
          display_name, primary_site_id, employment_status,
          remark, created_by, updated_by
        ) values (
          person_row.person_label,
          asset_row.site_id,
          'unknown',
          'Created from approved Asset workbook',
          actor_id,
          actor_id
        )
        returning id into resolved_person_id;
      end if;

      resolved_assignment_role := case
        when person_row.assignment_kind = 'responsible'
          and person_row.assignment_index = 1 then 'responsible_person'
        when person_row.assignment_kind = 'user'
          and person_row.assignment_index = 1 then 'primary_user'
        else 'additional_user'
      end;

      if not exists (
        select 1 from public.asset_person_assignments as assignment
        where assignment.asset_id = asset_row.id
          and assignment.person_id = resolved_person_id
          and assignment.assignment_role = resolved_assignment_role
          and assignment.valid_to is null
          and assignment.archived_at is null
      ) then
        insert into public.asset_person_assignments (
          asset_id, person_id, assignment_role, valid_from,
          remark, created_by, updated_by
        ) values (
          asset_row.id,
          resolved_person_id,
          resolved_assignment_role,
          current_date,
          'Created from approved Asset workbook',
          actor_id,
          actor_id
        );
      end if;
    end loop;

    for software_row in
      select distinct nullif(pg_catalog.btrim(item.value->>'product_label'), '') as product_label
      from pg_catalog.jsonb_array_elements(
        case
          when pg_catalog.jsonb_typeof(asset_row.raw_data->'installed_software') = 'array'
            then asset_row.raw_data->'installed_software'
          else '[]'::jsonb
        end
      ) as item(value)
      where nullif(pg_catalog.btrim(item.value->>'product_label'), '') is not null
      order by product_label
    loop
      resolved_product_id := null;
      select product.id into resolved_product_id
      from public.software_products as product
      where product.publisher_id = resolved_publisher_id
        and pg_catalog.lower(product.name) = pg_catalog.lower(software_row.product_label)
        and product.version_edition = ''
        and product.archived_at is null
      order by product.created_at, product.id
      limit 1;

      if resolved_product_id is null then
        insert into public.software_products (
          publisher_id, category_id, name, version_edition,
          support_status, remark, created_by, updated_by
        ) values (
          resolved_publisher_id,
          '13000000-0000-4000-8000-000000000005',
          software_row.product_label,
          '',
          'unknown',
          'Created from approved Asset workbook installed software',
          actor_id,
          actor_id
        )
        returning id into resolved_product_id;
        result.products_created := result.products_created + 1;
      end if;

      if not exists (
        select 1 from public.asset_software_installations as installation
        where installation.asset_id = asset_row.id
          and installation.software_product_id = resolved_product_id
          and installation.installation_status = 'installed'
          and installation.archived_at is null
      ) then
        insert into public.asset_software_installations (
          asset_id, software_product_id, installation_status,
          source, remark, created_by, updated_by
        ) values (
          asset_row.id,
          resolved_product_id,
          'installed',
          'migration',
          'Created from approved Asset workbook',
          actor_id,
          actor_id
        );
      end if;
    end loop;
  end loop;

  insert into migration.reconciliation_totals (
    reconciliation_run_id, metric, site_id, source_total, target_total, status
  )
  with imported_assets as (
    select asset.id, asset.site_id, staged.raw_data
    from public.assets as asset
    join migration.asset_staging_rows as staged on staged.id = asset.migration_source_row_id
    where asset.migration_batch_id = publish_asset_relations.import_batch_id
  ),
  people_ranked as (
    select imported.id as asset_id, imported.site_id,
      pg_catalog.btrim(item.value->>'person_label') as person_label,
      item.value->>'assignment_kind' as assignment_kind,
      pg_catalog.row_number() over (
        partition by imported.id, item.value->>'assignment_kind' order by item.ordinality
      ) as assignment_index
    from imported_assets as imported
    cross join lateral pg_catalog.jsonb_array_elements(
      case when pg_catalog.jsonb_typeof(imported.raw_data->'people_assignments') = 'array'
        then imported.raw_data->'people_assignments' else '[]'::jsonb end
    ) with ordinality as item(value, ordinality)
    where nullif(pg_catalog.btrim(item.value->>'person_label'), '') is not null
  ),
  network_observations as (
    select imported.id as asset_id, imported.site_id,
      case when pg_catalog.lower(coalesce(item.value->>'interface_name', '')) in ('lan','wifi')
        then pg_catalog.lower(item.value->>'interface_name') else 'other' end as interface_type,
      item.value->>'kind' as observation_kind,
      item.value->>'value' as observation_value,
      pg_catalog.row_number() over (
        partition by imported.id,
          pg_catalog.lower(coalesce(item.value->>'interface_name', 'other')),
          item.value->>'kind' order by item.ordinality
      ) as interface_slot
    from imported_assets as imported
    cross join lateral pg_catalog.jsonb_array_elements(
      case when pg_catalog.jsonb_typeof(imported.raw_data->'network_data') = 'array'
        then imported.raw_data->'network_data' else '[]'::jsonb end
    ) with ordinality as item(value, ordinality)
    where item.value->>'kind' in ('mac','ip')
  ),
  network_pairs as (
    select asset_id, site_id, interface_type, interface_slot,
      case
        when pg_catalog.upper(pg_catalog.replace(pg_catalog.btrim(coalesce(
          pg_catalog.max(observation_value) filter (where observation_kind='mac'), ''
        )), '-', ':')) ~ '^[0-9A-F]{2}(:[0-9A-F]{2}){5}$'
        then pg_catalog.upper(pg_catalog.replace(pg_catalog.btrim(
          pg_catalog.max(observation_value) filter (where observation_kind='mac')
        ), '-', ':'))
      end as normalized_mac,
      case
        when pg_catalog.pg_input_is_valid(pg_catalog.btrim(coalesce(
          pg_catalog.max(observation_value) filter (where observation_kind='ip'), ''
        )), 'inet')
        then pg_catalog.btrim(pg_catalog.max(observation_value) filter (where observation_kind='ip'))
      end as normalized_ip
    from network_observations
    group by asset_id, site_id, interface_type, interface_slot
  ),
  network_ranked as (
    select pair.*,
      case when pair.normalized_mac is null then null else
        pg_catalog.row_number() over (partition by pair.normalized_mac order by pair.asset_id, pair.interface_type, pair.interface_slot)
      end as mac_rank
    from network_pairs as pair
  ),
  source_totals as (
    select site_id, 'location_links'::text as metric, count(*)::numeric as total
    from imported_assets where nullif(pg_catalog.btrim(raw_data->>'location'), '') is not null group by site_id
    union all
    select site_id, 'operating_system_links', count(*)::numeric
    from imported_assets where nullif(pg_catalog.btrim(raw_data->>'operating_system'), '') is not null group by site_id
    union all
    select site_id, 'person_assignments', count(*)::numeric from (
      select distinct asset_id, site_id, person_label,
        case when assignment_kind='responsible' and assignment_index=1 then 'responsible_person'
          when assignment_kind='user' and assignment_index=1 then 'primary_user' else 'additional_user' end as role
      from people_ranked
    ) as assignments group by site_id
    union all
    select site_id, 'software_installations', count(*)::numeric from (
      select distinct imported.id as asset_id, imported.site_id,
        pg_catalog.lower(pg_catalog.btrim(item.value->>'product_label')) as product_label
      from imported_assets as imported
      cross join lateral pg_catalog.jsonb_array_elements(
        case when pg_catalog.jsonb_typeof(imported.raw_data->'installed_software')='array'
          then imported.raw_data->'installed_software' else '[]'::jsonb end
      ) as item(value)
      where nullif(pg_catalog.btrim(item.value->>'product_label'), '') is not null
    ) as installations group by site_id
    union all
    select site_id, 'network_interfaces', count(*)::numeric
    from network_ranked as network
    where network.normalized_ip is not null or (
      network.normalized_mac is not null and network.mac_rank=1 and not exists (
        select 1 from public.asset_network_interfaces as interface
        join public.assets as existing_asset on existing_asset.id=interface.asset_id
        where interface.mac_address=network.normalized_mac and interface.archived_at is null
          and existing_asset.migration_batch_id is distinct from publish_asset_relations.import_batch_id
      )
    ) group by site_id
  ),
  target_totals as (
    select asset.site_id, 'network_interfaces'::text as metric, count(*)::numeric as total
    from public.asset_network_interfaces as relation join public.assets as asset on asset.id=relation.asset_id
    where asset.migration_batch_id=publish_asset_relations.import_batch_id and relation.archived_at is null group by asset.site_id
    union all
    select asset.site_id, 'person_assignments', count(*)::numeric
    from public.asset_person_assignments as relation join public.assets as asset on asset.id=relation.asset_id
    where asset.migration_batch_id=publish_asset_relations.import_batch_id and relation.archived_at is null group by asset.site_id
    union all
    select asset.site_id, 'software_installations', count(*)::numeric
    from public.asset_software_installations as relation join public.assets as asset on asset.id=relation.asset_id
    where asset.migration_batch_id=publish_asset_relations.import_batch_id and relation.archived_at is null group by asset.site_id
    union all
    select site_id, 'operating_system_links', count(*)::numeric from public.assets
    where migration_batch_id=publish_asset_relations.import_batch_id and operating_system_product_id is not null group by site_id
    union all
    select site_id, 'location_links', count(*)::numeric from public.assets
    where migration_batch_id=publish_asset_relations.import_batch_id and location_id is not null group by site_id
  ),
  metric_names(metric) as (values
    ('network_interfaces'::text), ('person_assignments'), ('software_installations'),
    ('operating_system_links'), ('location_links')
  )
  select
    run.id,
    metric_names.metric,
    site.id,
    coalesce(source.total, 0),
    coalesce(target.total, 0),
    case when coalesce(source.total, 0)=coalesce(target.total, 0) then 'matched' else 'mismatch' end
  from migration.reconciliation_runs as run
  cross join public.sites as site
  cross join metric_names
  left join source_totals as source on source.site_id=site.id and source.metric=metric_names.metric
  left join target_totals as target on target.site_id=site.id and target.metric=metric_names.metric
  where run.import_batch_id = publish_asset_relations.import_batch_id
  on conflict (reconciliation_run_id, metric, site_id) do update
  set source_total = excluded.source_total,
      target_total = excluded.target_total,
      status = excluded.status;

  return result;
end;
$$;

revoke all on function private.publish_asset_relations(uuid)
from public, anon, authenticated;

create or replace function private.complete_asset_publish_before_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  relation_result public.import_publish_summary;
begin
  if new.action <> 'publish' or new.entity_type <> 'import_batch' then
    return new;
  end if;

  select * into relation_result
  from private.publish_asset_relations(new.entity_id);

  new.new_values := coalesce(new.new_values, '{}'::jsonb) || pg_catalog.jsonb_build_object(
    'products_created', coalesce((new.new_values->>'products_created')::integer, 0)
      + coalesce(relation_result.products_created, 0),
    'network_interfaces_created', (
      select count(*) from public.asset_network_interfaces as interface
      join public.assets as asset on asset.id = interface.asset_id
      where asset.migration_batch_id = new.entity_id and interface.archived_at is null
    ),
    'person_assignments_created', (
      select count(*) from public.asset_person_assignments as assignment
      join public.assets as asset on asset.id = assignment.asset_id
      where asset.migration_batch_id = new.entity_id and assignment.archived_at is null
    ),
    'software_installations_created', (
      select count(*) from public.asset_software_installations as installation
      join public.assets as asset on asset.id = installation.asset_id
      where asset.migration_batch_id = new.entity_id and installation.archived_at is null
    )
  );
  return new;
end;
$$;

revoke all on function private.complete_asset_publish_before_audit()
from public, anon, authenticated;

create trigger audit_asset_publish_relations_trg
before insert on audit.audit_events
for each row execute function private.complete_asset_publish_before_audit();

create or replace function public.publish_import_batch(
  import_batch_id uuid,
  expected_version integer,
  acknowledge_warnings boolean
)
returns public.import_publish_summary
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.import_publish_summary;
begin
  select * into result
  from public.publish_import_batch_core(import_batch_id, expected_version, acknowledge_warnings);

  select coalesce((event.new_values->>'products_created')::integer, result.products_created)
  into result.products_created
  from audit.audit_events as event
  where event.id = result.audit_event_id;

  return result;
end;
$$;

revoke all on function public.publish_import_batch(uuid, integer, boolean)
from public, anon;
grant execute on function public.publish_import_batch(uuid, integer, boolean)
to authenticated, service_role;

create or replace function private.add_asset_network_validation_warning()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  staged_raw_data jsonb;
begin
  if new.staging_entity_type <> 'asset' then
    return new;
  end if;

  select staged.raw_data into staged_raw_data
  from migration.asset_staging_rows as staged
  where staged.id = new.staging_row_id;

  if exists (
    select 1
    from pg_catalog.jsonb_array_elements(
      case
        when pg_catalog.jsonb_typeof(staged_raw_data->'network_data') = 'array'
          then staged_raw_data->'network_data'
        else '[]'::jsonb
      end
    ) as observation(value)
    where (
      observation.value->>'kind' = 'mac'
      and pg_catalog.upper(pg_catalog.replace(
        pg_catalog.btrim(coalesce(observation.value->>'value', '')), '-', ':'
      )) !~ '^[0-9A-F]{2}(:[0-9A-F]{2}){5}$'
    ) or (
      observation.value->>'kind' = 'ip'
      and not pg_catalog.pg_input_is_valid(
        pg_catalog.btrim(coalesce(observation.value->>'value', '')),
        'inet'
      )
    )
  ) then
    new.warnings := coalesce(new.warnings, '[]'::jsonb)
      || '["INVALID_NETWORK_VALUE"]'::jsonb;
  end if;

  return new;
end;
$$;

revoke all on function private.add_asset_network_validation_warning()
from public, anon, authenticated;

create trigger migration_row_results_asset_network_warning_trg
before insert or update of warnings, staging_entity_type, staging_row_id
on migration.row_results
for each row
execute function private.add_asset_network_validation_warning();
