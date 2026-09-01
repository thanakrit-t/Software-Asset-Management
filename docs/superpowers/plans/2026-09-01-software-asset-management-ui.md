# Software Asset Management UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished, responsive Software Asset Management UI prototype from `PRD.md` using Next.js 16 App Router, TypeScript, Tailwind CSS, and local mock data, without connecting to Supabase yet.

**Architecture:** The application uses App Router route groups, server-rendered pages where interaction is unnecessary, and focused client components for search, filtering, navigation, and role preview. Domain types and repository interfaces live independently from UI components; the first repository implementation returns deterministic mock data so a later Supabase adapter can replace it without rewriting pages.

**Tech Stack:** Next.js 16, React 19, TypeScript strict mode, Tailwind CSS 4, Lucide React, Recharts, Vitest, React Testing Library, jsdom.

**Spec:** `PRD.md`

## Global Constraints

- Use Next.js 16 App Router with TypeScript and `src/` layout.
- Use Tailwind CSS with the PRD palette: blue, slate gray, white, success, warning, and critical status colors.
- Do not initialize, configure, or call Supabase in this UI milestone.
- Use only deterministic local mock data through repository interfaces.
- Support Admin and User UI previews; User mode must hide management routes and mutation controls.
- Mask license keys for User mode and reveal them only in Admin preview.
- Primary UI language is Thai while preserving English product and source-data names.
- Target desktop at 1366×768 and usable tablet landscape layouts.
- Preserve `PRD.md` and both source Excel files at the project root.
- Run lint, unit/component tests, and production build before completion.

---

### Task 1: Application foundation and test harness

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `next.config.ts`
- Create: `postcss.config.mjs`
- Create: `eslint.config.mjs`
- Create: `vitest.config.ts`
- Create: `vitest.setup.ts`
- Create: `.gitignore`
- Create: `src/app/globals.css`
- Create: `src/app/layout.tsx`
- Create: `src/app/page.tsx`
- Test: `src/app/page.test.tsx`

**Interfaces:**
- Produces the `@/* -> ./src/*` alias used by every later task.
- Produces the root layout, global design tokens, and test environment.

- [ ] **Step 1: Create package and tooling configuration**

Use exact major versions and scripts:

```json
{
  "name": "software-asset-management",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint .",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "lucide-react": "^0.468.0",
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "recharts": "^3.0.0"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.0.0",
    "@testing-library/jest-dom": "^6.0.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.0.0",
    "@types/node": "^24.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "@vitejs/plugin-react": "^5.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^16.0.0",
    "jsdom": "^26.0.0",
    "tailwindcss": "^4.0.0",
    "typescript": "^5.0.0",
    "vitest": "^3.0.0"
  }
}
```

- [ ] **Step 2: Install dependencies**

Run: `npm install`

Expected: `node_modules/` and `package-lock.json` are created with Next.js major version 16.

- [ ] **Step 3: Write a failing landing-page test**

```tsx
import { render, screen } from "@testing-library/react";
import Home from "./page";

test("introduces the software asset management workspace", () => {
  render(<Home />);
  expect(screen.getByRole("heading", { name: /software asset management/i })).toBeInTheDocument();
});
```

- [ ] **Step 4: Run the test and verify RED**

Run: `npm test -- src/app/page.test.tsx`

Expected: FAIL because `src/app/page.tsx` does not exist.

- [ ] **Step 5: Add root layout, design tokens, and minimal landing page**

Create a Thai-language root layout and a minimal page that renders the requested heading. Define Tailwind theme tokens in `globals.css` for `--color-primary`, `--color-primary-dark`, `--color-surface`, `--color-border`, `--color-success`, `--color-warning`, and `--color-critical` using values from PRD section 12.

- [ ] **Step 6: Verify foundation**

Run: `npm test -- src/app/page.test.tsx`

Expected: PASS with 1 test and no warnings.

Run: `npm run lint`

Expected: exit 0.

---

### Task 2: Domain contracts, formatters, and mock repository

**Files:**
- Create: `src/features/sam/types.ts`
- Create: `src/features/sam/repository.ts`
- Create: `src/features/sam/mock-data.ts`
- Create: `src/features/sam/mock-repository.ts`
- Create: `src/features/sam/formatters.ts`
- Test: `src/features/sam/formatters.test.ts`
- Test: `src/features/sam/mock-repository.test.ts`

