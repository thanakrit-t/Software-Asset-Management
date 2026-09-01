# Software Asset Management

ระบบบริหาร Asset และ Software License ของ Thai Kurabo แบบฐานข้อมูลกลาง แยก Asset ออกจาก License และรองรับหลาย Site เช่น Factory และ Bangkok Office ตาม [PRD.md](./PRD.md) และ [database.md](./database.md)

## Current scope

- Next.js 16 App Router, React 19, TypeScript และ Tailwind CSS 4
- Supabase Auth แบบ email/password พร้อม cookie session, protected routes และ logout
- สิทธิ์ `admin` และ `user` อ่านจาก `public.profiles`; ไม่มีตัวสลับ role ใน browser
- PostgreSQL migrations, RLS, RPC, safe views, audit และ initial-import staging สำหรับ Excel
- หน้าจอธุรกิจยังอ่าน mock repository และฟอร์มบางส่วนยังไม่ persist; schema และ auth พร้อมแล้วสำหรับเชื่อม data adapter ในระยะถัดไป

## Safe local setup

ต้องมี Node.js, npm, Docker Desktop และ Docker engine ที่กำลังทำงาน

```powershell
npm install
Copy-Item .env.example .env.local
```

กำหนดเฉพาะ public configuration ใน `.env.local`:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
```

ห้ามเก็บ server secret/service key, database password หรือ user password ใน `.env.local`, source code, เอกสาร หรือ Git หากเคยส่ง credential ผ่านข้อความหรือไฟล์ที่ไม่ปลอดภัย ให้ rotate/disable ก่อนใช้ hosted project

เริ่ม Supabase local และสร้างฐานข้อมูลใหม่จาก migrations/seed:

```powershell
npm run supabase:start
npm run db:reset
npm run db:test
npm run db:lint
npm run dev
```

เปิดแอปที่ `http://localhost:3000` และ Supabase Studio ตาม URL ที่ CLI แสดง ผู้ใช้ต้องถูกสร้างหรือเชิญผ่านช่องทาง Supabase ที่เชื่อถือได้; trigger จะสร้าง profile เริ่มต้นเป็น role `user` และ status `active` โดยอัตโนมัติ การตั้ง admin คนแรกต้องทำผ่าน trusted database operation เท่านั้น

## Verification

```powershell
npm run db:reset
npm run db:test
npm run db:lint
npm test
npm run lint
npm run build
```

หยุด local services โดยเก็บข้อมูล local ไว้:

```powershell
npm run supabase:stop
```

## Hosted migration

การ deploy ไป hosted project ไม่ทำอัตโนมัติจาก local setup นี้ หลัง rotate credential ที่เคยเปิดเผยแล้ว ให้ login/link Supabase CLI ด้วยช่องทางที่ปลอดภัย จากนั้นตรวจ dry run ก่อน push จริง:

```powershell
npx supabase login
npx supabase link --project-ref <project-ref>
npx supabase db push --dry-run
npx supabase db push
```

ห้ามใช้ `supabase db reset --linked` ใน workflow นี้ เพราะเป็นคำสั่ง destructive ต่อฐานข้อมูลที่ link อยู่ หลัง deploy ให้ provision admin/user ผ่านช่องทางที่เชื่อถือได้และทดสอบ session กับ RLS ทั้งสอง role ก่อนเปิดใช้งาน

## Data boundary

Excel ต้นฉบับใช้เป็นแหล่งข้อมูลสำหรับ initial migration เพียงครั้งเดียว ไม่ใช่ฐานข้อมูล runtime ตารางใน schema `migration` ใช้ staging/reconciliation และตรวจข้อมูลซ้ำด้วย exact match ตามข้อตกลง

ขณะนี้ข้อมูลตัวอย่างของหน้าจออยู่ใน `src/features/sam/mock-data.ts` และไม่มี License Key จริง การอ่านผ่าน repository boundary ช่วยให้เปลี่ยนเป็น Supabase adapter ภายหลังโดยไม่เปลี่ยน URL ของหน้า
