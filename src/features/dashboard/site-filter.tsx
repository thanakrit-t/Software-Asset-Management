import type { Site } from "@/features/sam/types";
import { cn } from "@/lib/cn";

export type SiteFilterValue = "all" | Site["id"];

export function SiteFilter({ value, onChange }: { value: SiteFilterValue; onChange: (value: SiteFilterValue) => void }) {
  const options: Array<{ value: SiteFilterValue; label: string }> = [
    { value: "all", label: "All Sites" },
    { value: "factory", label: "Factory" },
    { value: "bangkok-office", label: "Bangkok Office" },
  ];
  return (
    <div role="group" aria-label="กรองข้อมูลตาม Site" className="flex flex-wrap gap-1 rounded-xl border border-slate-200 bg-white p-1 shadow-sm">
      {options.map((option) => (
        <button key={option.value} type="button" onClick={() => onChange(option.value)} aria-pressed={value === option.value} className={cn("min-h-9 rounded-lg px-3 text-xs font-semibold transition", value === option.value ? "bg-blue-600 text-white shadow-sm" : "text-slate-600 hover:bg-slate-100")}>
          {option.label}
        </button>
      ))}
    </div>
  );
}
