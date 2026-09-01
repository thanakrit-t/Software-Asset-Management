# Supabase Database and Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** สร้าง Supabase database foundation ตาม `database.md` แล้วเชื่อม Next.js 16 กับ Supabase Email/Password Auth และ server-derived admin/user authorization โดยไม่เก็บ credential จริงใน repository

**Architecture:** ใช้ imperative SQL migrations ที่ replay ได้ด้วย Supabase CLI และ pgTAP tests เป็น database contract จากนั้นใช้ `@supabase/ssr` แยก browser/server clients, `src/proxy.ts` สำหรับ refresh token และ protected route-group layouts สำหรับ authorization จริง ฝั่ง UI ยังอ่านข้อมูลธุรกิจจาก Mock Repository ในรอบนี้ แต่ role และ session เปลี่ยนไปใช้ `public.profiles` จริง

**Tech Stack:** Next.js 16 App Router, React 19, TypeScript 5, Tailwind CSS 4, Supabase PostgreSQL/Auth, `@supabase/supabase-js`, `@supabase/ssr`, Supabase CLI, pgTAP, Vitest, Testing Library

**Spec:** `docs/superpowers/specs/2026-09-01-supabase-database-auth-design.md`

## Global Constraints

- Single tenant: Thai Kurabo; initial sites are Factory and Bangkok Office.
- Roles are exactly `admin` and `user`; new profiles default to `user`.
- Authentication is Email/Password with no public registration UI.
- The browser receives only `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`.
- Never read `Supabase.com.txt`; never log or commit a real publishable, secret, anon, or service-role key.
- `license_allocations` is the source of truth for allocated quantity.
- `private`, `audit`, and `migration` have no grants for `anon` or `authenticated`.
- Next.js 16 uses `src/proxy.ts`; `cookies()` is asynchronous.
- Proxy refreshes/verifies session optimistically; layouts, Server Actions, RPCs, and RLS enforce authorization.
- Existing business screens remain backed by `mockSamRepository` during this plan.
- Database production SQL requires a pgTAP test that was observed failing for the intended missing behavior first.
- Remote deployment is excluded; all database commands in this plan use the explicit `--local` target.

---

## File Map

### Database and tooling

- `supabase/config.toml`: local Supabase services, auth settings, migration and seed configuration
- `supabase/migrations/202609010001_foundation.sql`: schemas, extensions, enums, privilege baseline and shared helpers
- `supabase/migrations/202609010002_identity_master.sql`: profiles, people, organization and master tables
- `supabase/migrations/202609010003_asset_software.sql`: asset, network, assignment, publisher, software and installation tables
- `supabase/migrations/202609010004_license_operations.sql`: license, allocation, notification, audit, settings and migration tables
- `supabase/migrations/202609010005_derived_rpc.sql`: safe views, lifecycle calculations, allocation functions, profile bootstrap and audit triggers
- `supabase/migrations/202609010006_rls_grants.sql`: RLS policies, grants, default privileges and function execution permissions
- `supabase/seed.sql`: deterministic master data and initial sites
- `supabase/tests/database/001_identity_master.test.sql`: identity defaults and master constraints
- `supabase/tests/database/002_asset_license.test.sql`: asset/license constraints and derived quantities
- `supabase/tests/database/003_security.test.sql`: anon/user/admin RLS and private-schema isolation
- `src/lib/supabase/database.types.ts`: generated TypeScript schema types after local migrations pass

### Application authentication

