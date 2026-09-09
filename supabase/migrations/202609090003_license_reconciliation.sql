create or replace function private.refresh_license_reconciliation(import_batch_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  with source_totals as (
    select site.id as site_id,
      count(staged.id)::numeric as license_total,
      coalesce(sum(staged.normalized_owned_quantity),0)::numeric as owned_total
    from public.sites as site
    left join migration.license_staging_rows as staged on (
      (site.code='FACTORY' and staged.sheet_name ilike '%factory%')
      or (site.code='BANGKOK_OFFICE' and staged.sheet_name ilike '%office%')
    )
    and exists (
      select 1
      from migration.source_files as source
      where source.id=staged.source_file_id
        and source.import_batch_id=refresh_license_reconciliation.import_batch_id
    )
    and exists (
      select 1
      from migration.row_results as result
      where result.import_batch_id=refresh_license_reconciliation.import_batch_id
        and result.staging_entity_type='license'
        and result.staging_row_id=staged.id
        and result.result_status='imported'
    )
    group by site.id
  ),
  target_totals as (
    select site.id as site_id,
      count(entitlement.id)::numeric as license_total,
      coalesce(sum(entitlement.owned_quantity),0)::numeric as owned_total
    from public.sites as site
    left join migration.license_staging_rows as staged on (
      (site.code='FACTORY' and staged.sheet_name ilike '%factory%')
      or (site.code='BANGKOK_OFFICE' and staged.sheet_name ilike '%office%')
    )
    left join public.license_entitlements as entitlement
      on entitlement.migration_source_row_id=staged.id
      and entitlement.migration_batch_id=refresh_license_reconciliation.import_batch_id
    group by site.id
  ),
  totals as (
    select source.site_id, metric.metric,
      case metric.metric when 'licenses' then source.license_total else source.owned_total end as source_total,
      case metric.metric when 'licenses' then target.license_total else target.owned_total end as target_total
    from source_totals as source
    join target_totals as target on target.site_id=source.site_id
    cross join (values ('licenses'::text),('owned_quantity'::text)) as metric(metric)
  )
  update migration.reconciliation_totals as reconciliation
  set source_total=totals.source_total,
      target_total=totals.target_total,
      status=case when totals.source_total=totals.target_total then 'matched' else 'mismatch' end
  from migration.reconciliation_runs as run, totals
  where run.id=reconciliation.reconciliation_run_id
    and run.import_batch_id=refresh_license_reconciliation.import_batch_id
    and reconciliation.metric=totals.metric
    and reconciliation.site_id=totals.site_id;

  update migration.reconciliation_runs as run
  set status=case when exists (
    select 1 from migration.reconciliation_totals as total
    where total.reconciliation_run_id=run.id and total.status='mismatch'
  ) then 'mismatch' else 'approved' end
  where run.import_batch_id=refresh_license_reconciliation.import_batch_id;
end;
$$;

revoke all on function private.refresh_license_reconciliation(uuid)
from public, anon, authenticated;

create or replace function private.refresh_license_reconciliation_before_audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.action='publish' and new.entity_type='import_batch' then
    perform private.refresh_license_reconciliation(new.entity_id);
  end if;
  return new;
end;
$$;

revoke all on function private.refresh_license_reconciliation_before_audit()
from public, anon, authenticated;

create trigger zzz_audit_license_reconciliation_trg
before insert on audit.audit_events
for each row execute function private.refresh_license_reconciliation_before_audit();

do $$
declare
  published_batch record;
begin
  for published_batch in
    select distinct batch.id
    from migration.import_batches as batch
    join public.license_entitlements as entitlement on entitlement.migration_batch_id=batch.id
    where batch.status='committed'
  loop
    perform private.refresh_license_reconciliation(published_batch.id);
  end loop;
end;
$$;
