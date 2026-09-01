"use client";

import { useState } from "react";
import { Eye, EyeOff, ShieldAlert } from "lucide-react";
import type { Role } from "@/features/sam/types";
import { maskLicenseKey } from "@/features/sam/formatters";

export function LicenseKey({ value, role, label = "License Key" }: { value: string; role: Role; label?: string }) {
  const [revealed, setRevealed] = useState(false);
  const canReveal = role === "admin";
  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-2"><code className="rounded-lg bg-slate-100 px-2.5 py-1.5 text-xs font-semibold text-slate-700">{canReveal && revealed ? value : maskLicenseKey(value)}</code>{canReveal ? <button type="button" aria-label={revealed ? `ซ่อน ${label}` : `แสดง ${label}`} onClick={() => setRevealed((current) => !current)} className="grid size-9 place-items-center rounded-lg text-slate-500 hover:bg-slate-100">{revealed ? <EyeOff aria-hidden="true" size={17} /> : <Eye aria-hidden="true" size={17} />}</button> : null}</div>
      {revealed ? <p className="flex items-center gap-1.5 text-xs font-medium text-amber-700"><ShieldAlert aria-hidden="true" size={14} />การเปิดดู {label} นี้จะถูกบันทึกเหตุการณ์ใน Audit Log เมื่อเชื่อม Backend</p> : null}
    </div>
  );
}
