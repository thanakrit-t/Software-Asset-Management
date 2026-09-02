# Live Supabase Repository and CRUD UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all operational mock reads with hosted-compatible Supabase reads and expose the approved role-aware action menus backed by real Server Actions.

**Architecture:** Server Components read through `SupabaseSamRepository`; Client Components submit forms to feature-local Server Actions; Server Actions call the typed RPCs created by the database plan and revalidate affected paths. Shared action-menu/dialog primitives provide consistent UX without creating a generic CRUD engine.

**Tech Stack:** Next.js 16 App Router, React 19, TypeScript, Tailwind CSS 4, Supabase SSR/JS, Vitest, Testing Library

**Spec:** `docs/superpowers/specs/2026-09-02-live-crud-excel-migration-design.md`

## Global Constraints

- Complete `docs/superpowers/plans/2026-09-02-live-crud-database-plan.md` first.
- Read the relevant installed guides in `node_modules/next/dist/docs/` before modifying Server Actions, Server Components, caching, or forms.
- Hosted Supabase is the only operational data source; no application page imports `mockSamRepository` when this plan finishes.
- Hide Admin actions from Users, but rely on database RPC authorization as the final boundary.
- Use Archive, Release, and Deactivate language; no hard-delete UI.
- Preserve secret masking and never place Service Role credentials in application code.
- Every task follows RED → GREEN → refactor and commits only its focused slice.

---

### Task 1: Domain Types and Supabase Read Repository

**Files:**
- Modify: `src/features/sam/types.ts`
- Modify: `src/features/sam/repository.ts`
- Create: `src/features/sam/supabase-mappers.ts`
- Create: `src/features/sam/supabase-mappers.test.ts`
- Create: `src/features/sam/supabase-repository.ts`
- Create: `src/features/sam/supabase-repository.test.ts`

**Interfaces:**
- Consumes: generated `Database` types and security-invoker views from the database plan.
- Produces: `createSupabaseSamRepository(client): SamRepository`; domain records containing `version`, `archivedAt`, and safe License fields.

- [ ] **Step 1: Write failing mapper tests with literal database fixtures**

```ts
test("maps an asset inventory row without losing optimistic-lock state", () => {
  expect(mapAssetRow({
    id: "asset-1",
    asset_code: "TKC-001",
    computer_name: "TKC-PC-001",
    asset_type_code: "pc",
    asset_status_code: "active",
    site_id: "site-1",
    site_name: "Factory",
    site_code: "FAC",
    version: 4,
    archived_at: null,
  })).toMatchObject({
    id: "asset-1",
    assetCode: "TKC-001",
    computerName: "TKC-PC-001",
    version: 4,
    archivedAt: undefined,
  });
});
```

Name the mutation this catches: dropping `version` would make every Edit/Archive action send stale or missing locking state.

- [ ] **Step 2: Run mapper tests and verify RED**

Run: `npx vitest run src/features/sam/supabase-mappers.test.ts --maxWorkers=1`

Expected: FAIL because `mapAssetRow` and the new domain fields do not exist.

- [ ] **Step 3: Add explicit domain fields and pure mappers**

Change `Site.id` from the mock-only literal union to `string`, add `version: number` and `archivedAt?: string` to mutable domain entities, and align Allocation targets to the database union `"asset" | "person" | "site"`. Remove `licenseKey` and `serialNumber` from ordinary `LicenseEntitlement`; secret reveal remains a separate response type.

```ts
export interface SecretReveal {
  value: string;
  revealedAt: string;
  correlationId: string;
}

export function mapAssetRow(row: AssetInventoryRow): Asset {
  return {
    id: row.id,
    assetCode: row.asset_code,
    computerName: row.computer_name,
    type: row.asset_type_code,
    status: row.asset_status_code,
    site: { id: row.site_id, name: row.site_name, shortName: row.site_code },
    version: row.version,
    archivedAt: row.archived_at ?? undefined,
    department: row.department_name ?? undefined,
    location: row.location_name ?? undefined,
    assignedTo: row.assigned_person_name ?? undefined,
  };
}
```

- [ ] **Step 4: Write failing repository query tests**

Create a typed fake client response and assert `.select()` targets safe views, filters archived rows by default, and returns mapper output. Do not assert only on mock call count; assert returned domain records and query filters.

