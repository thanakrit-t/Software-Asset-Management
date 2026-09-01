"use client";

import type { Role } from "@/features/sam/types";
import { Sidebar } from "./sidebar";

export function MobileNav({ open, role, pathname, onClose }: { open: boolean; role: Role; pathname: string; onClose: () => void }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 lg:hidden">
      <button type="button" aria-label="ปิดเมนู" onClick={onClose} className="absolute inset-0 bg-slate-950/40 backdrop-blur-sm" />
      <Sidebar role={role} pathname={pathname} onNavigate={onClose} onClose={onClose} className="relative z-10 shadow-2xl" />
    </div>
  );
}
