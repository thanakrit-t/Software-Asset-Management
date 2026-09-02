# Hosted Migration Publish and Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the atomic migration Publish boundary, deploy all verified changes to hosted Supabase, stage the approved workbooks, obtain an explicit reconciliation approval, Publish once, and verify the hosted system.

**Architecture:** Publish is a single Admin-checked PostgreSQL transaction that locks a validated batch, resolves approved exact mappings, writes production records with source traceability, records reconciliation/audit output, and prevents reuse of source fingerprints. Deployment uses local verification and hosted dry-runs before any remote mutation.

**Tech Stack:** Supabase CLI/PostgreSQL, pgTAP, Next.js 16 Server Actions, TypeScript/Vitest, hosted Supabase project `kqyhijptsvjoivyencgk`

**Spec:** `docs/superpowers/specs/2026-09-02-live-crud-excel-migration-design.md`

## Global Constraints

- Complete and review the database, application, and Excel staging plans first.
- Never print `.env.local`, Service Role keys, database passwords, Serial Numbers, or License Keys.
- Never run `supabase db reset --linked`.
- Remote schema changes require `migration list`, `db push --dry-run`, and a backup/export checkpoint first.
- Real workbook staging must stop for human reconciliation review before Publish.
- Publish runs once for the approved fingerprints and rolls back completely on any error.
- Archived records and audit history are never hard-deleted.

---

### Task 1: Atomic Publish RPC

**Files:**
- Create: `supabase/migrations/202609020005_migration_publish_rpc.sql`
- Modify: `supabase/tests/database/004_migration_review.test.sql`

**Interfaces:**
- Consumes: validated/acknowledged batch data from the staging plan and production command constraints from the database plan.
- Produces: `publish_import_batch(uuid, integer, boolean): public.import_publish_summary`.

- [ ] **Step 1: Write failing pgTAP tests for every Publish gate**

```sql
select throws_ok(
  $$ select public.publish_import_batch(
    current_setting('test.batch_with_errors')::uuid, 1, false
  ) $$,
  'P0001', 'IMPORT_HAS_ERRORS',
  'batch with errors cannot publish'
);

select throws_ok(
  $$ select public.publish_import_batch(
    current_setting('test.batch_with_warnings')::uuid, 1, false
  ) $$,
  'P0001', 'WARNINGS_NOT_ACKNOWLEDGED',
  'warnings require explicit acknowledgement'
);

select lives_ok(
  $$ select public.publish_import_batch(
    current_setting('test.valid_batch')::uuid, 1, true
  ) $$,
  'valid Admin-approved batch publishes'
);

select throws_ok(
  $$ select public.publish_import_batch(
    current_setting('test.valid_batch')::uuid, 2, true
  ) $$,
  'P0001', 'IMPORT_ALREADY_PUBLISHED',
  'committed fingerprints cannot publish twice'
);
```

Add assertions that production rows retain `migration_batch_id`/source-row IDs, reconciliation totals equal fixture totals, an audit event exists, and a forced late failure leaves zero production rows from the batch.

- [ ] **Step 2: Run the migration test and verify RED**

Run: `npx supabase test db supabase/tests/database/004_migration_review.test.sql`

Expected: FAIL because `publish_import_batch` and its summary type do not exist.

- [ ] **Step 3: Implement locking and precondition gates**

```sql
select * into batch
from migration.import_batches
where id = import_batch_id
for update;

if batch.status = 'committed' then
  raise exception using errcode = 'P0001', message = 'IMPORT_ALREADY_PUBLISHED';
end if;
if batch.version <> expected_version then
  raise exception using errcode = '40001', message = 'VERSION_CONFLICT';
end if;
if exists (
  select 1 from migration.row_results
  where import_batch_id = batch.id and result_status = 'error'
) then
  raise exception using errcode = 'P0001', message = 'IMPORT_HAS_ERRORS';
end if;
```

Verify Admin status, source fingerprints, warning acknowledgement, and approved mapping rules before inserting any production row.

- [ ] **Step 4: Implement deterministic production writes**

Publish in dependency order: Sites/master matches → Publishers/Vendors → Software Products → Assets/network/assignments → installed software → License Entitlements/private secret references → resolvable Allocations → reconciliation → audit → batch status.

Use `on conflict` only on the exact approved business keys. Do not use fuzzy normalization or silently merge conflicting source rows. Mark unresolved warning rows skipped and include them in summary totals.

- [ ] **Step 5: Return a sanitized summary and lock grants**

```sql
create type public.import_publish_summary as (
  import_batch_id uuid,
  assets_created integer,
  products_created integer,
  licenses_created integer,
  allocations_created integer,
  duplicate_rows_skipped integer,
  warning_rows_skipped integer,
  audit_event_id uuid
);
```

