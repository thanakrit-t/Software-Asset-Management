import { cn } from "@/lib/cn";

const styles: Record<string, string> = {
  active: "bg-emerald-50 text-emerald-700 ring-emerald-100",
  compliant: "bg-emerald-50 text-emerald-700 ring-emerald-100",
  spare: "bg-blue-50 text-blue-700 ring-blue-100",
  repair: "bg-amber-50 text-amber-700 ring-amber-100",
  "expiring-soon": "bg-amber-50 text-amber-700 ring-amber-100",
  retired: "bg-slate-100 text-slate-600 ring-slate-200",
  deactivated: "bg-slate-100 text-slate-600 ring-slate-200",
  expired: "bg-red-50 text-red-700 ring-red-100",
  "over-allocated": "bg-red-50 text-red-700 ring-red-100",
  untracked: "bg-violet-50 text-violet-700 ring-violet-100",
};

const labels: Record<string, string> = {
  active: "Active", compliant: "Compliant", spare: "Spare", repair: "Repair",
  "expiring-soon": "Expiring soon", retired: "Retired", deactivated: "Deactivated",
  expired: "Expired", "over-allocated": "Over-allocated", untracked: "Untracked",
};

export function StatusBadge({ status, label }: { status: string; label?: string }) {
  return <span className={cn("inline-flex items-center rounded-full px-2.5 py-1 text-xs font-bold ring-1 ring-inset", styles[status] ?? styles.retired)}>{label ?? labels[status] ?? status}</span>;
}
