# Supabase Database and Authentication Design

## 1. Objective

เชื่อมระบบ Software Asset Management เข้ากับ Supabase เป็นสองช่วงตามลำดับ:

1. สร้าง PostgreSQL migration ที่ทำให้แบบฐานข้อมูลใน `database.md` อยู่ภายใต้ version control และพร้อมตรวจสอบด้วย automated tests
2. เชื่อม Next.js 16 App Router กับ Supabase Auth โดยใช้ session จริงและ role จาก `public.profiles` แทนตัวเลือก role สำหรับ preview ใน browser

งานรอบนี้ยังไม่เปลี่ยนหน้าธุรกิจทั้งหมดจาก Mock Repository ไปอ่านและเขียน operational data จริง การเปลี่ยน repository เป็นงานถัดไปหลัง schema, RLS และ authentication ผ่านการตรวจสอบแล้ว

## 2. Approved Scope

### Included

- Supabase CLI project structure และ SQL migrations
- Schemas: `public`, `private`, `audit`, `migration`
- Extensions, enums, operational tables, migration staging tables, constraints และ indexes ตาม `database.md`
- Timestamp/version triggers, safe views, authorization helpers และ RPC contracts ที่จำเป็นต่อ MVP
- RLS, grants และ default privileges สำหรับ `anon`, `authenticated` และ database roles ภายใน
- Seed master data รวม Factory และ Bangkok Office
- Database tests สำหรับ constraints, derived quantities, admin/user permissions และ sensitive-data boundaries
- Supabase SSR clients สำหรับ browser, Server Components และ Route Handlers/Server Actions
- Email/password login, cookie session refresh, logout และ protected application routes
- Role และ account status จาก `public.profiles`
- Server-side admin route enforcement และ role-aware navigation
- Environment variable template โดยไม่มี credential จริง
- Unit/component tests สำหรับ auth mapping, redirects, role behavior และ login error handling

### Excluded

- Public registration
- Username login
- Active Directory, Entra ID หรือ SSO
- Auth Admin API สำหรับ invite/reset/user provisioning UI
- การ deploy migration ไป hosted project โดยอัตโนมัติ
- การอ่าน credential จาก `Supabase.com.txt`
- การเก็บ publishable, secret หรือ service-role key ใน Git
- การแทน `mockSamRepository` ด้วย Supabase repository สำหรับ Assets, Licenses, Allocations, Reports และ Dashboard
- การ import Excel จริงและ production cutover
- UI สำหรับเปิดดู license secret ฉบับเต็ม

## 3. Key Decisions

### 3.1 Delivery approach

ใช้แนวทาง schema-first แล้วตามด้วย authentication integration ซึ่งตรงกับลำดับที่อนุมัติ:

1. สร้างและทดสอบฐานข้อมูลก่อน เพื่อให้ role และ profile ที่ authentication ต้องพึ่งพามี contract ที่แน่นอน
2. เชื่อม authentication บน contract ดังกล่าว
3. คงข้อมูล UI จาก mock ไว้ชั่วคราว เพื่อไม่รวม data-access migration ขนาดใหญ่ไว้ในงาน security foundation

แนวทาง vertical slice ที่สร้างเฉพาะ `profiles` แล้วเชื่อม auth ก่อนถูกตัดออก เพราะจะทำให้ migrations ชุดแรกไม่ตรงกับ source-of-truth ใน `database.md` และเพิ่มการแก้ schema ซ้ำในภายหลัง ส่วนการรัน SQL ด้วยมือใน Dashboard ถูกตัดออกเพราะตรวจย้อนหลังและทำซ้ำระหว่าง environment ได้ยาก

### 3.2 Authentication method

- ใช้ Supabase Auth แบบ Email/Password
- ไม่มีหน้า Register และไม่เปิด public sign-up จาก UI
- บัญชีต้องถูกสร้างหรือเชิญโดยผู้ดูแลผ่านช่องทาง Supabase ที่เชื่อถือได้
- การอนุญาตทำงานใช้ `public.profiles.app_role` และ `account_status` เท่านั้น
- ไม่ใช้ `raw_user_meta_data` เป็น authorization source
- `admin` เข้าถึงเมนูทั้งหมด ส่วน `user` เข้าถึงเฉพาะหน้าดูข้อมูลและรายงาน

### 3.3 Key handling

