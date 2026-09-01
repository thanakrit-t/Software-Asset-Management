"use client";

import { Bell, Menu, Search } from "lucide-react";
import { Avatar } from "@/components/ui/avatar";
import { useRole } from "./role-provider";

export function Topbar({ onOpenMenu }: { onOpenMenu: () => void }) {
  const { role, setRole } = useRole();
  const displayName = role === "admin" ? "Admin User" : "Report Viewer";

  return (
    <header className="sticky top-0 z-30 flex h-20 items-center gap-3 border-b border-slate-200/80 bg-white/90 px-4 backdrop-blur-xl sm:px-6 lg:px-8">
      <button type="button" aria-label="เปิดเมนู" onClick={onOpenMenu} className="grid size-11 place-items-center rounded-xl text-slate-600 hover:bg-slate-100 lg:hidden">
        <Menu aria-hidden="true" size={22} />
      </button>
      <label className="relative hidden max-w-md flex-1 md:block">
        <span className="sr-only">ค้นหาทั้งระบบ</span>
        <Search aria-hidden="true" className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
        <input type="search" placeholder="ค้นหา Asset, Computer name, License..." className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 text-sm text-slate-900 transition focus:border-blue-400 focus:bg-white focus:outline-none" />
      </label>
      <div className="ml-auto flex items-center gap-2 sm:gap-3">
        <label className="flex items-center gap-2 rounded-xl border border-blue-100 bg-blue-50 px-2 py-1.5">
          <span className="hidden text-xs font-semibold text-blue-700 sm:inline">Preview</span>
          <select aria-label="เลือก Role สำหรับดูตัวอย่าง" value={role} onChange={(event) => setRole(event.target.value as "admin" | "user")} className="h-8 bg-transparent text-sm font-bold text-blue-950 focus:outline-none">
            <option value="admin">Admin</option>
            <option value="user">User</option>
          </select>
        </label>
        <button type="button" aria-label="การแจ้งเตือนที่ยังไม่อ่าน 2 รายการ" className="relative grid size-11 place-items-center rounded-xl text-slate-600 hover:bg-slate-100">
          <Bell aria-hidden="true" size={20} />
          <span className="absolute right-2.5 top-2.5 size-2 rounded-full bg-critical ring-2 ring-white" />
        </button>
        <div className="hidden h-9 w-px bg-slate-200 sm:block" />
        <div className="flex items-center gap-3">
          <Avatar name={displayName} />
          <div className="hidden lg:block">
            <p className="text-sm font-bold text-slate-900">{displayName}</p>
            <p className="text-xs text-slate-500">{role === "admin" ? "System Administrator" : "Read-only access"}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