**Interfaces:**
- Produces `Role`, `Site`, `Asset`, `SoftwareProduct`, `LicenseEntitlement`, `LicenseAllocation`, `NotificationItem`, and `AuditEvent` types.
- Produces `SamRepository` with async list and detail methods.
- Produces `mockSamRepository: SamRepository` for all pages.
- Produces `maskLicenseKey(value: string): string`, `formatNumber(value: number): string`, and `formatDate(value?: string): string`.

- [ ] **Step 1: Write failing formatter tests**

```ts
import { formatDate, maskLicenseKey } from "./formatters";

test("masks a license key except its final five characters", () => {
  expect(maskLicenseKey("36QJC-PNYBC-7BXCW-4CMCW-Q69TY")).toBe("•••••-•••••-•••••-•••••-Q69TY");
});

test("formats an ISO date in Thai-readable day month year order", () => {
  expect(formatDate("2026-08-28")).toBe("28 ส.ค. 2026");
});
```

- [ ] **Step 2: Run formatter tests and verify RED**

Run: `npm test -- src/features/sam/formatters.test.ts`

Expected: FAIL because `formatters.ts` is missing.

- [ ] **Step 3: Implement domain types and formatters**

Define discriminated status unions instead of free-form strings. Implement `maskLicenseKey` by preserving separators and the last five non-separator characters. Implement `formatDate` with a fixed `th-TH` formatter and UTC parsing so tests are timezone-stable.

- [ ] **Step 4: Verify formatter GREEN**

Run: `npm test -- src/features/sam/formatters.test.ts`

Expected: PASS with 2 tests.

- [ ] **Step 5: Write failing repository behavior tests**

```ts
import { mockSamRepository } from "./mock-repository";

test("returns assets for the requested site", async () => {
  const assets = await mockSamRepository.listAssets({ siteId: "factory" });
  expect(assets.length).toBeGreaterThan(0);
  expect(assets.every((asset) => asset.site.id === "factory")).toBe(true);
});

test("derives available seats from owned and allocated quantities", async () => {
  const licenses = await mockSamRepository.listLicenses({});
  expect(licenses.every((license) => license.availableQuantity === license.ownedQuantity - license.allocatedQuantity)).toBe(true);
});
```

- [ ] **Step 6: Run repository tests and verify RED**

Run: `npm test -- src/features/sam/mock-repository.test.ts`

Expected: FAIL because the repository and fixtures are missing.

- [ ] **Step 7: Implement representative mock data and repository**

Create deterministic Factory and Bangkok Office records inspired by the source workbooks: PC, notebook, and server assets; Microsoft Windows/Office, SQL Server, AutoCAD, and utility licenses; allocations, notifications, and audit events. Keep secrets fictitious and label fixtures as mock data. Implement filtering inside the repository rather than inside route components.

- [ ] **Step 8: Verify repository GREEN**

Run: `npm test -- src/features/sam/mock-repository.test.ts`

Expected: PASS with both behaviors verified.

---

### Task 3: Application shell, responsive navigation, and role preview

**Files:**
- Create: `src/components/app-shell/app-shell.tsx`
- Create: `src/components/app-shell/sidebar.tsx`
- Create: `src/components/app-shell/topbar.tsx`
- Create: `src/components/app-shell/mobile-nav.tsx`
- Create: `src/components/app-shell/role-provider.tsx`
- Create: `src/components/ui/logo-mark.tsx`
- Create: `src/components/ui/avatar.tsx`
- Create: `src/components/ui/button.tsx`
- Modify: `src/app/layout.tsx`
- Test: `src/components/app-shell/sidebar.test.tsx`

**Interfaces:**
- Produces `useRole(): { role: Role; setRole(role: Role): void }`.
- Produces `AppShell({ children }: { children: React.ReactNode })`.
- Consumes `Role` from Task 2.

- [ ] **Step 1: Write failing role-navigation tests**

