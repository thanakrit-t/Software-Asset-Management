# Excel Staging and Migration Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parse the two approved Excel workbooks into protected migration staging, validate exact duplicates and mapping errors, and let an Admin review reconciliation before Publish.

**Architecture:** A one-time Node/TypeScript CLI reads workbook structures with ExcelJS, normalizes rows through sheet-specific adapters, and sends bounded batches to security-definer staging RPCs using server-only credentials. The web application reads sanitized review DTOs through Admin-checked RPCs; it never parses uploaded workbooks or exposes migration tables.

**Tech Stack:** Node.js, TypeScript, ExcelJS, SHA-256/HMAC, Supabase JS, PostgreSQL migration schema, Next.js 16 App Router, Vitest, pgTAP

**Spec:** `docs/superpowers/specs/2026-09-02-live-crud-excel-migration-design.md`

## Global Constraints

- Complete the database and application plans first.
- Source workbooks are read-only and are not rewritten or exported.
- Duplicate detection is exact match only.
- Serial/License Key plaintext may exist only in CLI memory and the dedicated private-secret command; never in staging raw JSON, validation output, logs, fixtures, or audit events.
- Migration schema is not exposed through the Data API.
- The browser has no upload/import feature; the bundled approved files are staged once by CLI.
- Publish is not implemented in this plan; it remains disabled until the hosted publish plan.
- Never run `supabase db reset --linked`.

---

### Task 1: Protected Staging and Review RPCs

**Files:**
- Create: `supabase/migrations/202609020004_migration_staging_review_rpc.sql`
- Create: `supabase/tests/database/004_migration_review.test.sql`

**Interfaces:**
- Consumes: existing `migration.import_batches`, `source_files`, staging rows, row results, mapping rules, and reconciliation tables.
- Produces: `begin_import_batch(jsonb)`, `stage_asset_rows(uuid, jsonb)`, `stage_license_rows(uuid, jsonb)`, `validate_import_batch(uuid)`, `get_import_batch_review(uuid)`, and `acknowledge_import_warnings(uuid, integer)`.

- [ ] **Step 1: Write failing pgTAP tests for access and secret rejection**

```sql
select throws_ok(
  $$ select public.get_import_batch_review(gen_random_uuid()) $$,
  '42501', 'ACCESS_DENIED',
  'regular user cannot read migration review data'
);

select throws_ok(
  $$ select public.stage_license_rows(
    current_setting('test.batch_id')::uuid,
    '[{"raw_data":{"Serial No.":"PLAIN-TEXT"}}]'::jsonb
  ) $$,
  '22023', 'PLAINTEXT_SECRET_REJECTED',
  'staging rejects secret-like raw JSON keys'
);

select is(
  (public.validate_import_batch(current_setting('test.batch_id')::uuid)).error_count,
  0,
  'valid fixture batch has no errors'
);
```

- [ ] **Step 2: Run the new database test and verify RED**

Run: `npx supabase test db supabase/tests/database/004_migration_review.test.sql`

Expected: FAIL because the six functions do not exist.

- [ ] **Step 3: Implement server/service staging boundaries**

`begin_import_batch` accepts only the two approved source descriptors and rejects a fingerprint attached to an existing `committed` batch. `stage_*_rows` limits each JSON array to 100 rows, accepts only `draft`/`extracted` batches, advances the status to `extracted`, and rejects case-insensitive keys matching `serial`, `license_key`, `product_key`, or `os_key` inside `raw_data`.

Use typed result objects:

```sql
alter table migration.import_batches
  add column version integer not null default 1;
alter table migration.import_batches
  add constraint import_batches_version_ck check (version > 0);

create type public.import_validation_summary as (
  import_batch_id uuid,
  valid_count integer,
  warning_count integer,
  error_count integer,
  duplicate_count integer,
  skipped_count integer,
  version integer
);
```

- [ ] **Step 4: Implement validation and exact-match rules**