- `.env.example`: public environment variable names with non-secret example values
- `src/lib/supabase/env.ts`: pure environment validation
- `src/lib/supabase/client.ts`: browser client factory
- `src/lib/supabase/server.ts`: request-scoped server client factory
- `src/lib/supabase/proxy.ts`: cookie refresh implementation used by `src/proxy.ts`
- `src/proxy.ts`: Next.js 16 Proxy entry and matcher
- `src/features/auth/types.ts`: `Viewer`, `AuthActionState`, role and account status contracts
- `src/features/auth/viewer.ts`: current viewer resolution from verified claims and profile
- `src/features/auth/guards.ts`: authenticated/admin server guards
- `src/features/auth/actions.ts`: login and logout Server Actions
- `src/features/auth/login-form.tsx`: accessible client form driven by `useActionState`
- `src/app/login/page.tsx`: public login page outside App Shell
- `src/app/(protected)/layout.tsx`: verified viewer + Role Provider + App Shell
- `src/app/(protected)/(admin)/layout.tsx`: server-side admin guard
- `src/components/app-shell/role-provider.tsx`: server-seeded immutable viewer context
- `src/components/app-shell/topbar.tsx`: real viewer identity and logout control
- `src/components/app-shell/sidebar.tsx`: authenticated mode label instead of prototype warning
- Existing page files move into route groups without changing their URLs.

---

### Task 1: Local Supabase Tooling and Public Environment Contract

**Files:**
- Modify: `package.json`
- Modify: `package-lock.json`
- Modify: `.gitignore`
- Create: `.env.example`
- Create: `supabase/config.toml`
- Create: `src/lib/supabase/env.ts`
- Test: `src/lib/supabase/env.test.ts`

**Interfaces:**
- Produces: `PublicSupabaseEnv { url: string; publishableKey: string }`
- Produces: `readPublicSupabaseEnv(source: NodeJS.ProcessEnv): PublicSupabaseEnv`
- Produces npm scripts: `supabase:start`, `supabase:stop`, `db:reset`, `db:test`, `db:lint`, `db:types`

- [ ] **Step 1: Confirm the database test prerequisite**

Run:

```powershell
docker --version
docker info
```

Expected: both commands exit 0. If Docker is unavailable, stop before Task 2 and ask the user to install/start Docker Desktop; application code may not overtake the approved database-first sequence.

- [ ] **Step 2: Install project-scoped Supabase dependencies**

Run:

```powershell
npm install @supabase/supabase-js @supabase/ssr
npm install --save-dev supabase
```

Expected: `package.json` and `package-lock.json` contain all three packages and no install errors.

- [ ] **Step 3: Write the failing environment tests**

```ts
import { readPublicSupabaseEnv } from "./env";

test("returns validated public Supabase configuration", () => {
  expect(readPublicSupabaseEnv({
    NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
  })).toEqual({
    url: "https://example.supabase.co",
    publishableKey: "sb_publishable_example",
  });
});

test("names missing variables without including another variable value", () => {
  expect(() => readPublicSupabaseEnv({
    NEXT_PUBLIC_SUPABASE_URL: "https://do-not-print.supabase.co",
  })).toThrow("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");
  expect(() => readPublicSupabaseEnv({
    NEXT_PUBLIC_SUPABASE_URL: "https://do-not-print.supabase.co",
  })).not.toThrow("https://do-not-print.supabase.co");
});
```

- [ ] **Step 4: Run the environment tests and observe RED**

Run: `npm test -- src/lib/supabase/env.test.ts`

Expected: FAIL because `./env` does not exist.

- [ ] **Step 5: Implement the minimal environment parser**

```ts
export interface PublicSupabaseEnv {
  url: string;
  publishableKey: string;
}

export function readPublicSupabaseEnv(source: NodeJS.ProcessEnv): PublicSupabaseEnv {
  const url = source.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const publishableKey = source.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();
  const missing = [
    !url && "NEXT_PUBLIC_SUPABASE_URL",
    !publishableKey && "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
  ].filter(Boolean);
  if (missing.length > 0) throw new Error(`Missing Supabase environment variable: ${missing.join(", ")}`);
  return { url: url!, publishableKey: publishableKey! };
}
```

Create `.env.example` containing only:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

Add `.env.local` and Supabase CLI state directories `.temp/`/`.branches/` to ignored paths while retaining the existing `!.env.example` exception. Configure `config.toml` with `project_id = "software-asset-management"`, local API/database defaults, `site_url = "http://localhost:3000"`, `enable_signup = false`, migrations enabled, and `seed.sql` enabled.

