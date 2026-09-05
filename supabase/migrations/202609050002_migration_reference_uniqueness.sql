create or replace function private.migration_actor_id()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := auth.uid();
begin
  if actor_id is null then
    select profile.id
    into actor_id
    from public.profiles as profile
    where profile.app_role = 'admin'
      and profile.account_status = 'active'
    order by profile.created_at, profile.id
    limit 1;
  end if;
  if actor_id is null then
    raise exception using errcode = 'P0001', message = 'MIGRATION_ACTOR_NOT_FOUND';
  end if;
  return actor_id;
end;
$$;

revoke all on function private.migration_actor_id() from public,anon,authenticated;

create or replace function public.acknowledge_import_warnings(import_batch_id uuid, expected_version integer)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare current_version integer;
begin
  if not private.migration_caller_allowed() then raise exception using errcode='42501',message='ACCESS_DENIED'; end if;
  select version into current_version from migration.import_batches where id=import_batch_id for update;
  if not found then raise exception using errcode='P0002',message='IMPORT_BATCH_NOT_FOUND'; end if;
  if current_version<>expected_version then raise exception using errcode='40001',message='VERSION_CONFLICT'; end if;
  update migration.import_batches set status='approved',approved_at=now(),approved_by=private.migration_actor_id(),approval_note='Warnings acknowledged',version=version+1 where id=acknowledge_import_warnings.import_batch_id returning version into current_version;
  return current_version;
end;
$$;

revoke all on function public.acknowledge_import_warnings(uuid,integer) from public,anon;
grant execute on function public.acknowledge_import_warnings(uuid,integer) to authenticated,service_role;

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
  batch migration.import_batches%rowtype;
  actor_id uuid := private.migration_actor_id();
  asset_row record;
  license_row record;
  resolved_site_id uuid;
  resolved_publisher_id uuid;
  resolved_vendor_id uuid;
  resolved_product_id uuid;
  new_asset_id uuid;
  new_license_id uuid;
  created_assets integer := 0;
  created_products integer := 0;
  created_licenses integer := 0;
  created_allocations integer := 0;
  duplicate_skips integer := 0;
  warning_skips integer := 0;
  event_id uuid := extensions.gen_random_uuid();
  result public.import_publish_summary;
