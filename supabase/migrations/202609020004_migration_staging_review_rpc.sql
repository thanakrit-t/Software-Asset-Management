alter table migration.import_batches
  add column version integer not null default 1,
  add constraint import_batches_version_ck check (version > 0);

alter table migration.license_staging_rows
  drop constraint license_staging_rows_quantity_ck;

create type public.import_validation_summary as (
  import_batch_id uuid,
  valid_count integer,
  warning_count integer,
  error_count integer,
  duplicate_count integer,
  skipped_count integer,
  version integer
);

create table private.migration_staged_license_secrets (
  license_staging_row_id uuid primary key
    references migration.license_staging_rows(id) on delete cascade,
  license_key_vault_secret_id uuid,
  license_key_fingerprint bytea,
  serial_vault_secret_id uuid,
  serial_fingerprint bytea,
  created_at timestamptz not null default now(),
  constraint migration_staged_license_secrets_value_ck check (
    license_key_fingerprint is not null or serial_fingerprint is not null
  )
);

create or replace function private.migration_caller_allowed()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.role() = 'service_role' or private.is_admin();
$$;

create or replace function private.jsonb_contains_secret_key(value jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case pg_catalog.jsonb_typeof(value)
    when 'object' then exists (
      select 1
      from pg_catalog.jsonb_each(value) as item(key, child)
      where pg_catalog.lower(
        pg_catalog.regexp_replace(item.key, '[^a-zA-Z0-9]+', '_', 'g')
      ) in (
        'serial', 'serial_no', 'serial_number', 'license_key',
        'product_key', 'os_key'
      ) or private.jsonb_contains_secret_key(item.child)
    )
    when 'array' then exists (
      select 1
      from pg_catalog.jsonb_array_elements(value) as item(child)
      where private.jsonb_contains_secret_key(item.child)
    )
    else false
  end;
$$;

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

  if source_count <> 2 or asset_count <> 1 or license_count <> 1 then
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

create or replace function private.assert_stage_request(
  requested_batch_id uuid,
  rows jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  batch_status migration.import_batch_status;
begin
  if not private.migration_caller_allowed() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;
  if pg_catalog.jsonb_typeof(rows) <> 'array'
    or pg_catalog.jsonb_array_length(rows) = 0 then
    raise exception using errcode = '22023', message = 'ROWS_REQUIRED';
  end if;
  if pg_catalog.jsonb_array_length(rows) > 100 then
    raise exception using errcode = '22023', message = 'BATCH_TOO_LARGE';
  end if;
  select batch.status into batch_status
  from migration.import_batches as batch
  where batch.id = requested_batch_id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'IMPORT_BATCH_NOT_FOUND';
  end if;
  if batch_status not in ('draft', 'extracted') then
    raise exception using errcode = 'P0001', message = 'IMPORT_BATCH_NOT_EDITABLE';
  end if;
end;
$$;

create or replace function public.stage_asset_rows(
  import_batch_id uuid,
  rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  row_payload jsonb;
  staged_count integer := 0;
  resolved_source_file_id uuid;
begin
  perform private.assert_stage_request(import_batch_id, rows);
  for row_payload in select item from pg_catalog.jsonb_array_elements(rows) as supplied(item)
  loop
    if private.jsonb_contains_secret_key(coalesce(row_payload->'raw_data', '{}'::jsonb)) then
      raise exception using errcode = '22023', message = 'PLAINTEXT_SECRET_REJECTED';
    end if;
    resolved_source_file_id := (row_payload->>'source_file_id')::uuid;
    if not exists (
      select 1 from migration.source_files as source
      where source.id = resolved_source_file_id
        and source.import_batch_id = stage_asset_rows.import_batch_id
        and source.file_name = '02 203Total License(TKC) Update 2026-08-28.xlsx'
    ) then
      raise exception using errcode = '22023', message = 'INVALID_SOURCE_FILE';
    end if;
    insert into migration.asset_staging_rows (
      source_file_id, sheet_name, source_row_number, source_row_hash, raw_data,
      normalized_asset_code, normalized_computer_name, normalized_site_code,
      normalized_location_code, normalized_department_code,
      normalized_mac_address, normalized_ip_address, secret_present,
      secret_fingerprint, secret_masked_hint, secret_write_status
    ) values (
      resolved_source_file_id, row_payload->>'sheet_name',
      (row_payload->>'source_row_number')::integer,
      pg_catalog.decode(row_payload->>'source_row_hash', 'hex'),
      coalesce(row_payload->'raw_data', '{}'::jsonb),
      nullif(row_payload->>'normalized_asset_code', ''),
      nullif(row_payload->>'normalized_computer_name', ''),
      nullif(row_payload->>'normalized_site_code', ''),
      nullif(row_payload->>'normalized_location_code', ''),
      nullif(row_payload->>'normalized_department_code', ''),
      nullif(row_payload->>'normalized_mac_address', ''),
      nullif(row_payload->>'normalized_ip_address', '')::inet,
      coalesce((row_payload->>'secret_present')::boolean, false),
      case when row_payload->>'secret_fingerprint' is null then null
        else pg_catalog.decode(row_payload->>'secret_fingerprint', 'hex') end,
      nullif(row_payload->>'secret_masked_hint', ''),
      nullif(row_payload->>'secret_write_status', '')
    )
    on conflict (source_file_id, sheet_name, source_row_number) do update set
      source_row_hash = excluded.source_row_hash,
      raw_data = excluded.raw_data,
      normalized_asset_code = excluded.normalized_asset_code,
      normalized_computer_name = excluded.normalized_computer_name,
      normalized_site_code = excluded.normalized_site_code,
      normalized_location_code = excluded.normalized_location_code,
      normalized_department_code = excluded.normalized_department_code,
      normalized_mac_address = excluded.normalized_mac_address,
      normalized_ip_address = excluded.normalized_ip_address,
      validation_status = 'pending', validation_messages = '[]'::jsonb;
    staged_count := staged_count + 1;
  end loop;
  update migration.import_batches
  set status = 'extracted', version = version + 1
  where id = stage_asset_rows.import_batch_id;
  return staged_count;
end;
$$;

create or replace function public.stage_license_rows(
  import_batch_id uuid,
  rows jsonb
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  row_payload jsonb;
  staged_count integer := 0;
  resolved_source_file_id uuid;
  staged_row_id uuid;
  secret_payload jsonb;
  license_key_value text;
  serial_value text;
  license_key_fingerprint bytea;
  serial_fingerprint bytea;
  license_key_vault_id uuid;
  serial_vault_id uuid;
begin
  perform private.assert_stage_request(import_batch_id, rows);
  perform private.lock_license_plaintext_boundary();
  for row_payload in select item from pg_catalog.jsonb_array_elements(rows) as supplied(item)
  loop
    if private.jsonb_contains_secret_key(coalesce(row_payload->'raw_data', '{}'::jsonb)) then
      raise exception using errcode = '22023', message = 'PLAINTEXT_SECRET_REJECTED';
    end if;
    resolved_source_file_id := (row_payload->>'source_file_id')::uuid;
    if not exists (
      select 1 from migration.source_files as source
      where source.id = resolved_source_file_id
        and source.import_batch_id = stage_license_rows.import_batch_id
        and source.file_name = '03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx'
    ) then
      raise exception using errcode = '22023', message = 'INVALID_SOURCE_FILE';
    end if;

    secret_payload := coalesce(row_payload->'secret_payload', '{}'::jsonb);
    if pg_catalog.jsonb_typeof(secret_payload) <> 'object'
      or exists (select 1 from pg_catalog.jsonb_object_keys(secret_payload) as key where key not in ('license_key','serial_number')) then
      raise exception using errcode = '22023', message = 'INVALID_SECRET_PAYLOAD';
    end if;
    license_key_value := nullif(secret_payload->>'license_key', '');
    serial_value := nullif(secret_payload->>'serial_number', '');
    license_key_fingerprint := case when license_key_value is null
      then case when row_payload->>'license_key_fingerprint' is null then null else pg_catalog.decode(row_payload->>'license_key_fingerprint','hex') end
      else private.fingerprint_license_secret('license_key', license_key_value) end;
    serial_fingerprint := case when serial_value is null
      then case when row_payload->>'serial_fingerprint' is null then null else pg_catalog.decode(row_payload->>'serial_fingerprint','hex') end
      else private.fingerprint_license_secret('serial_number', serial_value) end;

    perform private.assert_no_license_secret_collision(
      array[row_payload->>'normalized_publisher', row_payload->>'normalized_vendor', row_payload->>'normalized_product_name'],
      array[license_key_fingerprint, serial_fingerprint]::bytea[]
    );

    insert into migration.license_staging_rows (
      source_file_id, sheet_name, source_row_number, source_row_hash, raw_data,
      normalized_publisher, normalized_vendor, normalized_product_name,
      normalized_version, normalized_classification, normalized_purchase_form,
      normalized_owned_quantity, normalized_purchase_date, normalized_start_date,
      normalized_end_date, normalized_record_status,
      license_key_present, license_key_fingerprint, license_key_masked_hint,
      serial_present, serial_fingerprint, serial_masked_hint, secret_write_status
    ) values (
      resolved_source_file_id, row_payload->>'sheet_name',
      (row_payload->>'source_row_number')::integer,
      pg_catalog.decode(row_payload->>'source_row_hash', 'hex'),
      coalesce(row_payload->'raw_data', '{}'::jsonb),
      nullif(row_payload->>'normalized_publisher',''), nullif(row_payload->>'normalized_vendor',''),
      nullif(row_payload->>'normalized_product_name',''), coalesce(row_payload->>'normalized_version',''),
      nullif(row_payload->>'normalized_classification',''), nullif(row_payload->>'normalized_purchase_form',''),
      nullif(row_payload->>'normalized_owned_quantity','')::integer,
      nullif(row_payload->>'normalized_purchase_date','')::date,
      nullif(row_payload->>'normalized_start_date','')::date,
      nullif(row_payload->>'normalized_end_date','')::date,
      nullif(row_payload->>'normalized_record_status',''),
      coalesce((row_payload->>'license_key_present')::boolean, license_key_value is not null),
      license_key_fingerprint,
      case when license_key_value is not null then private.mask_license_secret(license_key_value) else nullif(row_payload->>'license_key_masked_hint','') end,
      coalesce((row_payload->>'serial_present')::boolean, serial_value is not null),
      serial_fingerprint,
      case when serial_value is not null then private.mask_license_secret(serial_value) else nullif(row_payload->>'serial_masked_hint','') end,
      case when license_key_value is not null or serial_value is not null then 'vaulted' else nullif(row_payload->>'secret_write_status','') end
    )
    on conflict (source_file_id, sheet_name, source_row_number) do update set
      source_row_hash=excluded.source_row_hash, raw_data=excluded.raw_data,
      normalized_publisher=excluded.normalized_publisher, normalized_vendor=excluded.normalized_vendor,
      normalized_product_name=excluded.normalized_product_name, normalized_version=excluded.normalized_version,
      normalized_classification=excluded.normalized_classification,
      normalized_purchase_form=excluded.normalized_purchase_form,
      normalized_owned_quantity=excluded.normalized_owned_quantity,
      normalized_purchase_date=excluded.normalized_purchase_date,
      normalized_start_date=excluded.normalized_start_date,
      normalized_end_date=excluded.normalized_end_date,
      normalized_record_status=excluded.normalized_record_status,
      license_key_present=excluded.license_key_present,
      license_key_fingerprint=excluded.license_key_fingerprint,
      license_key_masked_hint=excluded.license_key_masked_hint,
      serial_present=excluded.serial_present, serial_fingerprint=excluded.serial_fingerprint,
      serial_masked_hint=excluded.serial_masked_hint, secret_write_status=excluded.secret_write_status,
      validation_status='pending', validation_messages='[]'::jsonb
    returning id into staged_row_id;

    if license_key_value is not null then
      license_key_vault_id := vault.create_secret(license_key_value, pg_catalog.format('sam_migration_%s_license_key',staged_row_id), 'SAM staged license key');
    else license_key_vault_id := null; end if;
    if serial_value is not null then
      serial_vault_id := vault.create_secret(serial_value, pg_catalog.format('sam_migration_%s_serial_number',staged_row_id), 'SAM staged serial number');
    else serial_vault_id := null; end if;
    if license_key_fingerprint is not null or serial_fingerprint is not null then
      insert into private.migration_staged_license_secrets (
        license_staging_row_id, license_key_vault_secret_id, license_key_fingerprint,
        serial_vault_secret_id, serial_fingerprint
      ) values (staged_row_id, license_key_vault_id, license_key_fingerprint, serial_vault_id, serial_fingerprint)
      on conflict (license_staging_row_id) do update set
        license_key_vault_secret_id=coalesce(excluded.license_key_vault_secret_id,private.migration_staged_license_secrets.license_key_vault_secret_id),
        license_key_fingerprint=excluded.license_key_fingerprint,
        serial_vault_secret_id=coalesce(excluded.serial_vault_secret_id,private.migration_staged_license_secrets.serial_vault_secret_id),
        serial_fingerprint=excluded.serial_fingerprint;
    end if;
    staged_count := staged_count + 1;
  end loop;
  update migration.import_batches set status='extracted', version=version+1 where id=stage_license_rows.import_batch_id;
  return staged_count;
end;
$$;

create or replace function public.validate_import_batch(import_batch_id uuid)
returns public.import_validation_summary
language plpgsql
security definer
set search_path = ''
as $$
declare
  batch migration.import_batches%rowtype;
  result public.import_validation_summary;
  reconciliation_id uuid;
begin
  if not private.migration_caller_allowed() then raise exception using errcode='42501',message='ACCESS_DENIED'; end if;
  select * into batch from migration.import_batches where id=import_batch_id for update;
  if not found then raise exception using errcode='P0002',message='IMPORT_BATCH_NOT_FOUND'; end if;
  if batch.status in ('committed','failed','cancelled') then raise exception using errcode='P0001',message='IMPORT_BATCH_NOT_EDITABLE'; end if;

  delete from migration.row_results where migration.row_results.import_batch_id=validate_import_batch.import_batch_id;
  delete from migration.reconciliation_runs where migration.reconciliation_runs.import_batch_id=validate_import_batch.import_batch_id;

  insert into migration.row_results (import_batch_id,staging_entity_type,staging_row_id,result_status,decision_reason,errors,warnings)
  select import_batch_id,'asset',row.id,
    case
      when coalesce(row.normalized_asset_code,row.normalized_computer_name) is null or row.normalized_site_code is null then 'error'
      when row.duplicate_rank > 1 or row.production_duplicate then 'skipped'
      else 'imported' end,
    case when row.duplicate_rank > 1 or row.production_duplicate then 'DUPLICATE_EXACT' end,
    case when coalesce(row.normalized_asset_code,row.normalized_computer_name) is null then '["MISSING_ASSET_BUSINESS_KEY"]'::jsonb
      when row.normalized_site_code is null then '["MISSING_SITE"]'::jsonb else '[]'::jsonb end,
    '[]'::jsonb
  from (
    select staged.*,
      row_number() over (partition by normalized_site_code,coalesce(normalized_asset_code,normalized_computer_name) order by source_file_id,sheet_name,source_row_number) duplicate_rank,
      exists(select 1 from public.assets a join public.sites s on s.id=a.site_id where s.code=staged.normalized_site_code and (a.asset_code=staged.normalized_asset_code or (staged.normalized_asset_code is null and a.computer_name=staged.normalized_computer_name))) production_duplicate
    from migration.asset_staging_rows staged
    join migration.source_files source on source.id=staged.source_file_id
    where source.import_batch_id=validate_import_batch.import_batch_id
  ) row;

  insert into migration.row_results (import_batch_id,staging_entity_type,staging_row_id,result_status,decision_reason,errors,warnings)
  select import_batch_id,'license',row.id,
    case when row.normalized_publisher is null or row.normalized_product_name is null or coalesce(row.normalized_owned_quantity,0)<0 then 'error'
      when row.duplicate_rank>1 or row.production_duplicate then 'skipped' else 'imported' end,
    case when row.duplicate_rank>1 or row.production_duplicate then 'DUPLICATE_EXACT' end,
    case when row.normalized_publisher is null then '["MISSING_PUBLISHER"]'::jsonb
      when row.normalized_product_name is null then '["MISSING_PRODUCT_NAME"]'::jsonb
      when coalesce(row.normalized_owned_quantity,0)<0 then '["INVALID_OWNED_QUANTITY"]'::jsonb else '[]'::jsonb end,
    case when row.normalized_vendor is null or row.normalized_classification is null or row.normalized_purchase_form is null then '["INCOMPLETE_OPTIONAL_MAPPING"]'::jsonb else '[]'::jsonb end
  from (
    select staged.*,
      row_number() over (partition by normalized_publisher,normalized_product_name,coalesce(normalized_version,''),license_key_fingerprint,serial_fingerprint order by source_file_id,sheet_name,source_row_number) duplicate_rank,
      exists(select 1 from private.license_secrets secret where (staged.license_key_fingerprint is not null and secret.license_key_fingerprint=staged.license_key_fingerprint) or (staged.serial_fingerprint is not null and secret.serial_fingerprint=staged.serial_fingerprint)) production_duplicate
    from migration.license_staging_rows staged
    join migration.source_files source on source.id=staged.source_file_id
    where source.import_batch_id=validate_import_batch.import_batch_id
  ) row;

  update migration.asset_staging_rows staged set
    validation_status=row_result.result_status,
    validation_messages=row_result.errors||row_result.warnings
  from migration.row_results row_result
  where row_result.staging_row_id=staged.id and row_result.import_batch_id=validate_import_batch.import_batch_id and row_result.staging_entity_type='asset';
  update migration.license_staging_rows staged set
    validation_status=row_result.result_status,
    validation_messages=row_result.errors||row_result.warnings
  from migration.row_results row_result
  where row_result.staging_row_id=staged.id and row_result.import_batch_id=validate_import_batch.import_batch_id and row_result.staging_entity_type='license';

  insert into migration.reconciliation_runs(import_batch_id,completed_at,checked_by,status)
  values(import_batch_id,now(),auth.uid(),'matched') returning id into reconciliation_id;
  insert into migration.reconciliation_totals(reconciliation_run_id,metric,site_id,source_total,target_total,status)
  select reconciliation_id,metric,site_id,total,total,'matched'
  from (
    select 'assets'::text metric,s.id site_id,count(a.id)::numeric total from public.sites s left join migration.asset_staging_rows a on a.normalized_site_code=s.code and a.source_file_id in(select id from migration.source_files where migration.source_files.import_batch_id=validate_import_batch.import_batch_id) group by s.id
    union all
    select 'licenses',s.id,count(l.id)::numeric from public.sites s left join migration.license_staging_rows l on ((s.code='FACTORY' and l.sheet_name ilike '%factory%') or (s.code='BANGKOK_OFFICE' and l.sheet_name ilike '%office%')) and l.source_file_id in(select id from migration.source_files where migration.source_files.import_batch_id=validate_import_batch.import_batch_id) group by s.id
    union all
    select 'owned_quantity',s.id,coalesce(sum(l.normalized_owned_quantity),0)::numeric from public.sites s left join migration.license_staging_rows l on ((s.code='FACTORY' and l.sheet_name ilike '%factory%') or (s.code='BANGKOK_OFFICE' and l.sheet_name ilike '%office%')) and l.source_file_id in(select id from migration.source_files where migration.source_files.import_batch_id=validate_import_batch.import_batch_id) group by s.id
  ) totals;

  update migration.import_batches set status='validated', approved_at=null,approved_by=null,approval_note=null,version=version+1 where id=import_batch_id returning version into result.version;
  select count(*) filter(where result_status='imported' and jsonb_array_length(warnings)=0),
    count(*) filter(where jsonb_array_length(warnings)>0 and result_status<>'error'),
    count(*) filter(where result_status='error'),
    count(*) filter(where decision_reason='DUPLICATE_EXACT'),
    count(*) filter(where result_status='skipped')
  into result.valid_count,result.warning_count,result.error_count,result.duplicate_count,result.skipped_count
  from migration.row_results where migration.row_results.import_batch_id=validate_import_batch.import_batch_id;
  result.import_batch_id:=import_batch_id;
  return result;
end;
$$;

create or replace function public.get_import_batch_review(import_batch_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare response jsonb;
begin
  if not private.is_admin() then raise exception using errcode='42501',message='ACCESS_DENIED'; end if;
  if not exists(select 1 from migration.import_batches where id=import_batch_id) then raise exception using errcode='P0002',message='IMPORT_BATCH_NOT_FOUND'; end if;
  select pg_catalog.jsonb_build_object(
    'batch',pg_catalog.jsonb_build_object('id',b.id,'batch_name',b.batch_name,'environment',b.environment,'status',b.status,'version',b.version,'started_at',b.started_at,'approved_at',b.approved_at),
    'sources',coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('id',s.id,'file_name',s.file_name,'sha256',pg_catalog.encode(s.sha256_checksum,'hex'),'file_size_bytes',s.file_size_bytes) order by s.file_name) from migration.source_files s where s.import_batch_id=b.id),'[]'::jsonb),
    'summary',pg_catalog.jsonb_build_object(
      'valid_count',(select count(*) from migration.row_results r where r.import_batch_id=b.id and r.result_status='imported' and jsonb_array_length(r.warnings)=0),
      'warning_count',(select count(*) from migration.row_results r where r.import_batch_id=b.id and jsonb_array_length(r.warnings)>0 and r.result_status<>'error'),
      'error_count',(select count(*) from migration.row_results r where r.import_batch_id=b.id and r.result_status='error'),
      'duplicate_count',(select count(*) from migration.row_results r where r.import_batch_id=b.id and r.decision_reason='DUPLICATE_EXACT'),
      'skipped_count',(select count(*) from migration.row_results r where r.import_batch_id=b.id and r.result_status='skipped')),
    'rows',coalesce((select pg_catalog.jsonb_agg(detail order by detail->>'entity_type', (detail->>'source_row_number')::integer) from (
      select pg_catalog.jsonb_build_object('entity_type','asset','staging_row_id',a.id,'sheet_name',a.sheet_name,'source_row_number',a.source_row_number,'normalized_values',pg_catalog.jsonb_build_object('asset_code',a.normalized_asset_code,'computer_name',a.normalized_computer_name,'site_code',a.normalized_site_code),'secret_masked_hint',a.secret_masked_hint,'secret_fingerprint',case when a.secret_fingerprint is null then null else pg_catalog.encode(a.secret_fingerprint,'hex') end,'result_status',r.result_status,'errors',r.errors,'warnings',r.warnings,'decision_reason',r.decision_reason) detail from migration.asset_staging_rows a join migration.source_files s on s.id=a.source_file_id left join migration.row_results r on r.import_batch_id=b.id and r.staging_row_id=a.id and r.staging_entity_type='asset' where s.import_batch_id=b.id
      union all
      select pg_catalog.jsonb_build_object('entity_type','license','staging_row_id',l.id,'sheet_name',l.sheet_name,'source_row_number',l.source_row_number,'normalized_values',pg_catalog.jsonb_build_object('publisher',l.normalized_publisher,'vendor',l.normalized_vendor,'product_name',l.normalized_product_name,'version',l.normalized_version,'owned_quantity',l.normalized_owned_quantity),'license_key_masked_hint',l.license_key_masked_hint,'license_key_fingerprint',case when l.license_key_fingerprint is null then null else pg_catalog.encode(l.license_key_fingerprint,'hex') end,'serial_masked_hint',l.serial_masked_hint,'serial_fingerprint',case when l.serial_fingerprint is null then null else pg_catalog.encode(l.serial_fingerprint,'hex') end,'result_status',r.result_status,'errors',r.errors,'warnings',r.warnings,'decision_reason',r.decision_reason) detail from migration.license_staging_rows l join migration.source_files s on s.id=l.source_file_id left join migration.row_results r on r.import_batch_id=b.id and r.staging_row_id=l.id and r.staging_entity_type='license' where s.import_batch_id=b.id
    ) details),'[]'::jsonb),
    'reconciliation',coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(t) order by t.metric,t.site_id) from migration.reconciliation_runs rr join migration.reconciliation_totals t on t.reconciliation_run_id=rr.id where rr.import_batch_id=b.id),'[]'::jsonb)
  ) into response from migration.import_batches b where b.id=import_batch_id;
  return response;
