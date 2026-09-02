"use client";

import Link from "next/link";
import {
  Bell, Boxes, ClipboardList, FileChartColumn, Gauge, KeyRound, ListTree,
  PackageSearch, ScrollText, Settings, ShieldCheck, Users, X,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import type { Role } from "@/features/sam/types";
import { cn } from "@/lib/cn";
import { LogoMark } from "@/components/ui/logo-mark";

interface NavigationItem {
  href: string;
  label: string;
  icon: LucideIcon;
  adminOnly?: boolean;
}

const primaryNavigation: NavigationItem[] = [
  { href: "/", label: "ภาพรวม", icon: Gauge },
  { href: "/assets", label: "Assets", icon: Boxes },
  { href: "/software", label: "Software Products", icon: PackageSearch },
  { href: "/licenses", label: "Licenses", icon: KeyRound },
  { href: "/allocations", label: "License Allocations", icon: ClipboardList },
  { href: "/reports", label: "รายงาน", icon: FileChartColumn },
  { href: "/notifications", label: "การแจ้งเตือน", icon: Bell },
];

const adminNavigation: NavigationItem[] = [
  { href: "/master-data", label: "ข้อมูลตั้งต้น", icon: ListTree, adminOnly: true },
  { href: "/users", label: "จัดการผู้ใช้งาน", icon: Users, adminOnly: true },
  { href: "/audit-logs", label: "Audit Logs", icon: ScrollText, adminOnly: true },
  { href: "/settings", label: "ตั้งค่าระบบ", icon: Settings, adminOnly: true },
];

interface SidebarProps {
  role: Role;
  pathname: string;
  className?: string;
  onNavigate?: () => void;
  onClose?: () => void;
}

function NavigationLinks({ items, role, pathname, onNavigate }: Pick<SidebarProps, "role" | "pathname" | "onNavigate"> & { items: NavigationItem[] }) {
  return (
    <ul className="space-y-1">
      {items.filter((item) => !item.adminOnly || role === "admin").map((item) => {
        const active = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
        const Icon = item.icon;
        return (
          <li key={item.href}>
            <Link
              href={item.href}
              aria-current={active ? "page" : undefined}
              onClick={onNavigate}
              className={cn(
                "group flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm font-medium transition-colors",
                active
                  ? "bg-blue-50 text-blue-800 shadow-sm ring-1 ring-blue-100"
                  : "text-slate-600 hover:bg-slate-50 hover:text-slate-950",
              )}
            >
              <Icon aria-hidden="true" size={19} className={active ? "text-blue-600" : "text-slate-400 group-hover:text-slate-700"} />
              <span>{item.label}</span>
            </Link>
          </li>
        );
      })}
    </ul>
  );
}

export function Sidebar({ role, pathname, className, onNavigate, onClose }: SidebarProps) {
  return (
    <aside className={cn("flex h-full w-[280px] flex-col border-r border-slate-200 bg-white", className)}>
      <div className={cn("relative flex h-24 flex-col justify-center gap-1.5 border-b border-slate-100 px-5", onClose && "pr-16")}>
        <LogoMark className="w-[150px]" />
        <p className="truncate text-xs font-semibold text-slate-600">Software Asset Management</p>
        {onClose ? (
          <button type="button" aria-label="ปิดเมนู" onClick={onClose} className="absolute right-3 top-1/2 grid size-11 -translate-y-1/2 place-items-center rounded-xl text-slate-500 hover:bg-slate-100">
            <X aria-hidden="true" size={20} />
          </button>
        ) : null}
      </div>

      <nav aria-label="เมนูหลัก" className="flex-1 overflow-y-auto px-4 py-5">
        <p className="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.16em] text-slate-400">Workspace</p>
        <NavigationLinks items={primaryNavigation} role={role} pathname={pathname} onNavigate={onNavigate} />
        {role === "admin" ? (
          <>
            <div className="my-5 border-t border-slate-100" />
            <p className="mb-2 px-3 text-[11px] font-bold uppercase tracking-[0.16em] text-slate-400">Administration</p>
            <NavigationLinks items={adminNavigation} role={role} pathname={pathname} onNavigate={onNavigate} />
          </>
        ) : null}
      </nav>

      <div className="m-4 rounded-2xl bg-gradient-to-br from-blue-950 to-blue-700 p-4 text-white shadow-lg shadow-blue-950/15">
        <div className="mb-3 flex items-center gap-2 text-xs font-semibold text-blue-100">
          <ShieldCheck aria-hidden="true" size={16} /> Authenticated session
        </div>
        <p className="text-sm font-semibold">Verified access</p>
        <p className="mt-1 text-xs leading-5 text-blue-100">สิทธิ์การใช้งานอ้างอิงจากบัญชีผู้ใช้ที่เข้าสู่ระบบ</p>
      </div>
    </aside>
  );
}