begin
  if not private.migration_caller_allowed() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('sam_import_publish', 0)
  );

  select * into batch
  from migration.import_batches as selected_batch
  where selected_batch.id = import_batch_id
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'IMPORT_BATCH_NOT_FOUND';
  end if;
  if batch.status = 'committed' then
    raise exception using errcode = 'P0001', message = 'IMPORT_ALREADY_PUBLISHED';
  end if;
  if batch.version <> expected_version then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;
  if batch.status not in ('validated', 'approved') then
    raise exception using errcode = 'P0001', message = 'IMPORT_NOT_VALIDATED';
  end if;
  if exists (
    select 1 from migration.row_results as validation
    where validation.import_batch_id = batch.id
      and validation.result_status = 'error'
  ) then
    raise exception using errcode = 'P0001', message = 'IMPORT_HAS_ERRORS';
  end if;
  if exists (
    select 1 from migration.row_results as validation
    where validation.import_batch_id = batch.id
      and pg_catalog.jsonb_array_length(validation.warnings) > 0
  ) and (not coalesce(acknowledge_warnings, false) or batch.approved_at is null) then
    raise exception using errcode = 'P0001', message = 'WARNINGS_NOT_ACKNOWLEDGED';
  end if;
  if exists (
    select 1
    from migration.source_files as source
    join migration.source_files as prior_source
      on prior_source.sha256_checksum = source.sha256_checksum
     and prior_source.import_batch_id <> source.import_batch_id
    join migration.import_batches as prior_batch
      on prior_batch.id = prior_source.import_batch_id
     and prior_batch.status = 'committed'
    where source.import_batch_id = batch.id
  ) then
    raise exception using errcode = 'P0001', message = 'SOURCE_ALREADY_PUBLISHED';
  end if;

  select count(*)::integer into duplicate_skips
  from migration.row_results
  where migration.row_results.import_batch_id = batch.id
    and decision_reason = 'DUPLICATE_EXACT';

  for asset_row in
    select staged.*, validation.id as result_id
    from migration.asset_staging_rows as staged
    join migration.source_files as source on source.id = staged.source_file_id
    join migration.row_results as validation
      on validation.import_batch_id = batch.id
     and validation.staging_entity_type = 'asset'
     and validation.staging_row_id = staged.id
    where source.import_batch_id = batch.id
      and validation.result_status = 'imported'
    order by source.file_name, staged.sheet_name, staged.source_row_number
  loop
    select site.id into resolved_site_id
    from public.sites as site
    where site.code = asset_row.normalized_site_code
      and site.is_active and site.archived_at is null;
    if resolved_site_id is null then
      raise exception using errcode = 'P0001', message = 'UNRESOLVED_REQUIRED_MAPPING';
    end if;

    insert into public.assets (
      asset_code, migration_reference, computer_name,
      asset_type_id, asset_status_id, site_id,
      manufacturer, model, purchase_date, remark,
      migration_batch_id, migration_source_row_id,
      created_by, updated_by
    ) values (
      asset_row.normalized_asset_code,
      pg_catalog.format('%s:%s', asset_row.source_file_id, asset_row.id),
      asset_row.normalized_computer_name,
      case asset_row.raw_data->>'asset_type'
        when 'pc' then '10000000-0000-4000-8000-000000000001'::uuid
        when 'notebook' then '10000000-0000-4000-8000-000000000002'::uuid
        else '10000000-0000-4000-8000-000000000004'::uuid end,
      '11000000-0000-4000-8000-000000000001',
      resolved_site_id,
      nullif(asset_row.raw_data->>'manufacturer',''),
      nullif(asset_row.raw_data->>'model',''),
      nullif(asset_row.raw_data->>'purchase_date','')::date,
      nullif(asset_row.raw_data->>'remark',''),
      batch.id, asset_row.id, actor_id, actor_id
    ) returning id into new_asset_id;
    created_assets := created_assets + 1;

    if asset_row.normalized_mac_address is not null
      or asset_row.normalized_ip_address is not null then
      insert into public.asset_network_interfaces (
        asset_id, interface_type, mac_address, ip_address,
        address_mode, raw_ip_text, is_primary, created_by, updated_by
      ) values (
        new_asset_id, 'lan', asset_row.normalized_mac_address,
        asset_row.normalized_ip_address,
        case when asset_row.normalized_ip_address is null then 'unknown' else 'static' end,
        asset_row.raw_data->>'ip_address', true, actor_id, actor_id
      );
    end if;

    update migration.row_results set
      target_entity_type = 'asset', target_entity_id = new_asset_id,
      decided_by = actor_id, decided_at = now()
    where id = asset_row.result_id;
  end loop;

  for license_row in
    select staged.*, validation.id as result_id,
      secrets.license_key_vault_secret_id,
      secrets.serial_vault_secret_id
    from migration.license_staging_rows as staged
    join migration.source_files as source on source.id = staged.source_file_id
    join migration.row_results as validation
      on validation.import_batch_id = batch.id
     and validation.staging_entity_type = 'license'
     and validation.staging_row_id = staged.id
    left join private.migration_staged_license_secrets as secrets
      on secrets.license_staging_row_id = staged.id
    where source.import_batch_id = batch.id
      and validation.result_status = 'imported'
    order by source.file_name, staged.sheet_name, staged.source_row_number
  loop
    select site.id into resolved_site_id
    from public.sites as site
    where site.code = case when license_row.sheet_name ilike '%factory%'
      then 'FACTORY' else 'BANGKOK_OFFICE' end
      and site.is_active and site.archived_at is null;
    if resolved_site_id is null then
      raise exception using errcode = 'P0001', message = 'UNRESOLVED_REQUIRED_MAPPING';
    end if;

    select publisher.id into resolved_publisher_id
    from public.publishers as publisher
    where coalesce(publisher.name_en, publisher.name_th) = license_row.normalized_publisher
      and publisher.archived_at is null
    order by publisher.created_at limit 1;
    if resolved_publisher_id is null then
      insert into public.publishers (code,name_th,name_en,created_by,updated_by)
      values (
        'MIG_' || pg_catalog.substr(pg_catalog.encode(extensions.digest(license_row.normalized_publisher,'sha256'),'hex'),1,20),
        license_row.normalized_publisher, license_row.normalized_publisher,
        actor_id, actor_id
      ) returning id into resolved_publisher_id;
    end if;

    resolved_vendor_id := null;
    if license_row.normalized_vendor is not null then
      select vendor.id into resolved_vendor_id from public.vendors as vendor
      where coalesce(vendor.name_en,vendor.name_th)=license_row.normalized_vendor
        and vendor.archived_at is null order by vendor.created_at limit 1;
      if resolved_vendor_id is null then
        insert into public.vendors(code,name_th,name_en,created_by,updated_by)
        values('MIG_'||pg_catalog.substr(pg_catalog.encode(extensions.digest(license_row.normalized_vendor,'sha256'),'hex'),1,20),license_row.normalized_vendor,license_row.normalized_vendor,actor_id,actor_id)
        returning id into resolved_vendor_id;
      end if;
    end if;

    select product.id into resolved_product_id
    from public.software_products as product
    where product.publisher_id=resolved_publisher_id
      and product.name=license_row.normalized_product_name
      and product.version_edition=coalesce(license_row.normalized_version,'')
      and product.archived_at is null;
    if resolved_product_id is null then
      insert into public.software_products(
        publisher_id,category_id,name,version_edition,support_status,
        remark,created_by,updated_by
      ) values (
        resolved_publisher_id,
        '13000000-0000-4000-8000-000000000002',
        license_row.normalized_product_name,
        coalesce(license_row.normalized_version,''), 'unknown',
        'Created by approved Excel migration', actor_id, actor_id
      ) returning id into resolved_product_id;
      created_products := created_products + 1;
    end if;

    insert into public.license_entitlements (
      license_reference,software_product_id,vendor_id,license_metric_id,
      owned_quantity,record_status,scope_mode,purchase_date,start_date,end_date,
      owner_name,legacy_install_date,license_key_masked,serial_number_masked,remark,
      migration_batch_id,migration_source_row_id,created_by,updated_by
    ) values (
      'MIG-' || license_row.id,
      resolved_product_id,resolved_vendor_id,
      '14000000-0000-4000-8000-000000000001',
      license_row.normalized_owned_quantity,
      case when license_row.normalized_record_status in ('draft','active','deactivated') then license_row.normalized_record_status::public.license_record_status else 'active' end,
      'selected_sites',license_row.normalized_purchase_date,
      license_row.normalized_start_date,license_row.normalized_end_date,
      nullif(license_row.raw_data->>'assigned_name',''),
      nullif(license_row.raw_data->>'install_date','')::date,
      license_row.license_key_masked_hint,license_row.serial_masked_hint,
      nullif(license_row.raw_data->>'remark',''),
      batch.id,license_row.id,actor_id,actor_id
    ) returning id into new_license_id;
    created_licenses := created_licenses + 1;
    insert into public.license_site_scopes(license_entitlement_id,site_id)
    values(new_license_id,resolved_site_id);

    if coalesce(nullif(license_row.raw_data->>'used_quantity','')::integer,0) > 0 then
      insert into public.license_allocations(
        license_entitlement_id,target_type,site_id,quantity,
        allocation_status,allocated_at,installed_at,remark,created_by,updated_by
      ) values (
        new_license_id,'site',resolved_site_id,
        (license_row.raw_data->>'used_quantity')::integer,
        'active',
        coalesce(license_row.normalized_purchase_date,license_row.normalized_start_date,current_date),
        nullif(license_row.raw_data->>'install_date','')::date,
        'Created from Excel Used License quantity',
        actor_id,actor_id
      );
      created_allocations := created_allocations + 1;
    end if;

    if license_row.license_key_fingerprint is not null
      or license_row.serial_fingerprint is not null then
      insert into private.license_secrets(
        license_entitlement_id,license_key_vault_secret_id,
        license_key_fingerprint,serial_vault_secret_id,serial_fingerprint
      ) values (
        new_license_id,license_row.license_key_vault_secret_id,
        license_row.license_key_fingerprint,license_row.serial_vault_secret_id,
        license_row.serial_fingerprint
      );
    end if;

    update migration.row_results set
      target_entity_type='license_entitlement',target_entity_id=new_license_id,
      decided_by=actor_id,decided_at=now()
    where id=license_row.result_id;
  end loop;

  update migration.reconciliation_totals as total set
    target_total = case total.metric
      when 'assets' then (
        select count(*) from public.assets as asset
        where asset.migration_batch_id=batch.id and asset.site_id=total.site_id
      )
      when 'licenses' then (
        select count(*) from public.license_entitlements as entitlement
        join migration.license_staging_rows as staged
          on staged.id=entitlement.migration_source_row_id
        where entitlement.migration_batch_id=batch.id
          and ((total.site_id='01000000-0000-4000-8000-000000000001' and staged.sheet_name ilike '%factory%')
            or (total.site_id='01000000-0000-4000-8000-000000000002' and staged.sheet_name ilike '%office%'))
      )
      when 'owned_quantity' then (
        select coalesce(sum(entitlement.owned_quantity),0)
        from public.license_entitlements as entitlement
        join migration.license_staging_rows as staged
          on staged.id=entitlement.migration_source_row_id
        where entitlement.migration_batch_id=batch.id
          and ((total.site_id='01000000-0000-4000-8000-000000000001' and staged.sheet_name ilike '%factory%')
            or (total.site_id='01000000-0000-4000-8000-000000000002' and staged.sheet_name ilike '%office%'))
      ) else total.target_total end,
    status = case when total.source_total = case total.metric
      when 'assets' then (select count(*) from public.assets a where a.migration_batch_id=batch.id and a.site_id=total.site_id)
      when 'licenses' then (select count(*) from public.license_entitlements e join migration.license_staging_rows s on s.id=e.migration_source_row_id where e.migration_batch_id=batch.id and ((total.site_id='01000000-0000-4000-8000-000000000001' and s.sheet_name ilike '%factory%') or (total.site_id='01000000-0000-4000-8000-000000000002' and s.sheet_name ilike '%office%')))
      when 'owned_quantity' then (select coalesce(sum(e.owned_quantity),0) from public.license_entitlements e join migration.license_staging_rows s on s.id=e.migration_source_row_id where e.migration_batch_id=batch.id and ((total.site_id='01000000-0000-4000-8000-000000000001' and s.sheet_name ilike '%factory%') or (total.site_id='01000000-0000-4000-8000-000000000002' and s.sheet_name ilike '%office%')))
      else total.target_total end then 'matched' else 'mismatch' end
  where total.reconciliation_run_id in (
    select run.id from migration.reconciliation_runs as run
    where run.import_batch_id=batch.id
  );

  update migration.reconciliation_runs set
    completed_at=now(),approved_at=now(),approved_by=actor_id,
    status=case when exists(select 1 from migration.reconciliation_totals total where total.reconciliation_run_id=migration.reconciliation_runs.id and total.status='mismatch') then 'mismatch' else 'approved' end
  where migration.reconciliation_runs.import_batch_id=batch.id;

  insert into audit.audit_events(
    id,actor_profile_id,actor_type,action,entity_type,entity_id,
    description,new_values,metadata
  ) values (
    event_id,actor_id,'migration','publish','import_batch',batch.id,
    'Approved Excel migration batch published',
    pg_catalog.jsonb_build_object(
      'assets_created',created_assets,'products_created',created_products,
      'licenses_created',created_licenses,'allocations_created',created_allocations,
      'duplicate_rows_skipped',duplicate_skips,'warning_rows_skipped',warning_skips
    ),
    pg_catalog.jsonb_build_object('source_fingerprints',(
      select pg_catalog.jsonb_agg(pg_catalog.encode(source.sha256_checksum,'hex') order by source.file_name)
      from migration.source_files as source where source.import_batch_id=batch.id
    ))
  );

  update migration.import_batches set
    status='committed',completed_at=now(),approved_at=coalesce(approved_at,now()),
    approved_by=coalesce(approved_by,actor_id),version=version+1
  where id=batch.id;

  result.import_batch_id:=batch.id;
  result.assets_created:=created_assets;
  result.products_created:=created_products;
  result.licenses_created:=created_licenses;
  result.allocations_created:=created_allocations;
  result.duplicate_rows_skipped:=duplicate_skips;
  result.warning_rows_skipped:=warning_skips;
  result.audit_event_id:=event_id;
  return result;
end;
$$;

revoke all on function public.publish_import_batch(uuid,integer,boolean) from public,anon;
grant execute on function public.publish_import_batch(uuid,integer,boolean) to authenticated,service_role;
