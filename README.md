# Software Asset Management

UI prototype สำหรับบริหาร Asset, Software Product, License Entitlement และ License Allocation ตาม [PRD.md](./PRD.md)

## Tech stack

- Next.js 16 App Router
- React 19 + TypeScript
- Tailwind CSS 4
- Vitest + React Testing Library
- Recharts และ Lucide React
- Supabase เป็นเป้าหมายของระยะถัดไป แต่ยังไม่มีการเชื่อมต่อในรอบ UI นี้

## Run locally

```bash
npm install
npm run dev
```

เปิด `http://localhost:3000` แล้วใช้ตัวเลือก `Preview` ด้านบนเพื่อสลับระหว่าง Admin และ User

## Verification

```bash
npm test
npm run lint
npm run build
```

## Data boundary

ข้อมูลทั้งหมดอยู่ใน `src/features/sam/mock-data.ts` และเป็นข้อมูลสมมติที่ได้แรงบันดาลใจจากโครงสร้าง Excel เท่านั้น ไม่ใช่ข้อมูล License Key จริง การอ่านข้อมูลผ่าน `SamRepository` ใน `src/features/sam/repository.ts` ทำให้สามารถเพิ่ม Supabase adapter ภายหลังโดยไม่เปลี่ยน UI routes

ฟอร์มและปุ่ม Export ในเวอร์ชันนี้เป็น UI-only และไม่ persist ข้อมูล