Insert deterministic `migration.row_results` entries for missing keys, invalid dates/quantities, ambiguous mappings, and duplicate business keys. Use `result_status = 'error'` for blocking rows, non-empty `warnings` arrays for warning rows, and `result_status = 'skipped'` plus `decision_reason = 'DUPLICATE_EXACT'` for duplicates. Re-running validation replaces results for the batch inside one transaction. Every status/approval mutation increments `import_batches.version`.

- [ ] **Step 5: Implement sanitized Admin review DTOs**

`get_import_batch_review` returns batch summary, reconciliation totals, and paged sanitized row details. It returns `secret_masked_hint` and `secret_fingerprint`, never a secret value.

- [ ] **Step 6: Verify GREEN, lint, and commit**

Run:

```bash
npx supabase db reset --local
npx supabase test db
npx supabase db lint --local --level warning --fail-on warning
```

Expected: all pgTAP files pass and lint reports no schema errors.

```bash
git add supabase/migrations/202609020004_migration_staging_review_rpc.sql supabase/tests/database/004_migration_review.test.sql
git commit -m "feat: add protected migration staging review"
```

---

### Task 2: Parser Primitives and Exact Duplicate Detection

**Files:**
- Modify: `package.json`
- Modify: `package-lock.json`
- Create: `scripts/migration/types.ts`
- Create: `scripts/migration/cell-values.ts`
- Create: `scripts/migration/fingerprint.ts`
- Create: `scripts/migration/exact-duplicates.ts`
- Create: `scripts/migration/parser-primitives.test.ts`

**Interfaces:**
- Produces: `cellText(cell)`, `cellDate(cell)`, `cellNumber(cell)`, `sha256File(path)`, `exactBusinessKey(parts)`, and `findExactDuplicates(rows, keyOf)`.

- [ ] **Step 1: Install pinned parser tooling**

Run: `npm install --save-dev exceljs tsx`

Use ExcelJS through its documented `Workbook.xlsx.readFile()` API. Do not use streaming mode because the source adapters need merged-cell context.

- [ ] **Step 2: Write failing primitive tests**

```ts
test("uses a formula result without evaluating workbook formulas", () => {
  expect(cellText({ formula: "A1+B1", result: 3 })).toBe("3");
});

test("exact duplicate keys preserve case and internal whitespace", () => {
  expect(exactBusinessKey(["Microsoft", "Office 365", ""])).toBe("Microsoft\u001fOffice 365\u001f");
  expect(exactBusinessKey(["Microsoft", "office 365", ""])).not.toBe(
    exactBusinessKey(["Microsoft", "Office 365", ""]),
  );
});

test("file fingerprint is stable and content based", async () => {
  expect(await sha256File(fixturePath)).toMatch(/^[a-f0-9]{64}$/);
});
```

- [ ] **Step 3: Run tests and verify RED**

Run: `npx vitest run scripts/migration/parser-primitives.test.ts --maxWorkers=1`

Expected: FAIL because the parser modules do not exist.

- [ ] **Step 4: Implement minimal pure primitives**

```ts
export function exactBusinessKey(parts: readonly unknown[]): string {
  return parts.map((part) => part == null ? "" : String(part)).join("\u001f");
}

export function safeFormulaValue(value: ExcelJS.CellValue): unknown {
  if (value && typeof value === "object" && "formula" in value) return value.result ?? null;
  return value;
}
```

The exact-match function must not lowercase, trim internal whitespace, or apply fuzzy matching. Individual adapters may convert typed Excel cells to stable strings but must retain a `sourceValue` alongside normalized output.

- [ ] **Step 5: Verify GREEN and commit**

Run focused tests; expected PASS.

```bash
git add package.json package-lock.json scripts/migration
git commit -m "feat: add Excel migration parser primitives"
```

---

### Task 3: Asset Workbook Adapters

**Files:**
- Create: `scripts/migration/asset-workbook.ts`
- Create: `scripts/migration/asset-workbook.test.ts`
- Create: `scripts/migration/test-workbooks.ts`

**Interfaces:**
- Consumes: parser primitives from Task 2.
- Produces: `parseAssetWorkbook(path): Promise<ParsedAssetWorkbook>` containing source coordinates, sites, assets, network data, people assignments, and installed-software observations.

- [ ] **Step 1: Generate a minimal in-memory Factory/Office fixture in the test**