- [ ] **Step 5: Implement the repository factory**

```ts
export function createSupabaseSamRepository(
  client: SupabaseClient<Database>,
): SamRepository {
  return {
    async listAssets(filters = {}) {
      let query = client.from("asset_inventory_v").select("*").is("archived_at", null);
      if (filters.siteId && filters.siteId !== "all") query = query.eq("site_id", filters.siteId);
      const { data, error } = await query;
      if (error) throw new SamRepositoryError("ASSET_READ_FAILED", error);
      return data.map(mapAssetRow);
    },
    // Implement every SamRepository method with the matching safe surface.
  };
}
```

- [ ] **Step 6: Verify repository tests and commit**

Run: `npx vitest run src/features/sam/supabase-mappers.test.ts src/features/sam/supabase-repository.test.ts --maxWorkers=1`

Expected: PASS.

```bash
git add src/features/sam
git commit -m "feat: add Supabase SAM repository"
```

---

### Task 2: Switch Server Components from Mock to Supabase

**Files:**
- Create: `src/features/sam/server-repository.ts`
- Modify: `src/app/(protected)/page.tsx`
- Modify: `src/app/(protected)/assets/page.tsx`
- Modify: `src/app/(protected)/assets/[id]/page.tsx`
- Modify: `src/app/(protected)/software/page.tsx`
- Modify: `src/app/(protected)/licenses/page.tsx`
- Modify: `src/app/(protected)/licenses/[id]/page.tsx`
- Modify: `src/app/(protected)/allocations/page.tsx`
- Modify: `src/app/(protected)/notifications/page.tsx`
- Modify: `src/app/(protected)/(admin)/audit-logs/page.tsx`
- Modify: `src/app/(protected)/(admin)/users/page.tsx`
- Modify: affected page tests under `src/app/`

**Interfaces:**
- Consumes: `createSupabaseSamRepository(client)` from Task 1 and `createServerSupabaseClient()`.
- Produces: `getServerSamRepository(): Promise<SamRepository>` used by every Server Component.

- [ ] **Step 1: Write a failing protected-page test**

Mock `getServerSamRepository`, not Supabase internals, and verify returned live fixtures render. Also add a source-boundary test that imports each page and would fail if `mockSamRepository` is required by a protected route.

```ts
vi.mock("@/features/sam/server-repository", () => ({
  getServerSamRepository: vi.fn(),
}));
```

- [ ] **Step 2: Verify RED**

Run: `npx vitest run src/app/(protected)/page.test.tsx --maxWorkers=1`

Expected: FAIL because `server-repository.ts` does not exist and the page still imports the mock repository.

- [ ] **Step 3: Implement the server repository factory and switch routes**

```ts
export async function getServerSamRepository(): Promise<SamRepository> {
  const client = await createServerSupabaseClient();
  return createSupabaseSamRepository(client);
}
```

Each page obtains one repository per request and keeps existing `Promise.all` behavior. Preserve `notFound()` for missing detail rows.

- [ ] **Step 4: Verify all page tests and absence of mock route imports**

Run:

```bash
npx vitest run src/app --maxWorkers=1
rg -n "mockSamRepository" src/app
```

Expected: tests pass; `rg` returns no protected route matches.

- [ ] **Step 5: Commit the live read switch**

```bash
git add src/app src/features/sam/server-repository.ts
git commit -m "feat: read SAM pages from Supabase"
```

---

### Task 3: Shared Mutation State, Error Mapping, and Action UI Primitives

**Files:**
- Create: `src/features/sam/action-state.ts`
- Create: `src/features/sam/action-state.test.ts`
- Create: `src/components/ui/action-menu.tsx`
- Create: `src/components/ui/action-menu.test.tsx`
- Create: `src/components/ui/confirmation-dialog.tsx`
- Create: `src/components/ui/confirmation-dialog.test.tsx`
- Create: `src/components/ui/toast-message.tsx`

**Interfaces:**
- Produces: `MutationState`, `mapSupabaseCommandError(error)`, `ActionMenu`, and `ConfirmationDialog` shared by later feature tasks.

- [ ] **Step 1: Write failing error-mapping tests**