```tsx
import { render, screen } from "@testing-library/react";
import { Sidebar } from "./sidebar";

test("shows settings navigation to administrators", () => {
  render(<Sidebar role="admin" pathname="/" />);
  expect(screen.getByRole("link", { name: /ตั้งค่าระบบ/ })).toBeInTheDocument();
});

test("hides management navigation from regular users", () => {
  render(<Sidebar role="user" pathname="/" />);
  expect(screen.queryByRole("link", { name: /ตั้งค่าระบบ/ })).not.toBeInTheDocument();
  expect(screen.getByRole("link", { name: /รายงาน/ })).toBeInTheDocument();
});
```

- [ ] **Step 2: Run navigation tests and verify RED**

Run: `npm test -- src/components/app-shell/sidebar.test.tsx`

Expected: FAIL because `Sidebar` is missing.

- [ ] **Step 3: Implement the shell**

Create a fixed desktop sidebar, responsive mobile drawer, and top bar with global search affordance, notification button, user avatar, and Admin/User preview selector. Persist only the preview role to `sessionStorage`; do not represent this as real authentication. Use `aria-current="page"` for the active navigation link.

- [ ] **Step 4: Verify shell GREEN**

Run: `npm test -- src/components/app-shell/sidebar.test.tsx`

Expected: PASS with both role cases.

Run: `npm run lint`

Expected: exit 0.

---

### Task 4: Dashboard with KPI cards, compliance chart, and alert panel

**Files:**
- Create: `src/features/dashboard/dashboard-summary.ts`
- Create: `src/features/dashboard/kpi-card.tsx`
- Create: `src/features/dashboard/license-overview-chart.tsx`
- Create: `src/features/dashboard/asset-distribution-chart.tsx`
- Create: `src/features/dashboard/attention-panel.tsx`
- Create: `src/features/dashboard/site-filter.tsx`
- Create: `src/features/dashboard/dashboard-view.tsx`
- Modify: `src/app/page.tsx`
- Test: `src/features/dashboard/dashboard-summary.test.ts`
- Test: `src/features/dashboard/dashboard-view.test.tsx`

**Interfaces:**
- Produces `buildDashboardSummary(assets, licenses): DashboardSummary`.
- Produces `DashboardView({ assets, licenses, notifications }: DashboardViewProps)`.
- Consumes Task 2 repository data and formatters.

- [ ] **Step 1: Write failing KPI derivation tests**

```ts
import { buildDashboardSummary } from "./dashboard-summary";

test("counts owned allocated available and over-allocated seats", () => {
  const summary = buildDashboardSummary([], [
    { id: "a", ownedQuantity: 10, allocatedQuantity: 7, availableQuantity: 3, lifecycleStatus: "active" },
    { id: "b", ownedQuantity: 2, allocatedQuantity: 4, availableQuantity: -2, lifecycleStatus: "active" }
  ] as never);
  expect(summary).toMatchObject({ owned: 12, allocated: 11, available: 1, overAllocated: 1 });
});
```

- [ ] **Step 2: Run the test and verify RED**

Run: `npm test -- src/features/dashboard/dashboard-summary.test.ts`

Expected: FAIL because the summary function is missing.

- [ ] **Step 3: Implement summary calculation**

Use a pure reducer and count over-allocation by entitlement records with negative available quantity. Keep date/status derivation in domain helpers rather than chart components.

- [ ] **Step 4: Verify KPI GREEN**

Run: `npm test -- src/features/dashboard/dashboard-summary.test.ts`

Expected: PASS.

- [ ] **Step 5: Write a failing dashboard accessibility test**

```tsx
import { render, screen } from "@testing-library/react";
import { DashboardView } from "./dashboard-view";

test("labels the dashboard KPIs and urgent items", () => {
  render(<DashboardView assets={[]} licenses={[]} notifications={[]} />);
  expect(screen.getByRole("heading", { name: /ภาพรวมสินทรัพย์ซอฟต์แวร์/ })).toBeInTheDocument();
  expect(screen.getByText(/รายการที่ต้องตรวจสอบ/)).toBeInTheDocument();
});
```

- [ ] **Step 6: Run dashboard component test and verify RED**

Run: `npm test -- src/features/dashboard/dashboard-view.test.tsx`

Expected: FAIL because `DashboardView` is missing.

- [ ] **Step 7: Build the dashboard UI**

Render five KPI cards, a license utilization bar/composed chart, an asset-by-site doughnut chart, and an attention panel. Add a visible site filter and responsive stacking. Chart components must include text summaries so the information is not color-only.

