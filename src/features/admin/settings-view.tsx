import type { Role } from "@/features/sam/types";
import { Button } from "@/components/ui/button";
import { AccessDenied } from "./access-denied";

export function SettingsView({ role }: { role: Role }) {
  if (role !== "admin") return <AccessDenied />;
  return <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"><div className="border-b border-slate-100 pb-5"><h2 className="text-lg font-bold text-slate-950">General & security settings</h2><p className="mt-1 text-sm text-slate-500">ค่า UI ตัวอย่างยังไม่ถูกบันทึก</p></div><form className="mt-6 grid gap-5 md:grid-cols-2"><Setting label="Organization name" value="Thai Kurabo Co., Ltd." /><Setting label="Timezone" value="Asia/Bangkok" /><Setting label="Session timeout (minutes)" value="30" /><Setting label="Expiration threshold (days)" value="90" /><Setting label="Visible License Key characters" value="5" /><label className="flex items-center justify-between rounded-xl border border-slate-200 p-4 text-sm font-semibold text-slate-700">Block over-allocation<input type="checkbox" defaultChecked className="size-5 accent-blue-600" /></label><div className="md:col-span-2"><Button type="button">บันทึกการตั้งค่า (Demo)</Button></div></form></section>;
}
function Setting({ label, value }: { label: string; value: string }) { return <label className="space-y-1.5 text-sm font-semibold text-slate-700">{label}<input aria-label={label} defaultValue={value} className="h-11 w-full rounded-xl border border-slate-200 px-3 font-normal focus:border-blue-400 focus:outline-none" /></label>; }