```ts
test.each([
  ["VERSION_CONFLICT", "ข้อมูลถูกแก้ไขโดยผู้ใช้อื่น กรุณาโหลดข้อมูลล่าสุด"],
  ["ACTIVE_ALLOCATIONS_EXIST", "กรุณา Release Allocation ที่ใช้งานอยู่ก่อน"],
  ["REASON_REQUIRED", "กรุณาระบุเหตุผล"],
])("maps %s to actionable Thai copy", (code, message) => {
  expect(mapSupabaseCommandError({ message: code })).toMatchObject({ error: message });
});
```

- [ ] **Step 2: Run tests and verify RED**

Run: `npx vitest run src/features/sam/action-state.test.ts src/components/ui/action-menu.test.tsx src/components/ui/confirmation-dialog.test.tsx --maxWorkers=1`

Expected: FAIL with missing modules.

- [ ] **Step 3: Implement minimal state and accessible primitives**

```ts
export interface MutationState {
  status: "idle" | "success" | "error" | "conflict";
  message?: string;
  fieldErrors?: Record<string, string>;
  correlationId?: string;
}
```

`ActionMenu` uses a labelled button, keyboard-accessible menu items, outside-click/Escape close, and destructive styling. `ConfirmationDialog` requires a non-empty reason when `requireReason` is true and does not call the action until the explicit confirmation button is submitted.

- [ ] **Step 4: Verify GREEN and commit**

Run the focused tests. Expected: PASS with no accessibility query warnings.

```bash
git add src/features/sam/action-state* src/components/ui/action-menu* src/components/ui/confirmation-dialog* src/components/ui/toast-message.tsx
git commit -m "feat: add mutation UI primitives"
```

---

### Task 4: Asset and Software Product Edit/Archive UI

**Files:**
- Create: `src/features/assets/actions.ts`
- Create: `src/features/assets/actions.test.ts`
- Modify: `src/features/assets/asset-form-drawer.tsx`
- Modify: `src/features/assets/asset-list.tsx`
- Modify: `src/features/assets/asset-detail.tsx`
- Modify: `src/features/assets/asset-list.test.tsx`
- Modify: `src/features/assets/asset-form-drawer.test.tsx`
- Modify: `src/features/assets/asset-detail.test.tsx`
- Create: `src/features/software/actions.ts`
- Create: `src/features/software/actions.test.ts`
- Create: `src/features/software/software-form-drawer.tsx`
- Modify: `src/features/software/software-list.tsx`
- Modify: `src/features/software/software-list.test.tsx`

**Interfaces:**
- Consumes: Task 3 primitives and typed RPCs.
- Produces: `saveAsset`, `archiveAsset`, `saveSoftwareProduct`, and `archiveSoftwareProduct` Server Actions.

- [ ] **Step 1: Write failing role/action and Server Action tests**

Component test:

```ts
test("shows Edit and Archive to admins but not users", async () => {
  const { rerender } = render(<AssetList assets={assets} role="user" />);
  expect(screen.queryByRole("button", { name: /actions for TKC-001/i })).not.toBeInTheDocument();
  rerender(<AssetList assets={assets} role="admin" />);
  await userEvent.click(screen.getByRole("button", { name: /actions for TKC-001/i }));
  expect(screen.getByRole("menuitem", { name: "แก้ไข" })).toBeInTheDocument();
  expect(screen.getByRole("menuitem", { name: "Archive" })).toBeInTheDocument();
});
```

Server Action test verifies `expected_version` and reason are passed to `.rpc()` and `revalidatePath("/assets")` runs only after success.

- [ ] **Step 2: Verify RED**

Run focused Asset and Software tests. Expected: FAIL because menus/actions do not exist.

- [ ] **Step 3: Implement Asset actions and prefilled Drawer**

```ts
const { error } = await client.rpc("update_asset", {
  asset_id: String(formData.get("id")),
  expected_version: Number(formData.get("version")),
  payload: { computer_name: formData.get("computerName"), remark: formData.get("remark") },
});
```

Use `useActionState`, preserve input on errors, and show active Allocation impact in the Archive Dialog.

- [ ] **Step 4: Implement Software actions and Drawer**

Prefill Publisher, Product Name, Version, Category, and active state. Archive requires a reason and does not remove historical License/Asset references.

