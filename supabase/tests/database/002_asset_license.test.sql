begin;

select plan(24);

select has_table('public', 'publishers', 'publishers table exists');
select has_table('public', 'software_products', 'software products table exists');
select has_table('public', 'assets', 'assets table exists');
select has_index(
  'public',
  'assets',
  'assets_asset_code_trgm_idx',
  'asset code trigram index exists'
);
select has_index(
  'public',
  'assets',
  'assets_computer_name_trgm_idx',
  'computer name trigram index exists'
);
select has_table('public', 'asset_network_interfaces', 'network interfaces table exists');
select has_table('public', 'asset_person_assignments', 'person assignments table exists');
select has_table('public', 'asset_software_installations', 'software installations table exists');
select has_table('public', 'vendors', 'vendors table exists');
select has_table('public', 'license_entitlements', 'license entitlements table exists');
select has_table('public', 'license_site_scopes', 'license site scopes table exists');
select has_table('public', 'license_allocations', 'license allocations table exists');
select has_table('private', 'license_secrets', 'private license secrets table exists');
select has_table('public', 'notifications', 'notifications table exists');
select has_table('audit', 'audit_events', 'audit events table exists');
select has_table('public', 'system_settings', 'system settings table exists');
select has_table('migration', 'import_batches', 'import batches table exists');
select has_table('migration', 'asset_staging_rows', 'asset staging table exists');
select has_table('migration', 'license_staging_rows', 'license staging table exists');

insert into public.publishers (id, code, name_th, name_en)
values ('20000000-0000-4000-8000-000000000001', 'MICROSOFT', 'ไมโครซอฟท์', 'Microsoft');

insert into public.software_products (
  id, publisher_id, category_id, name, version_edition, support_status
)
values (
  '21000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  '13000000-0000-4000-8000-000000000001',
  'Windows Test',
  '11',
  'supported'
);

insert into public.assets (
  id, asset_code, computer_name, asset_type_id, asset_status_id, site_id
)
values (
  '22000000-0000-4000-8000-000000000001',
  'TKC-001',
  'TKC-PC-001',
  '10000000-0000-4000-8000-000000000001',
  '11000000-0000-4000-8000-000000000001',
  '01000000-0000-4000-8000-000000000001'
);

select throws_ok(
  $$
    insert into public.assets (
      asset_code, asset_type_id, asset_status_id, site_id
    ) values (
      'tkc-001',
      '10000000-0000-4000-8000-000000000001',
      '11000000-0000-4000-8000-000000000001',
      '01000000-0000-4000-8000-000000000002'
    )
  $$,
  '23505',
  null,
  'active asset codes are unique without case sensitivity'
);

select throws_ok(
  $$
    insert into public.asset_network_interfaces (
      asset_id, interface_type, mac_address, address_mode
    ) values (
      '22000000-0000-4000-8000-000000000001',
      'lan',
      'invalid-mac',
      'dhcp'
    )
  $$,
  '23514',
  null,
  'invalid normalized MAC addresses are rejected'
);

insert into public.license_entitlements (
  id, software_product_id, license_metric_id, owned_quantity,
  record_status, scope_mode
)
values (
  '23000000-0000-4000-8000-000000000001',
  '21000000-0000-4000-8000-000000000001',
  '14000000-0000-4000-8000-000000000001',
  2,
  'active',
  'all_sites'
);

select throws_ok(
  $$
    insert into public.license_allocations (
      license_entitlement_id, target_type, asset_id, person_id,
      quantity, allocated_at
    ) values (
      '23000000-0000-4000-8000-000000000001',
      'asset',
      '22000000-0000-4000-8000-000000000001',
      '00000000-0000-4000-8000-000000000099',
      1,
      current_date
    )
  $$,
  '23514',
  null,
  'allocation target columns must match target type'
);

select throws_ok(
  $$
    insert into public.license_allocations (
      license_entitlement_id, target_type, asset_id, quantity, allocated_at
    ) values (
      '23000000-0000-4000-8000-000000000001',
      'asset',
      '22000000-0000-4000-8000-000000000001',
      0,
      current_date
    )
  $$,
  '23514',
  null,
  'allocation quantity must be positive'
);

select is(
  (select count(*)::integer from public.system_settings),
  1,
  'system settings contains exactly one row'
);

select * from finish();
rollback;