- [ ] **Step 6: Add safe local scripts and verify GREEN**

Add scripts that always state the local target:

```json
{
  "supabase:start": "supabase start",
  "supabase:stop": "supabase stop",
  "db:reset": "supabase db reset --local",
  "db:test": "supabase test db --local",
  "db:lint": "supabase db lint --local --level warning --fail-on warning",
  "db:types": "supabase gen types --lang typescript --local --schema public > src/lib/supabase/database.types.ts"
}
```

Run: `npm test -- src/lib/supabase/env.test.ts`

Expected: PASS.

- [ ] **Step 7: Commit the tooling contract**

```powershell
git add package.json package-lock.json .gitignore .env.example supabase/config.toml src/lib/supabase/env.ts src/lib/supabase/env.test.ts
git commit -m "chore: add local Supabase tooling"
```

---

### Task 2: Foundation, Identity, and Master Data Migrations

**Files:**
- Create: `supabase/tests/database/001_identity_master.test.sql`
- Create: `supabase/migrations/202609010001_foundation.sql`
- Create: `supabase/migrations/202609010002_identity_master.sql`
- Create: `supabase/seed.sql`

**Interfaces:**
- Produces enum types: `public.app_role`, `public.account_status`, allocation/lifecycle/supporting enums defined by `database.md`
- Produces identity: `public.profiles`, `public.people`
- Produces organization/master tables listed in `database.md` sections 6.1 and 6.2
- Produces helpers: `private.is_active_user() returns boolean`, `private.is_admin() returns boolean`

- [ ] **Step 1: Write failing pgTAP identity and master tests**

The test must begin a transaction, plan assertions, set JWT claims with `set_config('request.jwt.claims', ...)`, and roll back. Include assertions for:

```sql
select has_schema('private');
select has_schema('audit');
select has_schema('migration');
select has_table('public', 'profiles');
select col_is_pk('public', 'profiles', 'id');
select col_type_is('public', 'profiles', 'app_role', 'app_role');
select col_has_default('public', 'profiles', 'app_role');
select has_table('public', 'sites');
select results_eq(
  $$ select code from public.sites order by code $$,
  $$ values ('BANGKOK_OFFICE'::text), ('FACTORY'::text) $$,
  'initial sites are deterministic'
);
```

Insert duplicate case-insensitive site/master codes and assert the unique violation. Create an Auth user fixture and assert its profile role is `user`, status is `active`, and the user cannot update `app_role` directly.

- [ ] **Step 2: Run the identity tests and observe RED**

Run:

```powershell
npm run supabase:start
npm run db:test -- supabase/tests/database/001_identity_master.test.sql
```

Expected: FAIL because schemas/tables do not exist.

- [ ] **Step 3: Implement foundation and identity/master DDL**

Foundation migration must:

```sql
create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create schema if not exists private;
create schema if not exists audit;
create schema if not exists migration;
revoke all on schema private, audit, migration from public, anon, authenticated;
```

Create the enums and common trigger functions with `set search_path = ''`. Create `profiles` as a PK/FK to `auth.users(id)`, with role/status defaults and checks for login counters/lock state. Create `people`, `sites`, `locations`, `departments`, `asset_types`, `asset_statuses`, `internet_levels`, `software_categories`, `license_metrics`, `product_classifications`, `purchase_forms`, and `expiration_thresholds` with UUID PKs, common metadata, archive columns, version checks, and the exact relationships in `database.md`.

Implement `private.handle_new_auth_user()` as a security-definer trigger that always assigns `user`; do not accept role from Auth metadata. Add partial/case-insensitive unique indexes specified by the database design.

- [ ] **Step 4: Seed deterministic organization/master data**

Use fixed UUIDs and `insert ... on conflict (id) do update` for the approved codes. Do not seed login-capable users, passwords, keys, license secrets, real employee data, or production records.

