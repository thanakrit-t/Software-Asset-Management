import type { Metadata } from "next";
import { LogoMark } from "@/components/ui/logo-mark";
import { LoginForm } from "@/features/auth/login-form";

export const metadata: Metadata = { title: "เข้าสู่ระบบ" };

export default function LoginPage() {
  return (
    <main className="grid min-h-screen place-items-center bg-slate-100 px-4 py-10">
      <section className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-7 shadow-xl shadow-slate-900/10 sm:p-9">
        <div className="mb-8 flex items-center gap-4">
          <LogoMark />
          <div>
            <p className="text-sm font-bold text-blue-700">Thai Kurabo</p>
            <h1 className="text-xl font-bold text-slate-950">Software Asset Management</h1>
          </div>
        </div>
        <p className="mb-6 text-sm leading-6 text-slate-600">
          เข้าสู่ระบบด้วยบัญชีที่ผู้ดูแลระบบจัดเตรียมให้
        </p>
        <LoginForm />
      </section>
    </main>
  );
}
