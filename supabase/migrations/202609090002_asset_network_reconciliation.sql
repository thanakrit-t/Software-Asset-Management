create or replace function private.refresh_asset_network_reconciliation(import_batch_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  with imported_assets as (
    select asset.id, asset.site_id, staged.raw_data
    from public.assets as asset
    join migration.asset_staging_rows as staged on staged.id = asset.migration_source_row_id
    where asset.migration_batch_id = refresh_asset_network_reconciliation.import_batch_id
  ),
  observations as (
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
      case when pg_catalog.jsonb_typeof(imported.raw_data->'network_data')='array'
        then imported.raw_data->'network_data' else '[]'::jsonb end
    ) with ordinality as item(value, ordinality)
    where item.value->>'kind' in ('mac','ip')
  ),
  pairs as (
    select asset_id, site_id, interface_type, interface_slot,
      case when pg_catalog.upper(pg_catalog.replace(pg_catalog.btrim(coalesce(
        pg_catalog.max(observation_value) filter (where observation_kind='mac'), ''
      )), '-', ':')) ~ '^[0-9A-F]{2}(:[0-9A-F]{2}){5}$'
      then pg_catalog.upper(pg_catalog.replace(pg_catalog.btrim(
        pg_catalog.max(observation_value) filter (where observation_kind='mac')
      ), '-', ':')) end as normalized_mac,
      case when pg_catalog.pg_input_is_valid(pg_catalog.btrim(coalesce(
        pg_catalog.max(observation_value) filter (where observation_kind='ip'), ''
      )), 'inet')
      then pg_catalog.btrim(pg_catalog.max(observation_value) filter (where observation_kind='ip')) end as normalized_ip
    from observations
    group by asset_id, site_id, interface_type, interface_slot
  ),
  ranked as (
    select pair.*,
      case when normalized_mac is null then null else pg_catalog.row_number() over (
        partition by asset_id, normalized_mac order by interface_type, interface_slot
      ) end as asset_mac_rank,
      case when normalized_mac is null then null else pg_catalog.row_number() over (
        partition by normalized_mac order by asset_id, interface_type, interface_slot
      ) end as batch_mac_rank,
      case when normalized_ip is null then null else pg_catalog.row_number() over (
        partition by asset_id, normalized_ip order by interface_type, interface_slot
      ) end as asset_ip_rank
    from pairs as pair
  ),
  source_totals as (
    select site_id, count(*)::numeric as total
    from ranked as network
    where (
      network.normalized_ip is not null
      and network.asset_ip_rank=1
      and (network.normalized_mac is null or network.asset_mac_rank=1)
    ) or (
      network.normalized_ip is null
      and network.normalized_mac is not null
      and network.asset_mac_rank=1
      and network.batch_mac_rank=1
      and not exists (
        select 1 from public.asset_network_interfaces as interface
        join public.assets as existing_asset on existing_asset.id=interface.asset_id
        where interface.mac_address=network.normalized_mac and interface.archived_at is null
          and existing_asset.migration_batch_id is distinct from refresh_asset_network_reconciliation.import_batch_id
      )
    )
    group by site_id
  ),
  target_totals as (
    select asset.site_id, count(*)::numeric as total
    from public.asset_network_interfaces as interface
    join public.assets as asset on asset.id=interface.asset_id
    where asset.migration_batch_id=refresh_asset_network_reconciliation.import_batch_id
      and interface.archived_at is null
    group by asset.site_id
  ),
  totals as (
    select site.id as site_id, coalesce(source.total,0) as source_total,
      coalesce(target.total,0) as target_total
    from public.sites as site
    left join source_totals as source on source.site_id=site.id
    left join target_totals as target on target.site_id=site.id
  )
  update migration.reconciliation_totals as reconciliation
  set source_total=totals.source_total,
      target_total=totals.target_total,
      status=case when totals.source_total=totals.target_total then 'matched' else 'mismatch' end
  from migration.reconciliation_runs as run, totals
  where run.id=reconciliation.reconciliation_run_id
    and run.import_batch_id=refresh_asset_network_reconciliation.import_batch_id
    and reconciliation.metric='network_interfaces'
    and reconciliation.site_id=totals.site_id;

  update migration.reconciliation_runs as run
  set status=case when exists (
    select 1 from migration.reconciliation_totals as total
    where total.reconciliation_run_id=run.id and total.status='mismatch'
  ) then 'mismatch' else 'approved' end
  where run.import_batch_id=refresh_asset_network_reconciliation.import_batch_id;
end;
$$;

revoke all on function private.refresh_asset_network_reconciliation(uuid)
from public, anon, authenticated;

create or replace function private.refresh_asset_network_before_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.action='publish' and new.entity_type='import_batch' then
    perform private.refresh_asset_network_reconciliation(new.entity_id);
  end if;
  return new;
end;
$$;

revoke all on function private.refresh_asset_network_before_audit()
from public, anon, authenticated;

create trigger zz_audit_asset_network_reconciliation_trg
before insert on audit.audit_events
for each row execute function private.refresh_asset_network_before_audit();

do $$
declare
  published_batch record;
begin
  for published_batch in
    select distinct batch.id
    from migration.import_batches as batch
    join public.assets as asset on asset.migration_batch_id=batch.id
    where batch.status='committed'
  loop
    perform private.refresh_asset_network_reconciliation(published_batch.id);
  end loop;
end;
$$;
