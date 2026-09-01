import type { LucideIcon } from "lucide-react";
import { ArrowDownRight, ArrowUpRight } from "lucide-react";
import { cn } from "@/lib/cn";

interface KpiCardProps {
  label: string;
  value: string;
  hint: string;
  icon: LucideIcon;
  tone?: "blue" | "green" | "amber" | "red" | "slate";
  trend?: "up" | "down";
}

const tones = {
  blue: "bg-blue-50 text-blue-700 ring-blue-100",
  green: "bg-emerald-50 text-emerald-700 ring-emerald-100",
  amber: "bg-amber-50 text-amber-700 ring-amber-100",
  red: "bg-red-50 text-red-700 ring-red-100",
  slate: "bg-slate-100 text-slate-700 ring-slate-200",
};

export function KpiCard({ label, value, hint, icon: Icon, tone = "blue", trend }: KpiCardProps) {
  const TrendIcon = trend === "down" ? ArrowDownRight : ArrowUpRight;
  return (
    <article className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm shadow-slate-950/[0.03]">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-medium text-slate-500">{label}</p>
          <p className="mt-2 text-3xl font-bold tracking-tight text-slate-950">{value}</p>
        </div>
        <span className={cn("grid size-11 place-items-center rounded-xl ring-1", tones[tone])}>
          <Icon aria-hidden="true" size={21} />
        </span>
      </div>
      <p className="mt-4 flex items-center gap-1.5 text-xs leading-5 text-slate-500">
        {trend ? <TrendIcon aria-hidden="true" className={trend === "up" ? "text-emerald-600" : "text-red-600"} size={15} /> : null}
        {hint}
      </p>
    </article>
  );
}