- [ ] **Step 5: Reset and verify GREEN**

Run:

```powershell
npm run db:reset
npm run db:test -- supabase/tests/database/001_identity_master.test.sql
```

Expected: reset succeeds and all assertions pass.

- [ ] **Step 6: Commit identity and master schema**

```powershell
git add supabase/migrations/202609010001_foundation.sql supabase/migrations/202609010002_identity_master.sql supabase/seed.sql supabase/tests/database/001_identity_master.test.sql
git commit -m "feat: add identity and master database schema"
```

---

### Task 3: Asset, Software, License, and Operations Schema

**Files:**
- Create: `supabase/tests/database/002_asset_license.test.sql`
- Create: `supabase/migrations/202609010003_asset_software.sql`
- Create: `supabase/migrations/202609010004_license_operations.sql`

**Interfaces:**
- Produces asset/software tables from `database.md` sections 7 and 8
- Produces license/operations tables from sections 9, 13, 14, 15, and 17
- Enforces `license_allocations` target and quantity invariants

- [ ] **Step 1: Write failing domain constraint tests**

Create fixtures for one site, asset, product, metric, entitlement, and allocation. Assert:

```sql
select has_table('public', 'assets');
select has_table('public', 'software_products');
select has_table('public', 'license_entitlements');
select has_table('public', 'license_allocations');
select has_table('private', 'license_secrets');
select has_table('audit', 'audit_events');
select has_table('migration', 'import_batches');
```

Also assert case-insensitive active asset-code uniqueness, same-site computer-name uniqueness, MAC format checks, positive owned/allocation quantities, exactly one valid allocation target according to metric, site-scope integrity, and inability to hard-delete referenced master records.

- [ ] **Step 2: Run domain tests and observe RED**

Run: `npm run db:test -- supabase/tests/database/002_asset_license.test.sql`

Expected: FAIL because domain tables do not exist.

- [ ] **Step 3: Implement asset and software DDL**

Create `assets`, `asset_network_interfaces`, `asset_person_assignments`, `publishers`, `software_products`, and `asset_software_installations` with exact columns, metadata, checks, partial unique indexes, foreign keys, and archive behavior from `database.md`. Avoid denormalized allocated/license quantities on assets or installations.

- [ ] **Step 4: Implement license and operations DDL**

Create `vendors`, `license_entitlements`, `license_site_scopes`, `license_allocations`, `private.license_secrets`, `notifications`, `notification_recipients`, `audit.audit_events`, `system_settings`, and all migration import/reconciliation tables. Secret storage tables must expose neither plaintext secret nor Vault identifier through `public` objects.

License allocation constraints must require `quantity > 0`, a single target compatible with the selected metric, active/released timestamp consistency, and immutable history after release except trusted audit metadata.

- [ ] **Step 5: Reset and verify GREEN**

Run:

```powershell
npm run db:reset
npm run db:test -- supabase/tests/database/002_asset_license.test.sql
```

Expected: reset succeeds and all constraint tests pass.

- [ ] **Step 6: Commit operational schema**

```powershell
git add supabase/migrations/202609010003_asset_software.sql supabase/migrations/202609010004_license_operations.sql supabase/tests/database/002_asset_license.test.sql
git commit -m "feat: add asset and license database schema"
```

---

### Task 4: Derived Values, RPC Transactions, RLS, and Grants

**Files:**
- Create: `supabase/tests/database/003_security.test.sql`
- Create: `supabase/migrations/202609010005_derived_rpc.sql`
- Create: `supabase/migrations/202609010006_rls_grants.sql`

**Interfaces:**
- Produces: `public.license_compliance_v`
- Produces safe list/detail/report views named by `database.md` section 10.4
- Produces: `public.allocate_license(...)`, `public.release_license_allocation(...)`
- Produces approved admin mutation RPCs from `database.md` section 11.2
- Produces role-aware RLS and execution grants