end;
$$;

create or replace function public.acknowledge_import_warnings(import_batch_id uuid, expected_version integer)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare current_version integer;
begin
  if not private.is_admin() then raise exception using errcode='42501',message='ACCESS_DENIED'; end if;
  select version into current_version from migration.import_batches where id=import_batch_id for update;
  if not found then raise exception using errcode='P0002',message='IMPORT_BATCH_NOT_FOUND'; end if;
  if current_version<>expected_version then raise exception using errcode='40001',message='VERSION_CONFLICT'; end if;
  if exists(select 1 from migration.row_results where migration.row_results.import_batch_id=acknowledge_import_warnings.import_batch_id and result_status='error') then raise exception using errcode='P0001',message='IMPORT_HAS_ERRORS'; end if;
  update migration.import_batches set status='approved',approved_at=now(),approved_by=auth.uid(),approval_note='Warnings acknowledged',version=version+1 where id=acknowledge_import_warnings.import_batch_id returning version into current_version;
  return current_version;
end;
$$;

revoke all on function private.migration_caller_allowed() from public,anon,authenticated;
revoke all on function private.jsonb_contains_secret_key(jsonb) from public,anon,authenticated;
revoke all on function private.assert_stage_request(uuid,jsonb) from public,anon,authenticated;
revoke all on function public.begin_import_batch(jsonb) from public,anon;
revoke all on function public.stage_asset_rows(uuid,jsonb) from public,anon;
revoke all on function public.stage_license_rows(uuid,jsonb) from public,anon;
revoke all on function public.validate_import_batch(uuid) from public,anon;
revoke all on function public.get_import_batch_review(uuid) from public,anon;
revoke all on function public.acknowledge_import_warnings(uuid,integer) from public,anon;
grant execute on function public.begin_import_batch(jsonb) to authenticated,service_role;
grant execute on function public.stage_asset_rows(uuid,jsonb) to authenticated,service_role;
grant execute on function public.stage_license_rows(uuid,jsonb) to authenticated,service_role;
grant execute on function public.validate_import_batch(uuid) to authenticated,service_role;
grant execute on function public.get_import_batch_review(uuid) to authenticated;
grant execute on function public.acknowledge_import_warnings(uuid,integer) to authenticated;
