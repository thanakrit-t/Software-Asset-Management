create or replace function private.sync_missing_auth_profiles()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  inserted_count integer;
begin
  insert into public.profiles (
    id,
    display_name,
    email,
    app_role,
    account_status
  )
  select
    auth_user.id,
    coalesce(nullif(split_part(auth_user.email, '@', 1), ''), 'User'),
    auth_user.email,
    'user'::public.app_role,
    'active'::public.account_status
  from auth.users as auth_user
  where auth_user.email is not null
  on conflict (id) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

revoke all on function private.sync_missing_auth_profiles() from public, anon, authenticated;

select private.sync_missing_auth_profiles();
