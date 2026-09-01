create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists pg_trgm with schema extensions;

create schema if not exists private;
create schema if not exists audit;
create schema if not exists migration;

revoke all on schema private, audit, migration from public, anon, authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
alter default privileges in schema private revoke all on tables from public, anon, authenticated;
alter default privileges in schema private revoke execute on functions from public, anon, authenticated;
alter default privileges in schema audit revoke all on tables from public, anon, authenticated;
alter default privileges in schema audit revoke execute on functions from public, anon, authenticated;
alter default privileges in schema migration revoke all on tables from public, anon, authenticated;
alter default privileges in schema migration revoke execute on functions from public, anon, authenticated;

create type public.app_role as enum ('admin', 'user');
create type public.account_status as enum ('active', 'inactive', 'locked');
create type public.license_target_mode as enum (
  'device',
  'named_user',
  'concurrent',
  'site',
  'mixed'
);

create or replace function private.touch_updated_row()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.version := old.version + 1;
  if auth.uid() is not null then
    new.updated_by := auth.uid();
  end if;
  return new;
end;
$$;

create or replace function private.prevent_code_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.code is distinct from old.code then
    raise exception using
      errcode = 'P0001',
      message = 'DUPLICATE_BUSINESS_KEY',
      detail = 'Master data code is immutable';
  end if;
  return new;
end;
$$;

revoke all on function private.touch_updated_row() from public, anon, authenticated;
revoke all on function private.prevent_code_change() from public, anon, authenticated;