Revoke Public/Anon execution and grant Authenticated execution; the function still enforces Admin internally.

- [ ] **Step 6: Verify GREEN and commit**

Run:

```bash
npx supabase db reset --local
npx supabase test db
npx supabase db lint --local --level warning --fail-on warning
npm run db:types
```

Expected: all tests pass, lint is clean, generated types include the Publish RPC.

```bash
git add supabase/migrations/202609020005_migration_publish_rpc.sql supabase/tests/database/004_migration_review.test.sql src/lib/supabase/database.types.ts
git commit -m "feat: publish validated migration batches"
```

---

### Task 2: Enable Admin Publish Action

**Files:**
- Modify: `src/features/migration/actions.ts`
- Modify: `src/features/migration/actions.test.ts`
- Modify: `src/features/migration/migration-review-view.tsx`
- Modify: `src/features/migration/migration-review-view.test.tsx`

**Interfaces:**
- Consumes: typed `publish_import_batch` RPC.
- Produces: `publishImportBatch(previousState, formData): Promise<MutationState>` and an enabled confirmation flow only for eligible batches.

- [ ] **Step 1: Write failing Publish eligibility/action tests**

Assert Publish is disabled for errors, disabled for unacknowledged warnings, enabled for an eligible Admin batch, requires typing the batch confirmation phrase, passes `expected_version`, and revalidates operational paths only after success.

- [ ] **Step 2: Verify RED**

Run: `npx vitest run src/features/migration --maxWorkers=1`

Expected: FAIL because Publish is still deliberately disabled.

- [ ] **Step 3: Implement the Server Action**

```ts
const { data, error } = await client.rpc("publish_import_batch", {
  import_batch_id: batchId,
  expected_version: version,
  acknowledge_warnings: formData.get("acknowledgeWarnings") === "true",
});
if (error) return mapSupabaseCommandError(error);
for (const path of ["/migration-review", "/", "/assets", "/software", "/licenses", "/allocations", "/reports"]) {
  revalidatePath(path);
}
return { status: "success", message: `Publish สำเร็จ ${data.assets_created} Assets` };
```

- [ ] **Step 4: Implement double confirmation and sanitized summary**

Show exact record counts and skipped rows, never secret values. Require the phrase `PUBLISH <short-batch-id>` before enabling the final submit button.

- [ ] **Step 5: Verify GREEN and commit**

```bash
npx vitest run src/features/migration --maxWorkers=1
git add src/features/migration
git commit -m "feat: enable approved migration publish"
```

---

### Task 3: Full Local Release Verification

**Files:**
- Modify only focused files needed to fix failures introduced by the complete feature.

**Interfaces:**
- Produces: release evidence before remote deployment.

- [ ] **Step 1: Verify database from a clean local reset**

Run: `npm run db:verify`

Expected: reset, all pgTAP tests, lint, and type generation pass.

- [ ] **Step 2: Verify all application and parser tests sequentially**

Run: `npx vitest run --maxWorkers=1`

Expected: all tests pass with zero timeout failures.

- [ ] **Step 3: Verify lint and production build**

Run:

```bash
npm run lint
npm run build
```

Expected: exit 0 and all App Router routes build.

- [ ] **Step 4: Run real-workbook dry-run without writes**

Run: `npm run migration:stage -- --dry-run`

Expected: both approved fingerprints and sanitized counts; no database batch created; no plaintext secret output.

- [ ] **Step 5: Review Git state and stop if dirty for unrelated reasons**

Run: `git status --short --branch`

Expected: only deliberate focused changes. Preserve unrelated user edits and do not overwrite them.

---

### Task 4: Hosted Backup, Dry-Run, and Schema Deployment

**Files:**
- Create locally only: `backups/hosted-pre-crud-$samBackupStamp-schema.sql`
- Create locally only: `backups/hosted-pre-crud-$samBackupStamp-data.sql` (both ignored, never commit, never print contents).
- Modify: `.gitignore`

**Interfaces:**
- Produces: hosted schema matching locally verified migrations without publishing Excel rows.

- [ ] **Step 1: Confirm the linked project and migration baseline**

Run:

```bash
npx supabase projects list
npx supabase migration list --linked
```

Expected: linked project ref is exactly `kqyhijptsvjoivyencgk`; local/remote history matches through `202609020001` before new deployment.

- [ ] **Step 2: Export a hosted pre-change backup**

Add `backups/` to `.gitignore`, create that directory, and run both linked dumps with one generated timestamp:

```powershell
New-Item -ItemType Directory -Force -Path 'backups'
$samBackupStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
npx supabase db dump --linked --file "backups/hosted-pre-crud-$samBackupStamp-schema.sql"
npx supabase db dump --linked --data-only --use-copy --file "backups/hosted-pre-crud-$samBackupStamp-data.sql"
Get-Item "backups/hosted-pre-crud-$samBackupStamp-schema.sql", "backups/hosted-pre-crud-$samBackupStamp-data.sql" | Select-Object Name,Length
```

Expected: both files exist and have `Length` greater than zero; the command output contains no dumped row content. If the plan/account cannot produce both usable files, stop and report the blocker before pushing.

- [ ] **Step 3: Run hosted dry-run**

Run: `npx supabase db push --linked --dry-run`

Expected: only the reviewed new migrations `202609020002` through `202609020005` are listed.

- [ ] **Step 4: Push schema migrations**

Run: `npx supabase db push --linked`

Expected: every migration applies once with no partial failure.

- [ ] **Step 5: Verify hosted schema**

Run:

```bash
npx supabase migration list --linked
npx supabase db lint --linked --level warning
```

Expected: local/remote migration histories match and hosted lint has no schema errors.

Do not stage or Publish workbook data in this task.

---

### Task 5: Stage Real Workbooks and Review Reconciliation

**Files:**
- No committed source changes expected.

**Interfaces:**
- Produces: one hosted staged batch and a human-readable sanitized reconciliation checkpoint.

- [ ] **Step 1: Run live staging once**

Run: `npm run migration:stage`

Expected: one batch ID, both approved SHA-256 fingerprints, and sanitized counts. Capture no secret values in terminal logs.

- [ ] **Step 2: Open the Admin Migration Review screen**

Run the production build locally against hosted Supabase and open `/migration-review` as an Admin. Verify batch status, source files, row counts, site mappings, validation severities, and masked secret hints.

- [ ] **Step 3: Reconcile source and staged totals**

Check at minimum:

- Asset source rows by Factory/Bangkok Office.
- Unique exact Asset business keys and duplicate count.
- Unique Software Product exact keys.
- Factory/Office License detail row totals.
- Owned and Used totals against Summary Factory/Office.
- Error, warning, duplicate, and skipped counts.
- No plaintext secrets in UI, database staging JSON, audit output, or terminal logs.

- [ ] **Step 4: Resolve mappings and revalidate**

Apply approved mapping rules through the review UI, rerun `validate_import_batch`, and repeat reconciliation until error count is zero. Warnings remain visible and require explicit acknowledgement.

- [ ] **Step 5: Stop for explicit human Publish approval**

Report the batch ID, source fingerprints, reconciliation table, exact duplicate count, warning count, and rows planned for creation/skip. Do not call `publish_import_batch` until the user explicitly approves these concrete totals.

---

### Task 6: Publish Once and Verify Hosted Data

**Files:**
- No committed source changes expected unless verification finds a reproducible bug, which must begin with a failing test.

**Interfaces:**
- Consumes: explicit human approval from Task 5.
- Produces: hosted operational data from a batch whose database status is `committed`, plus final release evidence.

- [ ] **Step 1: Publish from the Admin confirmation Dialog**

Enter the required batch phrase and submit once. If the response is ambiguous because of a network error, query batch status before any retry; never blindly submit twice.

- [ ] **Step 2: Verify Publish summary and idempotency**

Confirm batch status is `committed`, summary totals match the approved checkpoint, and a second Publish attempt returns `IMPORT_ALREADY_PUBLISHED` without changing counts.

- [ ] **Step 3: Verify hosted operational surfaces**

As Admin, verify Assets, Software, Licenses, Allocations, Dashboard, Reports, and Audit Logs read hosted data. Exercise one Edit and one reversible state transition only on an approved test record; do not Archive production records merely for testing.

- [ ] **Step 4: Verify User RLS and action visibility**

As a regular User, verify safe lists/reports load, Admin actions are absent, and a direct administrative RPC probe returns `ACCESS_DENIED`.

- [ ] **Step 5: Run final automated evidence**

Run:

```bash
npx vitest run --maxWorkers=1
npm run lint
npm run build
npx supabase migration list --linked
npx supabase db lint --linked --level warning
git status --short --branch
```

Expected: tests/lint/build pass, migration history matches, hosted lint is clean, and the working tree contains no accidental secrets or generated migration output.

- [ ] **Step 6: Finalize the development branch**

Invoke `superpowers:finishing-a-development-branch`, present merge/push/PR choices, and include the approved reconciliation plus post-Publish verification in the handoff. Do not claim completion without the fresh evidence from Step 5.