- [ ] **Step 1: Write failing derived and security tests**

Use `set local role anon` and `set local role authenticated` with JWT claims fixtures for active user/admin profiles. Assert:

```sql
select throws_ok(
  $$ select * from public.assets $$,
  '42501',
  null,
  'anon cannot read assets'
);
select throws_ok(
  $$ insert into public.assets default values $$,
  '42501',
  null,
  'authenticated user has no direct DML'
);
```

Assert active user can select safe asset/license/report views, inactive user receives no rows, admin can execute approved RPCs, user cannot execute admin RPCs, and neither application role can access `private`, `audit`, or `migration` directly. Query `information_schema.role_table_grants` and `routine_privileges` to prove no accidental grants.

Create allocations totaling 3 against owned quantity 2 and assert `license_compliance_v` returns allocated `3`, available `-1`, and over-allocated status. Release one seat and assert active allocated quantity becomes `2` while history remains.

- [ ] **Step 2: Run security tests and observe RED**

Run: `npm run db:test -- supabase/tests/database/003_security.test.sql`

Expected: FAIL because views, RPCs, policies, or grants are absent.

- [ ] **Step 3: Implement derived views and transaction functions**

Derived quantities must use active `license_allocations`; lifecycle priority follows `database.md` section 10.3. All security-definer functions use an empty search path and fully qualified object names:

```sql
create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.app_role = 'admin'::public.app_role
      and p.account_status = 'active'::public.account_status
  );
$$;
```

RPCs must derive actor identity from `auth.uid()`, validate expected version, serialize allocation changes with a row lock on entitlement, enforce site/metric constraints, and insert redacted audit events in the same transaction.

- [ ] **Step 4: Implement RLS and explicit grants**

Enable and force RLS on operational tables where ownership bypass is not required. Revoke default table/function privileges first, grant authenticated SELECT only on approved safe surfaces, and grant EXECUTE per RPC contract. Revoke all schema/table/sequence/function privileges for application roles in `private`, `audit`, and `migration`. Keep `service_role` out of browser-facing contracts.

- [ ] **Step 5: Reset, test, and lint database**

Run:

```powershell
npm run db:reset
npm run db:test
npm run db:lint
```

Expected: reset succeeds, all pgTAP suites pass, and lint reports no security warnings introduced by these migrations.

- [ ] **Step 6: Generate database TypeScript types**

Run: `npm run db:types`

Expected: `src/lib/supabase/database.types.ts` contains `profiles`, safe public views, and approved RPC signatures, and contains no secret values.

- [ ] **Step 7: Commit the protected database contract**

```powershell
git add supabase/migrations/202609010005_derived_rpc.sql supabase/migrations/202609010006_rls_grants.sql supabase/tests/database/003_security.test.sql src/lib/supabase/database.types.ts
git commit -m "feat: enforce database authorization and license integrity"
```

---

### Task 5: Supabase SSR Client Factories and Proxy Refresh

**Files:**
- Create: `src/lib/supabase/client.ts`
- Create: `src/lib/supabase/server.ts`
- Create: `src/lib/supabase/proxy.ts`
- Create: `src/proxy.ts`
- Test: `src/lib/supabase/client.test.ts`
- Test: `src/lib/supabase/proxy.test.ts`

**Interfaces:**
- Produces: `createBrowserSupabaseClient(): SupabaseClient<Database>`
- Produces: `createServerSupabaseClient(): Promise<SupabaseClient<Database>>`
- Produces: `updateSupabaseSession(request: NextRequest): Promise<NextResponse>`
- Produces: Next.js `proxy(request)` with static matcher configuration

- [ ] **Step 1: Read the current SSR package types after installation**

Inspect `node_modules/@supabase/ssr` declarations and the installed Next.js `proxy`/`cookies` docs. Confirm cookie adapter signatures before writing tests; use `getAll`/`setAll` and `await cookies()`.

- [ ] **Step 2: Write failing client factory tests**

