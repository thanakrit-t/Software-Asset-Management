# Live CRUD Database Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add audited, Admin-only PostgreSQL commands for operational CRUD state transitions without granting direct table writes.

**Architecture:** Public security-definer RPCs are the only mutation boundary. Each RPC clears its search path, checks the authenticated Admin, validates business rules, applies optimistic locking, and writes an audit event in the same transaction.

**Tech Stack:** Supabase CLI 2.116+, PostgreSQL/PLpgSQL, pgTAP, generated Supabase TypeScript types

**Spec:** `docs/superpowers/specs/2026-09-02-live-crud-excel-migration-design.md`

## Global Constraints

- Hosted Supabase remains the single source of truth.
- Business records use Archive, Release, or Deactivate; no application hard delete.
- `anon` has no application access and `authenticated` has no direct table mutation grants.
- All administrative writes require an active Admin, `expected_version` on updates, a reason for state transitions, and an audit event.
- Serial/License Key plaintext is never returned by ordinary reads or written to audit/log payloads.
- Never run `supabase db reset --linked`.
- Read the relevant installed Next.js 16 guide before any later application-code task; this database plan does not modify Next.js code.

---

### Task 1: Asset and Software Product Commands

**Files:**
- Create: `supabase/migrations/202609020002_asset_software_commands.sql`
- Modify: `supabase/tests/database/002_asset_license.test.sql`

**Interfaces:**
- Consumes: `private.is_admin()`, `public.assets`, `public.software_products`, `audit.audit_events`, row `version` triggers.
- Produces: `public.create_asset(jsonb)`, `public.update_asset(uuid, integer, jsonb)`, `public.archive_asset(uuid, integer, text, boolean)`, `public.create_software_product(jsonb)`, `public.update_software_product(uuid, integer, jsonb)`, `public.archive_software_product(uuid, integer, text)`.

- [ ] **Step 1: Add failing pgTAP coverage for access, optimistic locking, and Archive**

Append assertions using the existing fixture helpers and transaction setup:

```sql
select throws_ok(
  $$ select public.update_asset('00000000-0000-0000-0000-000000000001', 1, '{}'::jsonb) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot update an asset'
);

select lives_ok(
  $$ select public.update_asset(
    current_setting('test.asset_id')::uuid,
    1,
    jsonb_build_object('computer_name', 'TDD-PC-UPDATED')
  ) $$,
  'admin updates an asset with the expected version'
);

select throws_ok(
  $$ select public.update_asset(current_setting('test.asset_id')::uuid, 1, '{}'::jsonb) $$,
  '40001', 'VERSION_CONFLICT',
  'stale asset updates are rejected'
);

select throws_ok(
  $$ select public.archive_software_product(
    current_setting('test.product_id')::uuid, 1, ''
  ) $$,
  '22023', 'REASON_REQUIRED',
  'software archive requires a reason'
);
```

- [ ] **Step 2: Run the focused database test and verify RED**

Run: `npx supabase test db supabase/tests/database/002_asset_license.test.sql`

Expected: FAIL because the six command functions do not exist.

- [ ] **Step 3: Implement the minimal command migration**

Use one private guard pattern and explicit allowlisted fields. The update shape must follow this pattern:

```sql
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
begin
  if not private.is_admin() then
    raise exception using errcode = '42501', message = 'ACCESS_DENIED';
  end if;

  select * into before_row from public.assets where id = asset_id for update;
  update public.assets
  set computer_name = coalesce(nullif(btrim(payload->>'computer_name'), ''), computer_name),
      asset_status_id = case
        when payload ? 'asset_status_id' then (payload->>'asset_status_id')::uuid
        else asset_status_id
      end,
      remark = case when payload ? 'remark' then nullif(btrim(payload->>'remark'), '') else remark end,
      updated_by = auth.uid()
  where id = asset_id and version = expected_version and archived_at is null
  returning * into result;

  if not found then
    raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
  end if;

  insert into audit.audit_events (
    actor_profile_id, actor_type, action, entity_type, entity_id,
    description, old_values, new_values
  ) values (
    auth.uid(), 'user', 'update', 'asset', result.id,
    'Asset updated', to_jsonb(before_row) - array['created_by','updated_by'],
    to_jsonb(result) - array['created_by','updated_by']
  );
  return result;
end;
$$;
```

Implement Create and Archive with the same authorization/audit pattern. Resolve `asset_type_id`, `asset_status_id`, `site_id`, `location_id`, and `department_id` only from explicit UUID payload fields and active master rows. `archive_asset` must count active Allocations and raise `ACTIVE_ALLOCATIONS_EXIST` unless `acknowledge_allocations` is true. Software Product Create uses the existing normalized unique business key; convert `unique_violation` to `DUPLICATE_RECORD`.