- [ ] **Step 8: Verify dashboard GREEN**

Run: `npm test -- src/features/dashboard/dashboard-view.test.tsx`

Expected: PASS.

---

### Task 5: Reusable data-table controls and Assets experience

**Files:**
- Create: `src/components/data-table/search-field.tsx`
- Create: `src/components/data-table/filter-select.tsx`
- Create: `src/components/data-table/table-shell.tsx`
- Create: `src/components/ui/status-badge.tsx`
- Create: `src/components/ui/empty-state.tsx`
- Create: `src/features/assets/asset-list.tsx`
- Create: `src/features/assets/asset-detail.tsx`
- Create: `src/features/assets/asset-form-drawer.tsx`
- Create: `src/app/assets/page.tsx`
- Create: `src/app/assets/[id]/page.tsx`
- Test: `src/features/assets/asset-list.test.tsx`

**Interfaces:**
- Produces controlled `SearchField`, `FilterSelect`, and `TableShell` UI components.
- Produces `AssetList({ assets, role }: { assets: Asset[]; role: Role })`.
- Produces `AssetDetail({ asset, allocations }: AssetDetailProps)`.

- [ ] **Step 1: Write failing asset list behavior tests**

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AssetList } from "./asset-list";

test("filters assets by computer name", async () => {
  const user = userEvent.setup();
  render(<AssetList role="user" assets={assetFixtures} />);
  await user.type(screen.getByRole("searchbox", { name: /ค้นหา asset/ }), "TPO-083");
  expect(screen.getByText("TPO-083-PC")).toBeInTheDocument();
  expect(screen.queryByText("TKCBKKLT001")).not.toBeInTheDocument();
});

test("shows the add action only to administrators", () => {
  const { rerender } = render(<AssetList role="user" assets={assetFixtures} />);
  expect(screen.queryByRole("button", { name: /เพิ่ม asset/ })).not.toBeInTheDocument();
  rerender(<AssetList role="admin" assets={assetFixtures} />);
  expect(screen.getByRole("button", { name: /เพิ่ม asset/ })).toBeInTheDocument();
});
```

- [ ] **Step 2: Run list tests and verify RED**

Run: `npm test -- src/features/assets/asset-list.test.tsx`

Expected: FAIL because `AssetList` is missing.

- [ ] **Step 3: Implement asset list and detail UI**

Build search, Site/Type/Status filters, responsive table, pagination affordance, status badges, and Admin-only add button. Build detail tabs/sections for overview, network interfaces, software allocations, and activity history. The add/edit drawer is a UI-only controlled form: submit shows a local success banner and does not persist.

- [ ] **Step 4: Verify asset experience GREEN**

Run: `npm test -- src/features/assets/asset-list.test.tsx`

Expected: PASS for search and role behavior.

---

### Task 6: Software, licenses, allocations, and sensitive data behavior

**Files:**
- Create: `src/features/software/software-list.tsx`
- Create: `src/features/licenses/license-list.tsx`
- Create: `src/features/licenses/license-detail.tsx`
- Create: `src/features/licenses/license-key.tsx`
- Create: `src/features/licenses/license-form-drawer.tsx`
- Create: `src/features/allocations/allocation-list.tsx`
- Create: `src/features/allocations/allocation-drawer.tsx`
- Create: `src/app/software/page.tsx`
- Create: `src/app/licenses/page.tsx`
- Create: `src/app/licenses/[id]/page.tsx`
- Create: `src/app/allocations/page.tsx`
- Test: `src/features/licenses/license-key.test.tsx`
- Test: `src/features/licenses/license-list.test.tsx`

**Interfaces:**
- Produces `LicenseKey({ value, role }: { value: string; role: Role })`.
- Produces role-aware license and allocation list/detail components.
- Consumes `maskLicenseKey` and mock repository contracts from Task 2.

- [ ] **Step 1: Write failing secret-display tests**

```tsx
import { render, screen } from "@testing-library/react";
import { LicenseKey } from "./license-key";