Mock only the external constructors and assert factories pass the validated URL/key, server cookie reads are forwarded, and server cookie writes tolerate Server Component read-only contexts without printing cookie values.

- [ ] **Step 3: Run client tests and observe RED**

Run: `npm test -- src/lib/supabase/client.test.ts`

Expected: FAIL because client/server factories do not exist.

- [ ] **Step 4: Implement browser and server factories**

Use `createBrowserClient<Database>` for browser code and a fresh `createServerClient<Database>` per server request. The server cookie adapter calls `(await cookies()).getAll()` and attempts `setAll`; it may ignore only the documented Server Component cookie-write limitation, not configuration/auth errors.

- [ ] **Step 5: Write failing Proxy tests**

Assert public `/login` remains reachable, protected routes without claims redirect to `/login?next=<encoded-path>`, authenticated requests preserve refreshed response cookies, and static/image assets do not match the Proxy config.

- [ ] **Step 6: Run Proxy tests and observe RED**

Run: `npm test -- src/lib/supabase/proxy.test.ts`

Expected: FAIL because refresh logic and `src/proxy.ts` do not exist.

- [ ] **Step 7: Implement Proxy refresh**

Create request/response cookie adapters, call `supabase.auth.getClaims()` immediately after client creation, and return the same response object containing refreshed cookies. Treat Proxy as an optimistic redirect only; do not query profiles or perform full authorization there.

- [ ] **Step 8: Verify SSR infrastructure GREEN and commit**

Run: `npm test -- src/lib/supabase/client.test.ts src/lib/supabase/proxy.test.ts`

Expected: PASS.

```powershell
git add src/lib/supabase/client.ts src/lib/supabase/server.ts src/lib/supabase/proxy.ts src/proxy.ts src/lib/supabase/client.test.ts src/lib/supabase/proxy.test.ts
git commit -m "feat: add Supabase SSR session infrastructure"
```

---

### Task 6: Verified Viewer and Server Authorization Guards

**Files:**
- Create: `src/features/auth/types.ts`
- Create: `src/features/auth/viewer.ts`
- Create: `src/features/auth/viewer.test.ts`
- Create: `src/features/auth/guards.ts`
- Create: `src/features/auth/guards.test.ts`

**Interfaces:**
- Produces: `Viewer { id: string; displayName: string; email: string; role: "admin" | "user" }`
- Produces: `loadViewer(): Promise<Viewer | null>`
- Produces: `requireViewer(): Promise<Viewer>`
- Produces: `requireAdmin(): Promise<Viewer>`

- [ ] **Step 1: Write failing viewer tests**

Inject a minimal auth/profile gateway into the pure resolver and test: missing claims returns `null`; missing profile returns `null`; inactive/locked status returns `null`; active profile maps only approved fields; unknown role is rejected.

- [ ] **Step 2: Run viewer tests and observe RED**

Run: `npm test -- src/features/auth/viewer.test.ts`

Expected: FAIL because viewer resolver does not exist.

- [ ] **Step 3: Implement verified viewer loading**

Call `auth.getClaims()`, take `sub` from verified claims, query `profiles` for `id, display_name, email, app_role, account_status`, require status `active`, and return the narrow `Viewer`. Do not expose raw Auth user, access token, profile metadata, or upstream error payload.

- [ ] **Step 4: Write failing guard tests**

Mock `loadViewer` and Next navigation control flow. Assert `requireViewer` redirects a missing viewer to `/login`; `requireAdmin` returns admin; `requireAdmin` rejects user without returning protected children.

- [ ] **Step 5: Run guard tests and observe RED**

Run: `npm test -- src/features/auth/guards.test.ts`

Expected: FAIL because guards do not exist.

- [ ] **Step 6: Implement guards and verify GREEN**

`requireViewer` redirects before returning. `requireAdmin` calls `requireViewer`, checks role, and returns an explicit forbidden result consumed by the admin layout rather than relying on hidden navigation.