- [ ] **Step 4: Grant only function execution and verify GREEN**

At the end of the migration:

```sql
revoke all on function public.update_asset(uuid, integer, jsonb) from public, anon;
grant execute on function public.update_asset(uuid, integer, jsonb) to authenticated;
```

Repeat for all six functions. Run: `npx supabase db reset --local && npx supabase test db`

Expected: all pgTAP files pass.

- [ ] **Step 5: Commit the asset/software command slice**

```bash
git add supabase/migrations/202609020002_asset_software_commands.sql supabase/tests/database/002_asset_license.test.sql
git commit -m "feat: add asset and software commands"
```

---

### Task 2: License, Master Data, Settings, Notification, and Report Commands

**Files:**
- Create: `supabase/migrations/202609020003_license_admin_reporting_commands.sql`
- Modify: `supabase/tests/database/001_identity_master.test.sql`
- Modify: `supabase/tests/database/002_asset_license.test.sql`
- Modify: `supabase/tests/database/003_security.test.sql`

**Interfaces:**
- Consumes: Task 1 command conventions, existing `allocate_license`, `release_license_allocation`, `set_user_role`, and `set_user_status`.
- Produces: `create_license_entitlement(jsonb, jsonb)`, `update_license_entitlement(uuid, integer, jsonb)`, `archive_license_entitlement(uuid, integer, text)`, `rotate_license_secret(uuid, text, text, text)`, `reveal_license_secret(uuid, text, uuid)`, `update_master_data(text, uuid, integer, jsonb)`, `archive_master_data(text, uuid, integer, text)`, `set_notification_state(uuid, boolean, boolean)`, `update_system_settings(integer, jsonb)`, and `export_report(text, jsonb)`.

- [ ] **Step 1: Write failing business-rule and recipient-scope tests**

```sql
select throws_ok(
  $$ select public.update_license_entitlement(
    current_setting('test.license_id')::uuid,
    1,
    jsonb_build_object('owned_quantity', 0)
  ) $$,
  'P0001', 'OWNED_BELOW_ALLOCATED',
  'owned quantity cannot fall below active allocation'
);

select throws_ok(
  $$ select public.archive_license_entitlement(
    current_setting('test.license_id')::uuid, 1, 'retired contract'
  ) $$,
  'P0001', 'ACTIVE_ALLOCATIONS_EXIST',
  'license with active allocations cannot be archived'
);

select is(
  (select is_read from public.set_notification_state(
    current_setting('test.notification_id')::uuid, true, false
  )),
  true,
  'recipient marks own notification read'
);

select lives_ok(
  $$ select public.update_system_settings(
    1, jsonb_build_object('over_allocation_policy', 'block')
  ) $$,
  'admin updates validated settings with optimistic locking'
);

select lives_ok(
  $$ select public.export_report('asset_inventory', '{}'::jsonb) $$,
  'active user exports a safe report through the audited boundary'
);

select lives_ok(
  $$ select public.create_license_entitlement(
    jsonb_build_object(
      'software_product_id', current_setting('test.product_id'),
      'owned_quantity', 1,
      'license_metric', 'device'
    ),
    jsonb_build_object('license_key', 'TEST-KEY-001', 'serial_number', 'SERIAL 001')
  ) $$,
  'admin creates an entitlement and stores supplied secrets through Vault'
);

select throws_ok(
  $$ select public.reveal_license_secret(
    current_setting('test.license_id')::uuid, 'license_key', gen_random_uuid()
  ) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot reveal a license secret'
);

```

- [ ] **Step 2: Run focused tests and verify RED**

Run: `npx supabase test db`

Expected: FAIL with missing license/master/settings/notification/report command functions.

- [ ] **Step 3: Implement License commands and the complete Vault boundary**

Lock the entitlement before computing active allocated quantity:

```sql
select coalesce(sum(quantity), 0)::integer into active_quantity
from public.license_allocations
where license_entitlement_id = entitlement_id
  and allocation_status = 'active';

if payload ? 'owned_quantity'
  and (payload->>'owned_quantity')::integer < active_quantity then
  raise exception using errcode = 'P0001', message = 'OWNED_BELOW_ALLOCATED';
end if;
```

