import { LockKeyhole } from "lucide-react";

export function AccessDenied() {
  return (
    <section className="grid min-h-[55vh] place-items-center rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm">
      <div>
        <span className="mx-auto grid size-16 place-items-center rounded-2xl bg-red-50 text-red-700">
          <LockKeyhole aria-hidden="true" size={28} />
        </span>
        <h1 className="mt-5 text-2xl font-bold text-slate-950">ไม่มีสิทธิ์เข้าถึง</h1>
        <p className="mt-2 text-sm text-slate-500">เมนูนี้สงวนไว้สำหรับผู้ดูแลระบบ</p>
      </div>
    </section>
  );
}