Run: `npm test -- src/features/auth/viewer.test.ts src/features/auth/guards.test.ts`

Expected: PASS.

- [ ] **Step 7: Commit viewer authorization**

```powershell
git add src/features/auth
git commit -m "feat: resolve and authorize authenticated viewers"
```

---

### Task 7: Login and Logout Server Actions

**Files:**
- Create: `src/features/auth/actions.ts`
- Create: `src/features/auth/actions.test.ts`
- Create: `src/features/auth/login-form.tsx`
- Create: `src/features/auth/login-form.test.tsx`
- Create: `src/app/login/page.tsx`

**Interfaces:**
- Produces: `AuthActionState { error?: string; fieldErrors?: { email?: string; password?: string } }`
- Produces: `login(previousState: AuthActionState, formData: FormData): Promise<AuthActionState>`
- Produces: `logout(): Promise<never>`

- [ ] **Step 1: Write failing action tests**

Assert blank/invalid email and blank password return field errors without calling Supabase; valid credentials call `signInWithPassword({ email, password })`; any provider failure returns the same Thai generic error; success redirects to `/`; logout calls `signOut()` then redirects to `/login`. Ensure redirect is outside caught provider errors.

- [ ] **Step 2: Run action tests and observe RED**

Run: `npm test -- src/features/auth/actions.test.ts`

Expected: FAIL because actions do not exist.

- [ ] **Step 3: Implement minimal Server Actions**

Use a pure credential parser before the server orchestration. Return only user-safe messages:

```ts
export const initialAuthActionState: AuthActionState = {};
const invalidLoginMessage = "อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองอีกครั้ง";
```

Do not return Supabase errors, account-existence distinctions, tokens, or password values.

- [ ] **Step 4: Write failing Login Form tests**

Assert labels for Email/Password, password input type, submit button, accessible field errors, generic form error with `role="alert"`, and no Register link.

- [ ] **Step 5: Run form tests and observe RED**

Run: `npm test -- src/features/auth/login-form.test.tsx`

Expected: FAIL because the form does not exist.

- [ ] **Step 6: Implement login UI and public page**

Use `useActionState(login, initialAuthActionState)`, `useFormStatus` for pending copy, existing blue/gray/white visual tokens, autocomplete values `email` and `current-password`, and a Thai introduction for Thai Kurabo. Keep the login page outside App Shell.

- [ ] **Step 7: Verify auth actions/forms GREEN and commit**

Run: `npm test -- src/features/auth/actions.test.ts src/features/auth/login-form.test.tsx`

Expected: PASS.

```powershell
git add src/features/auth/actions.ts src/features/auth/actions.test.ts src/features/auth/login-form.tsx src/features/auth/login-form.test.tsx src/app/login/page.tsx
git commit -m "feat: add secure email password login"
```

---

### Task 8: Protected Route Groups and Server-Derived Role Context

**Files:**
- Create: `src/app/(protected)/layout.tsx`
- Create: `src/app/(protected)/(admin)/layout.tsx`
- Move: existing business pages/tests under `src/app/(protected)/`
- Move: `master-data`, `users`, `audit-logs`, and `settings` under `src/app/(protected)/(admin)/`
- Modify: `src/app/layout.tsx`
- Modify: `src/components/app-shell/role-provider.tsx`
- Modify: `src/components/app-shell/app-shell.tsx`
- Modify: `src/components/app-shell/topbar.tsx`
- Modify: `src/components/app-shell/sidebar.tsx`
- Modify: affected component/page tests

**Interfaces:**
- `RoleProvider({ viewer, children })`
- `useViewer(): Viewer`
- `useRole(): { role: Viewer["role"] }` retained temporarily only if existing consumers require it
- `AppShell({ viewer, children })`

- [ ] **Step 1: Write failing immutable viewer-context tests**

Replace sessionStorage-based expectations with a provider seeded by an admin/user `Viewer`. Assert context exposes identity/role, has no `setRole`, writes no sessionStorage, and sidebar navigation changes only from the provided viewer.