test("masks a license key for a regular user", () => {
  render(<LicenseKey role="user" value="36QJC-PNYBC-7BXCW-4CMCW-Q69TY" />);
  expect(screen.getByText("•••••-•••••-•••••-•••••-Q69TY")).toBeInTheDocument();
  expect(screen.queryByText("36QJC-PNYBC-7BXCW-4CMCW-Q69TY")).not.toBeInTheDocument();
});

test("allows an administrator to reveal a license key", async () => {
  const user = userEvent.setup();
  render(<LicenseKey role="admin" value="36QJC-PNYBC-7BXCW-4CMCW-Q69TY" />);
  await user.click(screen.getByRole("button", { name: /แสดง license key/ }));
  expect(screen.getByText("36QJC-PNYBC-7BXCW-4CMCW-Q69TY")).toBeInTheDocument();
});
```

- [ ] **Step 2: Run secret-display tests and verify RED**

Run: `npm test -- src/features/licenses/license-key.test.tsx`

Expected: FAIL because `LicenseKey` is missing.

- [ ] **Step 3: Implement masked/reveal behavior**

Use local component state for Admin reveal, include accessible button labels, and never place the full key into User-rendered markup. Add a UI-only audit notice near the Admin reveal action.

- [ ] **Step 4: Verify secret-display GREEN**

Run: `npm test -- src/features/licenses/license-key.test.tsx`

Expected: PASS.

- [ ] **Step 5: Write failing license list tests**

Verify that the list exposes Owned, Allocated, Available, lifecycle status, product search, and Admin-only create/allocation actions.

- [ ] **Step 6: Run license list tests and verify RED**

Run: `npm test -- src/features/licenses/license-list.test.tsx`

Expected: FAIL because the list is missing.

- [ ] **Step 7: Build software, license, and allocation routes**

Build list/detail pages with shared filtering and table components. Use status badges for Active, Expiring Soon, Expired, Deactivated, Compliant, and Over-allocated. Add UI-only drawers for new license and allocation with validation messages and no persistence.

- [ ] **Step 8: Verify module GREEN**

Run: `npm test -- src/features/licenses/license-list.test.tsx src/features/licenses/license-key.test.tsx`

Expected: PASS.

---

### Task 7: Reports, notifications, and Admin management screens

**Files:**
- Create: `src/features/reports/report-catalog.tsx`
- Create: `src/features/reports/report-preview.tsx`
- Create: `src/features/notifications/notification-list.tsx`
- Create: `src/features/admin/master-data-view.tsx`
- Create: `src/features/admin/user-management-view.tsx`
- Create: `src/features/admin/audit-log-view.tsx`
- Create: `src/features/admin/settings-view.tsx`
- Create: `src/app/reports/page.tsx`
- Create: `src/app/notifications/page.tsx`
- Create: `src/app/master-data/page.tsx`
- Create: `src/app/users/page.tsx`
- Create: `src/app/audit-logs/page.tsx`
- Create: `src/app/settings/page.tsx`
- Test: `src/features/reports/report-catalog.test.tsx`
- Test: `src/features/admin/settings-view.test.tsx`

**Interfaces:**
- Produces the 14 report cards defined in PRD FR-09.
- Produces UI-only Admin pages that consume role context and render an access-denied panel in User preview.

- [ ] **Step 1: Write failing report-catalog tests**

```tsx
import { render, screen } from "@testing-library/react";
import { ReportCatalog } from "./report-catalog";

test("offers asset license compliance and migration reports", () => {
  render(<ReportCatalog />);
  expect(screen.getByText(/Asset Inventory/)).toBeInTheDocument();
  expect(screen.getByText(/Owned vs Allocated/)).toBeInTheDocument();
  expect(screen.getByText(/Migration Reconciliation/)).toBeInTheDocument();
});
```

- [ ] **Step 2: Run report tests and verify RED**

Run: `npm test -- src/features/reports/report-catalog.test.tsx`

Expected: FAIL because `ReportCatalog` is missing.

- [ ] **Step 3: Implement reports and notifications**

Build report cards grouped by Asset, License/Compliance, and Data Quality. Add filter/preview UI and disabled export actions labeled as demo-only. Build notifications with severity, read state, linked entity, and timestamp.

- [ ] **Step 4: Verify report GREEN**

Run: `npm test -- src/features/reports/report-catalog.test.tsx`

Expected: PASS.

- [ ] **Step 5: Write failing Admin access test**

```tsx
import { render, screen } from "@testing-library/react";
import { SettingsView } from "./settings-view";