Use ExcelJS to create a temporary workbook with merged multi-row headers, one formula-result cell, one PC row, one NB row, network values, and software-presence columns. Use invented values only.

- [ ] **Step 2: Write failing adapter assertions**

```ts
expect(result.assets).toEqual([
  expect.objectContaining({ siteCode: "factory", assetType: "pc", sourceRow: 7 }),
  expect.objectContaining({ siteCode: "bangkok-office", assetType: "notebook" }),
]);
expect(result.installedSoftware).toContainEqual(
  expect.objectContaining({ productLabel: "Microsoft Office 365", present: true }),
);
```

- [ ] **Step 3: Run the adapter test and verify RED**

Run: `npx vitest run scripts/migration/asset-workbook.test.ts --maxWorkers=1`

Expected: FAIL because `parseAssetWorkbook` does not exist.

- [ ] **Step 4: Implement two explicit sheet adapters**

Define exact sheet-name aliases and header coordinates for `Software(Factory)` and `Software(Bangkok Offic)`. Propagate merged header master values where needed; ignore pure totals/notes rows; keep `sheetName`, `sourceRow`, and cell coordinates on every emitted record.

- [ ] **Step 5: Add malformed-row tests and verify GREEN**

Assert missing Asset business keys become parser issues rather than silently disappearing. Run focused tests; expected PASS.

- [ ] **Step 6: Commit the Asset adapters**

```bash
git add scripts/migration/asset-workbook.ts scripts/migration/asset-workbook.test.ts scripts/migration/test-workbooks.ts
git commit -m "feat: parse asset inventory workbooks"
```

---

### Task 4: License Workbook Adapter and Secret Redaction

**Files:**
- Create: `scripts/migration/license-workbook.ts`
- Create: `scripts/migration/license-workbook.test.ts`
- Modify: `scripts/migration/test-workbooks.ts`

**Interfaces:**
- Produces: `parseLicenseWorkbook(path, secretFingerprinter): Promise<ParsedLicenseWorkbook>` with sanitized rows plus an in-memory `SecretEnvelope[]` that is never serialized to logs.

- [ ] **Step 1: Write a fixture with invented Serial values and summary totals**

Include Factory/Office detail sheets, one exact duplicate, dates, quantities, and summary sheets. Use a fake value such as `TEST-SERIAL-DO-NOT-USE`.

- [ ] **Step 2: Write failing redaction and mapping tests**

```ts
expect(JSON.stringify(result.stagingRows)).not.toContain("TEST-SERIAL-DO-NOT-USE");
expect(result.secrets[0]).toMatchObject({ maskedHint: "••••-USE" });
expect(result.stagingRows[0]).toMatchObject({
  normalizedPublisher: "Example Maker",
  normalizedOwnedQuantity: 5,
  sourceSheet: "Software License FACTORY",
});
```

- [ ] **Step 3: Verify RED**

Run: `npx vitest run scripts/migration/license-workbook.test.ts --maxWorkers=1`

Expected: FAIL because the License adapter does not exist.

- [ ] **Step 4: Implement detail and summary adapters**

Read header row 8 for detail sheets. Treat Summary Factory/Office only as reconciliation data. Date conversion must preserve Excel date meaning and emit ISO `yyyy-mm-dd`; non-date text becomes a validation issue instead of an inferred date.

- [ ] **Step 5: Verify no-secret serialization and GREEN**

Run focused tests and an `rg` scan of committed fixtures for the invented serial. Expected: tests pass; no generated output file contains plaintext secret values.

- [ ] **Step 6: Commit the License adapter**

```bash
git add scripts/migration/license-workbook.ts scripts/migration/license-workbook.test.ts scripts/migration/test-workbooks.ts
git commit -m "feat: parse license migration workbook"
```

---

### Task 5: One-Time Staging CLI

**Files:**
- Create: `scripts/migration/stage-approved-workbooks.ts`
- Create: `scripts/migration/stage-approved-workbooks.test.ts`
- Modify: `package.json`
- Modify: `.env.example`