- [ ] **Step 2: Run shell tests and observe RED**

Run: `npm test -- src/components/app-shell`

Expected: FAIL because current provider has preview state and Topbar exposes a role selector.

- [ ] **Step 3: Implement immutable role/viewer shell**

Remove preview selector and `sam-preview-role` storage. Topbar displays viewer name/role and contains a logout form. Sidebar keeps admin filtering but replaces “UI Prototype / Mock data mode” with an authenticated-status card that does not claim Supabase is disconnected.

- [ ] **Step 4: Write failing protected/admin layout tests**

Assert protected layout calls `requireViewer` and seeds App Shell with the returned viewer. Assert admin layout renders children for admin and renders existing `AccessDenied` without children for user.

- [ ] **Step 5: Run layout tests and observe RED**

Run: `npm test -- src/app`

Expected: FAIL because route-group layouts do not exist and Root Layout still mounts App Shell globally.

- [ ] **Step 6: Move routes and implement layouts**

Move files without changing URL segments because parenthesized route groups are omitted from URLs. Root Layout retains only metadata, `<html>`, `<body>`, and global CSS. Protected Layout resolves viewer and mounts Role Provider/App Shell. Admin Layout performs server authorization before rendering admin children.

Update page tests to pass explicit viewer context only when testing client descendants directly; layout integration tests mock server guards at the module boundary.

- [ ] **Step 7: Verify route/shell GREEN and commit**

Run:

```powershell
npm test -- src/components/app-shell src/app
npm run lint
```

Expected: tests pass and lint has no role-preview/sessionStorage references.

```powershell
git add src/app src/components/app-shell
git commit -m "feat: protect application routes with Supabase roles"
```

---

### Task 9: Full Verification and Security Review

**Files:**
- Modify only files required to fix failures demonstrated by the checks below
- Update: `README.md` with safe local setup commands and environment variable names

**Interfaces:**
- Produces reproducible setup instructions without credentials
- Produces verification evidence for database and application layers

- [ ] **Step 1: Write the README verification section**

Document: copy `.env.example` to `.env.local`; fill only URL/publishable key; start Docker; run `npm run supabase:start`; run `npm run db:reset`; run `npm run db:test`; run `npm run dev`. State explicitly that hosted migration uses `supabase db push --dry-run` then `supabase db push` only after a separate secure link/login step, and that `db reset --linked` is not part of this workflow.

- [ ] **Step 2: Scan for leaked credentials and forbidden patterns**

Run:

```powershell
rg -n "service_role|sb_secret_|SUPABASE_SECRET|eyJhbGci" . -g "!Supabase.com.txt" -g "!node_modules/**" -g "!.git/**"
rg -n "sam-preview-role|setRole|sessionStorage" src
```

Expected: no committed credential/token patterns and no preview-role persistence. Documentation may mention forbidden variable names only when explaining policy; inspect every match.

- [ ] **Step 3: Run the full database suite from a clean state**

Run:

```powershell
npm run db:reset
npm run db:test
npm run db:lint
```

Expected: all commands exit 0.

- [ ] **Step 4: Run the full application suite**

Run:

```powershell
npm test
npm run lint
npm run build
```

Expected: all commands exit 0 with no test warnings or TypeScript/build errors.

- [ ] **Step 5: Inspect the production client output**

Search `.next` for the configured variable names and confirm only public URL/publishable values can be included. Confirm no server-only key name, service-role token, login password, or license secret exists in output/log files.

- [ ] **Step 6: Review Git diff and commit documentation/final fixes**

Run:

```powershell
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors, no `.env.local`, no Supabase CLI state, and no unrelated user files staged.

```powershell
git add README.md
git commit -m "docs: document Supabase local workflow"
```

- [ ] **Step 7: Stop local services without deleting local data**

Run: `npm run supabase:stop`

Expected: local containers stop normally; do not use destructive `--no-backup`.