- [ ] **Step 5: Verify GREEN and commit**

Run:

```bash
npx vitest run src/features/assets src/features/software --maxWorkers=1
```

Expected: all focused tests pass.

```bash
git add src/features/assets src/features/software
git commit -m "feat: manage assets and software products"
```

---

### Task 5: License and Allocation Operational Actions

**Files:**
- Create: `src/features/licenses/actions.ts`
- Create: `src/features/licenses/actions.test.ts`
- Modify: `src/features/licenses/license-form-drawer.tsx`
- Modify: `src/features/licenses/license-list.tsx`
- Modify: `src/features/licenses/license-detail.tsx`
- Modify: `src/features/licenses/license-key.tsx`
- Create: `src/features/allocations/actions.ts`
- Create: `src/features/allocations/actions.test.ts`
- Modify: `src/features/allocations/allocation-list.tsx`
- Modify: `src/features/allocations/allocation-drawer.tsx`
- Modify: `src/features/licenses/license-list.test.tsx`
- Modify: `src/features/licenses/license-form-drawer.test.tsx`
- Modify: `src/features/licenses/license-detail.test.tsx`
- Modify: `src/features/allocations/allocation-list.test.tsx`
- Modify: `src/features/allocations/allocation-drawer.test.tsx`

**Interfaces:**
- Consumes: typed `create_license_entitlement(payload, secret_payload)`, `rotate_license_secret`, and `reveal_license_secret` RPCs.
- Produces: `saveLicenseEntitlement`, `rotateLicenseSecret`, `revealLicenseSecret`, `archiveLicenseEntitlement`, `allocateLicense`, `releaseAllocation`, and audited secret reveal behavior.

- [ ] **Step 1: Write failing tests for Owned/Allocated, Archive, and Release UX**

Assert the form prevents Owned below displayed Active Allocated before submit, the database error is still handled, Archive explains active Allocation impact, and Allocation rows offer Release rather than Edit/Delete.

- [ ] **Step 2: Verify RED**

Run: `npx vitest run src/features/licenses src/features/allocations --maxWorkers=1`

Expected: new action tests fail.

- [ ] **Step 3: Implement typed License actions and secret separation**

Ordinary form state never contains a stored secret value. On Create, split allowlisted entitlement fields into `payload` and new values into `secret_payload` before calling `create_license_entitlement`. Editing entitlement metadata calls `update_license_entitlement` and never sends secret fields. Secret replacement uses a separate confirmation form calling `rotate_license_secret` with `secret_type`, the new value, and a required reason.

Reveal uses a freshly generated correlation UUID and calls `reveal_license_secret` with the current user session. Render the returned value only inside a no-store Client Dialog, clear it from state on close/unmount, and never place it in a URL, toast, log, Server Component prop, cache, or reusable form default.

- [ ] **Step 4: Implement Allocation Create and Release actions**

Release sends `allocation_id`, `expected_version`, and required `reason`; success revalidates `/allocations`, `/licenses`, the related detail route, and `/`.

- [ ] **Step 5: Verify GREEN and commit**

Run focused tests; expected all pass.

```bash
git add src/features/licenses src/features/allocations
git commit -m "feat: manage licenses and allocations"
```

---

### Task 6: Master Data, System Settings, User, and Notification Actions

**Files:**
- Create: `src/features/admin/actions.ts`
- Create: `src/features/admin/actions.test.ts`
- Modify: `src/features/admin/master-data-view.tsx`
- Modify: `src/features/admin/user-management-view.tsx`
- Modify: `src/features/admin/settings-view.test.tsx`
- Create: `src/features/notifications/actions.ts`
- Modify: `src/features/admin/settings-view.tsx`
- Create: `src/features/notifications/actions.test.ts`
- Modify: `src/features/notifications/notification-list.tsx`
- Create/modify: focused component tests beside changed views

**Interfaces:**
- Produces: master-data Edit/Archive, optimistic System Settings update, user role/status, and own-recipient notification state actions.

- [ ] **Step 1: Write failing tests for action visibility and protected states**

Test that the last active Admin error remains visible, Archive requires a reason, stale System Settings return a conflict, and a User can mark only their own notification read/dismissed.

