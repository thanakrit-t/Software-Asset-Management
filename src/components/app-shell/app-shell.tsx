"use client";

import { useState } from "react";
import { usePathname } from "next/navigation";
import { MobileNav } from "./mobile-nav";
import { Sidebar } from "./sidebar";
import { Topbar } from "./topbar";
import { useRole } from "./role-provider";

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { role } = useRole();
  const [menuOpen, setMenuOpen] = useState(false);
  return (
    <div className="min-h-screen bg-canvas">
      <Sidebar role={role} pathname={pathname} className="fixed inset-y-0 left-0 z-40 hidden lg:flex" />
      <MobileNav open={menuOpen} role={role} pathname={pathname} onClose={() => setMenuOpen(false)} />
      <div className="min-w-0 lg:pl-[280px]">
        <Topbar onOpenMenu={() => setMenuOpen(true)} />
        <main className="min-h-[calc(100vh-5rem)] px-4 py-6 sm:px-6 lg:px-8 lg:py-8">{children}</main>
      </div>
    </div>
  );
}