test("blocks settings content in regular user preview", () => {
  render(<SettingsView role="user" />);
  expect(screen.getByRole("heading", { name: /ไม่มีสิทธิ์เข้าถึง/ })).toBeInTheDocument();
  expect(screen.queryByLabelText(/session timeout/)).not.toBeInTheDocument();
});
```

- [ ] **Step 6: Run Admin access test and verify RED**

Run: `npm test -- src/features/admin/settings-view.test.tsx`

Expected: FAIL because `SettingsView` is missing.

- [ ] **Step 7: Implement management pages**

Create Master Data tabs, user/role table, audit event list, and system settings form. These are non-persistent UI prototypes. Every Admin route must render an access-denied state in User preview in addition to being absent from the sidebar.

- [ ] **Step 8: Verify management GREEN**

Run: `npm test -- src/features/admin/settings-view.test.tsx`

Expected: PASS.

---

### Task 8: Responsive polish, route metadata, and completion verification

**Files:**
- Create: `src/app/loading.tsx`
- Create: `src/app/error.tsx`
- Create: `src/app/not-found.tsx`
- Create: `src/components/ui/page-header.tsx`
- Create: `src/components/ui/skeleton.tsx`
- Modify: all route pages to add metadata and consistent page headers
- Modify: `README.md`
- Test: `src/components/app-shell/app-shell.test.tsx`

**Interfaces:**
- Produces consistent loading, empty, error, and not-found experiences.
- Documents mock-mode behavior and the later Supabase adapter boundary.

- [ ] **Step 1: Write a failing shell landmark test**

```tsx
import { render, screen } from "@testing-library/react";
import { AppShell } from "./app-shell";

test("exposes navigation and main content landmarks", () => {
  render(<AppShell><h1>Dashboard</h1></AppShell>);
  expect(screen.getByRole("navigation", { name: /เมนูหลัก/ })).toBeInTheDocument();
  expect(screen.getByRole("main")).toContainElement(screen.getByRole("heading", { name: "Dashboard" }));
});
```

- [ ] **Step 2: Run landmark test and verify RED**

Run: `npm test -- src/components/app-shell/app-shell.test.tsx`

Expected: FAIL until landmarks and labels are complete.

- [ ] **Step 3: Finish responsive and state polish**

Add focus-visible styles, reduced-motion behavior, 44px minimum touch targets, horizontal table scrolling, tablet sidebar behavior, skeletons, and clear empty/error states. Add metadata titles for all routes and README setup commands.

- [ ] **Step 4: Verify landmark GREEN**

Run: `npm test -- src/components/app-shell/app-shell.test.tsx`

Expected: PASS.

- [ ] **Step 5: Run complete automated verification**

Run: `npm test`

Expected: all tests pass with 0 failures.

Run: `npm run lint`

Expected: exit 0 with no lint errors.

Run: `npm run build`

Expected: Next.js production build succeeds and all routes compile.

- [ ] **Step 6: Run a visual QA pass**

Run: `npm run dev`

Inspect `/`, `/assets`, `/assets/tpo-083`, `/licenses`, `/licenses/lic-office-365`, `/allocations`, `/reports`, and `/settings` at desktop and tablet widths. Verify no clipped text, overlapping panels, broken charts, unreadable contrast, or inaccessible mobile navigation. Switch between Admin and User preview and verify restricted navigation/actions disappear while Admin routes show access denied in User mode.

- [ ] **Step 7: Record implementation boundary**

Update `README.md` to state that all records and mutations are mock-only, no Supabase package or environment variable is required, and the future integration point is `SamRepository`.

---

## Plan Self-Review

- PRD UI scope is covered across dashboard, assets, products, licenses, allocations, reports, notifications, master data, users, audit logs, and settings.
- Admin/User navigation, mutation visibility, route guard presentation, and license-key masking each have behavior tests.
- Supabase is intentionally deferred behind `SamRepository`; no client initialization appears in this milestone.
- Initial migration execution is not included because this milestone is UI-only; migration report presentation is included.
- Export actions are clearly demo-only because producing business files without a backend is outside this milestone.
- Every production behavior task starts with a failing test and contains a concrete verification command.
