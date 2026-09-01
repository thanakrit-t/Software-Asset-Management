import Link from "next/link";
import { AlertTriangle, ArrowUpRight, BellRing, Info } from "lucide-react";
import type { NotificationItem } from "@/features/sam/types";
import { cn } from "@/lib/cn";

const severity = {
  critical: { icon: AlertTriangle, className: "bg-red-50 text-red-700 ring-red-100" },
  warning: { icon: BellRing, className: "bg-amber-50 text-amber-700 ring-amber-100" },
  info: { icon: Info, className: "bg-blue-50 text-blue-700 ring-blue-100" },
};

export function AttentionPanel({ notifications }: { notifications: NotificationItem[] }) {
  return (
    <section className="rounded-2xl border border-slate-200/80 bg-white shadow-sm">
      <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
        <div>
          <h2 className="font-bold text-slate-950">รายการที่ต้องตรวจสอบ</h2>
          <p className="mt-0.5 text-xs text-slate-500">เรียงตามระดับความสำคัญล่าสุด</p>
        </div>
        <Link href="/notifications" className="flex min-h-10 items-center gap-1 text-sm font-semibold text-blue-700 hover:text-blue-900">
          ดูทั้งหมด <ArrowUpRight aria-hidden="true" size={16} />
        </Link>
      </div>
      <div className="divide-y divide-slate-100 px-5">
        {notifications.length ? notifications.slice(0, 4).map((item) => {
          const Icon = severity[item.severity].icon;
          return (
            <Link key={item.id} href={`/${item.entityType === "asset" ? "assets" : "licenses"}/${item.entityId}`} className="flex gap-3 py-4 transition hover:bg-slate-50/70">
              <span className={cn("grid size-10 shrink-0 place-items-center rounded-xl ring-1", severity[item.severity].className)}><Icon aria-hidden="true" size={18} /></span>
              <span className="min-w-0">
                <span className="block text-sm font-semibold text-slate-900">{item.title}</span>
                <span className="mt-1 block text-xs leading-5 text-slate-500">{item.message}</span>
              </span>
            </Link>
          );
        }) : <p className="py-12 text-center text-sm text-slate-500">ยังไม่มีการแจ้งเตือน</p>}
      </div>
    </section>
  );
}