- [ ] **Step 2: Verify RED**

Run focused Admin/Notification tests. Expected: FAIL with missing action and Settings handlers.

- [ ] **Step 3: Implement Server Actions and UI**

Map entity names through an explicit union, never arbitrary table names. The Settings action sends `expected_version` and allowlisted policy fields to `update_system_settings`. Master changes revalidate `/master-data`; Settings revalidates `/settings`; User changes revalidate `/users`; notification state revalidates `/notifications` and `/`.

- [ ] **Step 4: Verify GREEN and commit**

```bash
npx vitest run src/features/admin src/features/notifications --maxWorkers=1
git add src/features/admin src/features/notifications
git commit -m "feat: manage admin settings and notification state"
```

---

### Task 7: Live Reports and Audited Export

**Files:**
- Create: `src/features/reports/repository.ts`
- Create: `src/features/reports/repository.test.ts`
- Create: `src/features/reports/export.ts`
- Create: `src/features/reports/export.test.ts`
- Modify: `src/features/reports/report-catalog.tsx`
- Modify: `src/features/reports/report-catalog.test.tsx`
- Modify: `src/features/reports/report-preview.test.tsx`
- Create: `src/app/api/reports/export/route.ts`
- Create: `src/app/api/reports/export/route.test.ts`
- Modify: `src/app/(protected)/reports/page.tsx`

**Interfaces:**
- Consumes: typed `export_report(report_type, filters)` RPC and safe report rows.
- Produces: hosted report previews and authenticated CSV downloads with Audit events.

- [ ] **Step 1: Write failing live-preview and route tests**

Use literal safe report fixtures. Assert the preview contains hosted rows rather than mock labels, the route rejects an unknown `reportType`, a valid export calls `export_report`, CSV cells beginning with `=`, `+`, `-`, or `@` are prefixed with an apostrophe, and the response has `text/csv; charset=utf-8` plus an attachment filename.

- [ ] **Step 2: Verify RED**

Run: `npx vitest run src/features/reports src/app/api/reports/export/route.test.ts --maxWorkers=1`

Expected: FAIL because the live report repository/export route does not exist and the catalog still advertises mock preview data.

- [ ] **Step 3: Implement typed report reads and CSV escaping**

```ts
export function csvCell(value: unknown): string {
  const text = value == null ? "" : String(value);
  const safe = /^[=+\-@]/.test(text) ? `'${text}` : text;
  return `"${safe.replaceAll('"', '""')}"`;
}
```

The report type is an explicit union: `asset_inventory`, `license_compliance`, `license_expiry`, and `allocation_history`. Filters are allowlisted by report type.

- [ ] **Step 4: Implement the authenticated Route Handler**

Read the installed Next.js 16 Route Handler guide first. Require the current Viewer, validate query parameters, call the audited RPC with the authenticated server client, and return UTF-8 BOM CSV so Thai text opens correctly in Excel.

- [ ] **Step 5: Verify GREEN and commit**

```bash
npx vitest run src/features/reports src/app/api/reports/export/route.test.ts --maxWorkers=1
git add src/features/reports src/app/api/reports/export "src/app/(protected)/reports/page.tsx"
git commit -m "feat: add live audited report exports"
```

---

### Task 8: Application Regression and Build Checkpoint

**Files:**
- Modify only files required to fix failures introduced by Tasks 1–7.

**Interfaces:**
- Produces: a locally verified live-data application ready for the migration review plan.

- [ ] **Step 1: Run the complete application suite sequentially**

Run: `npx vitest run --maxWorkers=1`

Expected: all tests pass with zero failures/timeouts.

- [ ] **Step 2: Run lint and production build**

Run:

```bash
npm run lint
npm run build
```

Expected: both exit 0; every App Router route builds.

- [ ] **Step 3: Verify the mock boundary is gone**

Run: `rg -n "mockSamRepository|mock-data" src/app src/features --glob '!**/*.test.*'`

Expected: no operational imports. Keeping mock fixtures solely for tests is allowed.

- [ ] **Step 4: Commit any focused regression fixes and stop for review**

```bash
git status --short
git log -8 --oneline
```

Do not stage or publish Excel data yet. Continue with `2026-09-02-excel-staging-review-plan.md` after checkpoint approval.