**Interfaces:**
- Consumes: both adapters and staging RPCs.
- Produces: `npm run migration:stage -- --dry-run` and `npm run migration:stage` commands; prints only counts, fingerprints, batch ID, and sanitized issues.

- [ ] **Step 1: Write a failing orchestration test with a fake staging gateway**

Assert dry-run parses/validates without RPC writes, live mode sends chunks of at most 100 rows, secrets go only to the dedicated secret parameter, and console output never contains secret plaintext.

- [ ] **Step 2: Verify RED**

Run: `npx vitest run scripts/migration/stage-approved-workbooks.test.ts --maxWorkers=1`

Expected: FAIL because the CLI orchestrator does not exist.

- [ ] **Step 3: Implement explicit approved-file constants and gateway**

```ts
const APPROVED_FILES = {
  assets: "02 203Total License(TKC) Update 2026-08-28.xlsx",
  licenses: "03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx",
} as const;
```

Read `NEXT_PUBLIC_SUPABASE_URL` and server-only `SUPABASE_SERVICE_ROLE_KEY`. Fail closed when either file name/fingerprint is missing. Add scripts:

```json
"migration:stage": "tsx scripts/migration/stage-approved-workbooks.ts"
```

Do not add the Service Role key value to `.env.example`; document only its variable name and server/CLI-only purpose.

- [ ] **Step 4: Verify dry-run against copies of the real workbooks**

Run: `npm run migration:stage -- --dry-run`

Expected: sanitized counts for both workbooks, no database write, no plaintext secret output.

- [ ] **Step 5: Verify tests and commit**

```bash
npx vitest run scripts/migration --maxWorkers=1
git add scripts/migration package.json package-lock.json .env.example
git commit -m "feat: add approved workbook staging CLI"
```

---

### Task 6: Admin Migration Review Screen

**Files:**
- Create: `src/features/migration/types.ts`
- Create: `src/features/migration/repository.ts`
- Create: `src/features/migration/repository.test.ts`
- Create: `src/features/migration/migration-review-view.tsx`
- Create: `src/features/migration/migration-review-view.test.tsx`
- Create: `src/features/migration/actions.ts`
- Create: `src/features/migration/actions.test.ts`
- Create: `src/app/(protected)/(admin)/migration-review/page.tsx`
- Modify: `src/components/app-shell/sidebar.tsx`
- Modify: `src/components/app-shell/sidebar.test.tsx`

**Interfaces:**
- Consumes: sanitized review RPCs from Task 1.
- Produces: Admin route `/migration-review`, row filters, warning acknowledgement, and a disabled Publish control that the hosted publish plan activates.

- [ ] **Step 1: Write failing navigation and review-state tests**

Assert Admin sees `ตรวจสอบการย้ายข้อมูล`, User does not, summary cards render literal counts, secret hints are masked, and Publish stays disabled when errors exist or warnings are unacknowledged.

- [ ] **Step 2: Verify RED**

Run focused Sidebar/Migration tests. Expected: FAIL with missing route/components.

- [ ] **Step 3: Implement typed review repository and page**

Server page loads the latest staged batch through `get_import_batch_review`; filters are URL search params; row detail displays source sheet/row, normalized values, the derived display category from `result_status` plus `errors`/`warnings`, and sanitized issue messages.

- [ ] **Step 4: Implement warning acknowledgement only**

The action sends batch ID and expected version, maps version conflicts, and revalidates `/migration-review`. Render Publish as disabled with copy `เปิดใช้งานหลังผ่าน Hosted Publish checkpoint`.

- [ ] **Step 5: Verify full plan and commit**

Run:

```bash
npx vitest run scripts/migration src/features/migration src/components/app-shell/sidebar.test.tsx --maxWorkers=1
npm run lint
npm run build
```

Expected: all pass.

```bash
git add src/features/migration "src/app/(protected)/(admin)/migration-review" src/components/app-shell
git commit -m "feat: add migration review workspace"
```

- [ ] **Step 6: Stop for reconciliation review**

Do not stage the real files against hosted Supabase or enable Publish in this plan. Continue with `2026-09-02-hosted-publish-verification-plan.md` only after local tests and dry-run counts are reviewed.
