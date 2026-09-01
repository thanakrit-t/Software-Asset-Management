do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles', 'people', 'sites', 'locations', 'departments',
    'asset_types', 'asset_statuses', 'internet_levels',
    'software_categories', 'license_metrics', 'product_classifications',
    'purchase_forms', 'expiration_thresholds', 'publishers',
    'software_products', 'assets', 'asset_network_interfaces',
    'asset_person_assignments', 'asset_software_installations', 'vendors',
    'license_entitlements', 'license_site_scopes', 'license_allocations',
    'notifications', 'notification_recipients', 'system_settings'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('alter table public.%I force row level security', table_name);
  end loop;
end;
$$;

alter table audit.audit_events enable row level security;
alter table audit.audit_events force row level security;

create policy profiles_read_self_or_admin
on public.profiles
for select
to authenticated
using (
  id = auth.uid() or (select private.is_admin())
);

create policy people_read_active_user
on public.people
for select
to authenticated
using ((select private.is_active_user()));

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'sites', 'locations', 'departments', 'asset_types', 'asset_statuses',
    'internet_levels', 'software_categories', 'license_metrics',
    'product_classifications', 'purchase_forms', 'expiration_thresholds',
    'publishers', 'software_products', 'assets', 'asset_network_interfaces',
    'asset_person_assignments', 'asset_software_installations', 'vendors',
    'license_entitlements', 'license_site_scopes', 'license_allocations',
    'notifications', 'system_settings'
  ]
  loop
    execute format(
      'create policy active_user_read on public.%I for select to authenticated using ((select private.is_active_user()))',
      table_name
    );
  end loop;
end;
$$;

create policy notification_recipients_read_own_or_admin
on public.notification_recipients
for select
to authenticated
using (profile_id = auth.uid() or (select private.is_admin()));

create policy audit_events_read_admin
on audit.audit_events
for select
to authenticated
using ((select private.is_admin()));

revoke all on schema public from anon;
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;
revoke execute on all functions in schema public from anon;

grant usage on schema public to authenticated;
grant select on all tables in schema public to authenticated;
revoke insert, update, delete, truncate, references, trigger
on all tables in schema public from authenticated;
revoke usage, update on all sequences in schema public from authenticated;

grant execute on function private.is_active_user() to authenticated;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.current_profile_id() to authenticated;

grant execute on function public.allocate_license(jsonb) to authenticated;
grant execute on function public.release_license_allocation(uuid, integer, text) to authenticated;
grant execute on function public.set_user_role(uuid, public.app_role, text) to authenticated;
grant execute on function public.set_user_status(uuid, public.account_status, text) to authenticated;

grant select on audit.audit_events to authenticated;

grant select on public.asset_current_people_v to authenticated;
grant select on public.asset_inventory_v to authenticated;
grant select on public.active_allocations_v to authenticated;
grant select on public.license_compliance_v to authenticated;
grant select on public.license_expiry_v to authenticated;
grant select on public.license_safe_v to authenticated;
grant select on public.dashboard_summary_v to authenticated;
grant select on public.data_quality_v to authenticated;
grant select on public.notification_feed_v to authenticated;
grant select on public.audit_log_admin_v to authenticated;

revoke all on schema private, audit, migration from public, anon, authenticated;
revoke all on all tables in schema private, migration from public, anon, authenticated;
revoke all on all sequences in schema private, migration from public, anon, authenticated;
revoke all on all functions in schema private, migration from public, anon, authenticated;

grant execute on function private.is_active_user() to authenticated;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.current_profile_id() to authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
alter default privileges in schema private revoke all on tables from public, anon, authenticated;
alter default privileges in schema audit revoke all on tables from public, anon, authenticated;
alter default privileges in schema migration revoke all on tables from public, anon, authenticated;