- Browser และ SSR client ใช้ Project URL กับ publishable key เท่านั้น
- ชื่อตัวแปรคือ `NEXT_PUBLIC_SUPABASE_URL` และ `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- ไม่มี secret/service-role key ใน code, `.env.example`, test fixture, client bundle หรือ log
- งานที่ต้องใช้ Auth Admin API ในอนาคตต้องใช้ server-only secret key แยกต่างหาก และไม่ใช้ prefix `NEXT_PUBLIC_`
- Credential ที่เคยถูกเปิดเผยจะไม่ถูกอ่านจากไฟล์หรือใช้ใน implementation นี้

## 4. Database Architecture

### 4.1 Migration layout

สร้างไฟล์ภายใต้ `supabase/migrations/` ตาม dependency order:

1. Foundation: extensions, schemas, enum types, privilege baseline และ shared helpers
2. Identity and master data: profiles, people, sites, locations, departments และ master tables
3. Asset and software: assets, network interfaces, assignments, publishers, products และ installations
4. License and secret boundary: entitlements, site scopes, allocations และ private secret metadata
5. Operations: notifications, audit events, settings และ migration staging/reconciliation tables
6. Derived layer: views, indexes และ calculation helpers
7. RPC and triggers: mutation contracts, optimistic locking, allocation transactions และ audit hooks
8. RLS and grants: policies, function execution grants และ direct-DML restrictions
9. Seed data: deterministic master records และ two initial sites

ทุก migration ต้องเป็น deterministic และรันบนฐานข้อมูลว่างได้ตามลำดับ ห้ามอาศัย object ที่สร้างด้วยมือใน hosted Dashboard

### 4.2 Schema boundary

- `public`: operational tables, safe views และ approved RPC entry points
- `private`: license-secret metadata และ security helpers ที่ไม่เปิดผ่าน Data API
- `audit`: append-only events ซึ่ง application อ่านผ่าน safe admin surface เท่านั้น
- `migration`: initial-import staging และ reconciliation ซึ่งไม่มี grant แก่ application roles
- `auth`: จัดการโดย Supabase และอ้างถึงเฉพาะ contract ที่รองรับ เช่น `auth.users(id)`

### 4.3 Identity bootstrap

Trigger หลัง `auth.users` insert สร้าง `public.profiles` ด้วยค่าปลอดภัย:

- `id` เท่ากับ `auth.users.id`
- `email` มาจาก normalized Auth email
- `display_name` ใช้ชื่อจาก trusted provisioning metadata ถ้ามี มิฉะนั้นใช้ส่วนก่อน `@`
- `app_role` เริ่มต้นเป็น `user`
- `account_status` เริ่มต้นเป็น `active`

การยกระดับเป็น `admin` ต้องทำผ่าน trusted database operation เท่านั้น ห้ามให้ผู้ใช้แก้ role หรือ account status ของตนเอง

### 4.4 Authorization helpers and RLS

Database helpers อ่าน `auth.uid()` แล้ว resolve profile ปัจจุบันโดยไม่รับ user ID จาก client ใช้ helper อย่างน้อยสำหรับ:

- ตรวจว่ามี session และ profile active
- ตรวจ role `admin`
- ปฏิเสธ inactive/locked account

Policy baseline:

- `anon`: ไม่มีสิทธิ์อ่าน operational tables
- active `user`: `select` เฉพาะข้อมูล non-sensitive และ safe views ที่กำหนด
- active `admin`: อ่านข้อมูล operational ทั้งหมด แต่ mutation สำคัญผ่าน RPC
- `authenticated`: ไม่มี direct DML บน operational tables ที่กำหนดให้ใช้ RPC
- `private`, `audit`, `migration`: ไม่มี grants แก่ `anon` หรือ `authenticated`
- การแสดง license secret เต็มไม่อยู่ใน scope และไม่มี public view ที่เปิดเผย secret reference, fingerprint หรือ Vault identifier

### 4.5 Derived quantities and allocation integrity

`license_allocations` เป็น source of truth ของ allocated quantity โดยนับเฉพาะ active allocation ตามกฎใน `database.md` Safe view คำนวณ:

- owned quantity
- allocated quantity
- available quantity
- over-allocation state
- lifecycle status จากวันเริ่ม/สิ้นสุดและ threshold

Allocation RPC ทำงานใน transaction เดียว ตรวจ entitlement, target type, quantity, site scope, archive status และ optimistic version ก่อนเขียนข้อมูล

### 4.6 Seeds

Seed ใช้ stable UUID values เพื่อให้ local, test และ hosted environment อ้างอิงรายการเดียวกันได้ โดยอย่างน้อยมี:

- Sites: `FACTORY`, `BANGKOK_OFFICE`
- Asset types และ statuses ที่ UI ใช้
- Internet levels
- Software categories
- License metrics
- Product classifications
- Purchase forms
- Default expiration thresholds
- Default system settings ที่ไม่ใช่ secret

Seed ต้องใช้ conflict-safe statements เพื่อให้ reset/replay ให้ผลเหมือนเดิม

## 5. Next.js Authentication Architecture

### 5.1 Supabase client boundaries

แยก factory ตาม execution environment:

- Browser client สำหรับ event จากหน้า login/logout ที่จำเป็น
- Server client สำหรับ Server Components, Server Actions และ Route Handlers โดยอ่าน/เขียน cookies ผ่าน API ของ Next.js 16
- Session-refresh layer สำหรับต่ออายุ auth cookies และ redirect ผู้ใช้ที่ไม่มี session

ไม่มี singleton server client เพราะ cookies และ session เป็น request-scoped

### 5.2 Route groups

โครงสร้าง App Router แบ่งเป็น:

- Auth route: `/login` แสดงนอก App Shell
- Protected application routes: dashboard, assets, software, licenses, allocations, reports และ notifications
- Admin-only routes: master data, users, settings และ audit logs

Root layout เก็บเฉพาะ global HTML/styles ส่วน protected layout รับ verified viewer แล้วประกอบ Role Provider และ App Shell วิธีนี้ป้องกัน login page แสดง sidebar ชั่วคราว และไม่พึ่ง client hydration เพื่อบังคับสิทธิ์

### 5.3 Session and viewer resolution

Server-side viewer loader:

1. ขอ Auth user จาก Supabase server client
2. ถ้าไม่มี user ให้ redirect ไป `/login`
3. อ่าน profile ของ user ปัจจุบัน
4. ถ้า profile ไม่มีหรือ status ไม่ใช่ `active` ให้ sign out/redirect พร้อมข้อความทั่วไป
5. คืนค่า viewer ที่มีเฉพาะ `id`, `displayName`, `email` และ `role`

Role Provider เปลี่ยนจาก sessionStorage preview เป็น initial viewer ที่ server ส่งให้ ไม่มี role switcher ใน production flow

### 5.4 Login and logout flow

Login ใช้ Server Action เพื่อรับ email/password, validate input และเรียก `signInWithPassword` ผลลัพธ์ผิดพลาดแสดงข้อความทั่วไปที่ไม่บอกว่า email มีอยู่หรือไม่ เมื่อสำเร็จให้ redirect ไปหน้า dashboard

Logout ใช้ Server Action เรียก `signOut`, ล้าง session ผ่าน Supabase SSR cookie handling และ redirect ไป `/login`

### 5.5 Route authorization

- Session-refresh layer ป้องกัน request ที่ไม่มี sessionในระดับกว้าง
- Protected layout ตรวจ viewer อีกครั้งด้วยข้อมูลที่เชื่อถือได้จาก server
- Admin layout ตรวจ `viewer.role === "admin"`; ผู้ใช้ทั่วไปได้รับหน้า Access Denied หรือ redirect ตาม pattern ปัจจุบัน
- Sidebar ใช้ server-derived role เพื่อซ่อนเมนู admin แต่การซ่อนเมนูไม่ถือเป็น security boundary
- RLS เป็น security boundary สุดท้ายสำหรับข้อมูลในฐานข้อมูล

## 6. Component and Module Boundaries

แต่ละหน่วยมีหน้าที่เดียว:

- Environment module: validate public Supabase configuration และให้ error ที่อ่านเข้าใจได้เมื่อยังไม่ตั้งค่า
- Browser/server Supabase factories: สร้าง client ตาม environment
- Auth actions: login/logout orchestration และ user-safe errors
- Viewer loader: แปลง Auth user + profile เป็น application viewer
- Authorization helpers: require authenticated viewer และ require admin
- Auth UI: form state, accessible validation และ pending state
- Role context: expose viewer role ให้ client navigation/components โดยไม่มี persistence ของตนเอง
- SQL migrations: แยกตาม dependency/domain ไม่รวมทุก object ไว้ไฟล์เดียว
- Database tests: แยก constraint/derived-data ออกจาก RLS/security tests

## 7. Error Handling

- Missing public environment variables: fail fast ฝั่ง server ด้วยข้อความระบุชื่อตัวแปร แต่ไม่พิมพ์ค่า
- Invalid credentials: แสดงข้อความทั่วไปภาษาไทยและไม่แยก unknown email จาก wrong password
- Missing profile/inactive account: ปฏิเสธการเข้าใช้งานและไม่เปิดเผย profile data
- Supabase unavailable: แสดง error state ที่ลองใหม่ได้ ไม่แสดง stack trace หรือ upstream payload
- Unauthorized admin route: ไม่ render children และไม่พึ่ง client-side redirect อย่างเดียว
- Migration failure: transaction ของ migration นั้น rollback และ Supabase CLI แสดง migration version ที่ล้มเหลว
- Constraint/RPC error: ใช้ business error code ที่นิยามใน `database.md`; UI mapping เชิงธุรกิจทำในงาน repository integration ถัดไป

## 8. Testing Strategy

### 8.1 Database tests

ทดสอบบน local Supabase reset database:

- ทุก migration รันจากฐานข้อมูลว่างได้
- seed มีสอง site และไม่เกิดข้อมูลซ้ำเมื่อ replay ด้วยกลไกที่รองรับ
- unique/check/foreign-key constraints สำคัญทำงาน
- allocation-derived totals ถูกต้องเมื่อ allocate/release
- user อ่าน safe operational data ได้แต่เขียนไม่ได้
- admin ใช้ approved RPC ได้
- anon อ่าน operational dataไม่ได้
- authenticated roles อ่าน `private`, `audit` และ `migration` โดยตรงไม่ได้
- ไม่มี safe view ส่งคืน secret metadata
- profile bootstrap ใช้ default role `user`

### 8.2 Application tests

ใช้ Vitest และ Testing Library ตามโครงสร้างปัจจุบัน:

- environment validation ไม่รั่วค่าของ key
- viewer mapping คืน role/status ที่ถูกต้อง
- unauthenticated access redirect ไป login
- inactive profile ถูกปฏิเสธ
- user เข้า admin guard ไม่ได้
- server-derived role ทำให้ Sidebar แสดงเมนูถูกต้อง
- login validation ปฏิเสธ input ไม่ครบก่อนเรียก Supabase
- login failure ใช้ข้อความทั่วไป
- logout flow ไป `/login`

### 8.3 Verification commands

- `npm test`
- `npm run lint`
- `npm run build`
- `npx supabase db reset` เมื่อ Supabase CLI และ local Docker พร้อมใช้งาน
- database test command ที่กำหนดใน Supabase config หลัง test files ถูกสร้าง

หาก environment ไม่มี Docker หรือยังไม่ได้ authenticate Supabase CLI ให้รายงาน database verification ส่วนที่รันไม่ได้อย่างชัดเจน โดยยังคงรัน static SQL checks และ application verification ที่ทำได้

## 9. Deployment and Rollback

### Deployment

1. Rotate/disable credential ที่เคยเปิดเผยก่อนใช้งาน hosted project
2. สร้าง publishable key และกำหนด environment variables ใน local/hosting platform
3. ตรวจ migrations ด้วย local reset และ database tests
4. เชื่อม Supabase CLI กับ project ผ่าน interactive login หรือ secure CI secret ที่อยู่นอก repository
5. ตรวจ migration diff แล้ว deploy ไป staging/hosted project
6. สร้าง admin คนแรกผ่าน trusted provisioning และเปลี่ยน role ผ่าน approved operation
7. ทดสอบ admin/user session และ RLS ก่อนเปิดให้ใช้งาน

### Rollback

- ก่อนมี production data สามารถ reset environment แล้ว replay migration ที่แก้ไขแล้วได้
- หลังมี production data ห้ามแก้ migration ที่ deploy แล้ว ให้สร้าง forward-fix migration ใหม่
- Schema change ที่ลบ/เปลี่ยนชนิดข้อมูลต้องใช้ expand-migrate-contract และ backup ก่อน deploy
- Auth integration rollback ทำได้โดย revert application deployment แต่ไม่ลดระดับ RLS หรือเปิด direct grants เพื่อแก้ปัญหาชั่วคราว

## 10. Acceptance Criteria

- Repository ไม่มี project key หรือ secret จริง และ `.env.example` มีเฉพาะชื่อกับค่าตัวอย่าง
- Supabase migrations สร้าง schemas/tables/views/functions/policies/seeds ตาม approved database design และ dependency order
- Database tests พิสูจน์ว่า anon ถูกปฏิเสธ, user อ่านอย่างเดียว และ admin ใช้ mutation contract ที่อนุมัติ
- License-sensitive metadata ไม่ปรากฏผ่าน public safe views หรือ grants
- ผู้ใช้ไม่มี session เปิด protected URL แล้วถูกส่งไป `/login`
- ผู้ใช้ active login ด้วย email/password แล้วเข้า application ได้
- Role ใน UI มาจาก profile ที่ server ตรวจแล้ว ไม่มี sessionStorage role override
- User ไม่สามารถเข้า admin routes แม้พิมพ์ URL โดยตรง
- Admin เห็นและเข้า admin routes ได้
- Logout ทำลาย application session และกลับไป `/login`
- Existing application tests, lint และ production build ผ่าน หรือมีการระบุ environmental blocker พร้อมหลักฐานคำสั่งที่ล้มเหลว