Create/update only safe entitlement fields and reject secret keys inside the ordinary `payload`. Enable the Supabase Vault extension in this migration if it is not already enabled. Implement private normalization helpers exactly as approved: License Key uses trim, uppercase ASCII, and removes whitespace/hyphens; Serial uses trim, uppercase ASCII, and collapses whitespace without removing punctuation. Load the HMAC pepper from its own named Vault entry, use HMAC-SHA-256 for fingerprints, and never expose the pepper or fingerprints through `public`.
`create_license_entitlement(payload, secret_payload)` creates the entitlement, calls `vault.create_secret` for each supplied value, stores only Vault UUIDs/fingerprints in `private.license_secrets`, and writes only masked hints to the entitlement. `rotate_license_secret(entitlement_id, secret_type, value, reason)` validates `secret_type` against `license_key|serial_number`, calls `vault.update_secret`, updates fingerprint/mask/rotation metadata, and audits only secret type plus reason. `reveal_license_secret(entitlement_id, secret_type, correlation_id)` checks the live Admin, reads only the selected Vault UUID through `vault.decrypted_secrets`, writes an audit event without plaintext, and returns a one-row typed result. Revoke all access to Vault/private helpers from `public`, `anon`, and `authenticated`; authenticated callers may execute only the guarded public RPCs. Archive rejects active Allocations.

Add pgTAP assertions that:

- ordinary safe views and `export_report` never contain plaintext, Vault UUIDs, or fingerprints;
- normalized exact-equivalent values produce the same HMAC fingerprint;
- create and rotate update masked hints and private references atomically;
- reveal works for an active Admin, fails for User/inactive Admin, requires a caller-supplied correlation ID, and writes an audit row without the revealed value;
- an injected failure rolls back the entitlement and its secret-reference row.

- [ ] **Step 4: Implement Master Data, Settings, notification state, and audited Report commands**

`update_master_data` and `archive_master_data` accept only the entity values listed in the migration, such as `publisher`, `vendor`, `department`, `location`, `purchase_form`, and `software_category`. Use a `case` statement; unknown values raise `INVALID_MASTER_ENTITY`.

`set_notification_state` must update only the authenticated recipient row:

```sql
update public.notification_recipients
set is_read = requested_is_read,
    read_at = case when requested_is_read then now() else null end,
    is_dismissed = requested_is_dismissed,
    dismissed_at = case when requested_is_dismissed then now() else null end
where id = recipient_id and profile_id = auth.uid()
returning * into result;
```

`update_system_settings` validates policy enums and uses the singleton row version for optimistic locking. `export_report` accepts an explicit report-type allowlist, selects only safe-view fields, applies allowlisted filters, records an `export` audit event, and returns JSONB rows without License secrets.

- [ ] **Step 5: Verify grants, RLS, audit redaction, and GREEN**

Run:

```bash
npx supabase db reset --local
npx supabase test db
npx supabase db lint --local --level warning --fail-on warning
```

Expected: all tests pass; lint reports no schema errors; pgTAP confirms audit JSON lacks secret values and that `anon`/direct authenticated SQL cannot read `vault.decrypted_secrets` or `private.license_secrets`.

- [ ] **Step 6: Commit the license/admin command slice**

```bash
git add supabase/migrations/202609020003_license_admin_reporting_commands.sql supabase/tests/database
git commit -m "feat: add license and admin commands"
```

---

### Task 3: Generated Types and Database Contract Verification

**Files:**
- Modify: `src/lib/supabase/database.types.ts`
- Modify: `package.json`

**Interfaces:**
- Consumes: all RPC signatures from Tasks 1–2.
- Produces: generated `Database` types containing the new public functions and row versions for application plans.

- [ ] **Step 1: Generate types from the verified local schema**

Run: `npm run db:types`

Expected: `src/lib/supabase/database.types.ts` changes and contains `update_asset`, `archive_software_product`, `create_license_entitlement`, `rotate_license_secret`, `reveal_license_secret`, `update_license_entitlement`, `set_notification_state`, `update_system_settings`, and `export_report`.

- [ ] **Step 2: Add a repeatable database verification script**

Add this exact script:

```json
"db:verify": "npm run db:reset && npm run db:test && npm run db:lint && npm run db:types"
```

- [ ] **Step 3: Run the complete database contract verification**

Run: `npm run db:verify && npx tsc --noEmit`

Expected: exit 0 with all pgTAP tests passing and TypeScript accepting the generated types.

- [ ] **Step 4: Commit generated contracts**

```bash
git add package.json src/lib/supabase/database.types.ts
git commit -m "chore: generate live command database types"
```

---

### Task 4: Database Plan Checkpoint

**Files:**
- No production file changes expected.

**Interfaces:**
- Produces: a reviewed local database foundation ready for the application plan.

- [ ] **Step 1: Run final evidence commands**

Run:

```bash
npm run db:verify
git status --short
git log -3 --oneline
```

Expected: database reset/test/lint/type generation pass; working tree is clean.

- [ ] **Step 2: Review mutation coverage against the spec action matrix**

Confirm each action has exactly one RPC boundary, direct table grants remain revoked, every state transition has a reason, and every Admin mutation writes audit data.

- [ ] **Step 3: Stop for checkpoint review**

Do not link or push hosted migrations in this plan. Hosted deployment occurs only in `2026-09-02-hosted-publish-verification-plan.md` after application and migration review plans pass locally.
