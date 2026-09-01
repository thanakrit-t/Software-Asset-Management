"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { AlertTriangle, Boxes, KeyRound, Laptop, Plus, ShieldCheck } from "lucide-react";
import type { Asset, LicenseEntitlement, NotificationItem, Role } from "@/features/sam/types";
import { formatNumber } from "@/features/sam/formatters";
import { buildDashboardSummary } from "./dashboard-summary";
import { KpiCard } from "./kpi-card";
import { LicenseOverviewChart } from "./license-overview-chart";
import { AssetDistributionChart } from "./asset-distribution-chart";
import { AttentionPanel } from "./attention-panel";
import { SiteFilter, type SiteFilterValue } from "./site-filter";

interface DashboardViewProps {
  assets: Asset[];
  licenses: LicenseEntitlement[];
  notifications: NotificationItem[];
  role: Role;
}

export function DashboardView({ assets, licenses, notifications, role }: DashboardViewProps) {
  const [site, setSite] = useState<SiteFilterValue>("all");
  const filteredAssets = useMemo(() => site === "all" ? assets : assets.filter((asset) => asset.site.id === site), [assets, site]);
  const filteredLicenses = useMemo(() => {
    if (site === "all") return licenses;
    const label = site === "factory" ? "Factory" : "Bangkok Office";
    return licenses.filter((license) => license.siteScope === label || license.siteScope === "All Sites");
  }, [licenses, site]);
  const summary = buildDashboardSummary(filteredAssets, filteredLicenses);

  return (
    <div className="mx-auto max-w-[1600px] space-y-6">
      <div className="flex flex-col justify-between gap-4 xl:flex-row xl:items-end">
        <div>
          <p className="mb-2 text-xs font-bold uppercase tracking-[0.18em] text-blue-600">Executive workspace</p>
          <h1 className="text-2xl font-bold tracking-tight text-slate-950 sm:text-3xl">
            ภาพรวมสินทรัพย์ซอฟต์แวร์
            <span className="sr-only"> Software Asset Management</span>
          </h1>
          <p className="mt-2 text-sm text-slate-500">ข้อมูลล่าสุดจาก Mock repository · 1 กันยายน 2026, 09:30</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <SiteFilter value={site} onChange={setSite} />
          {role === "admin" ? (
            <Link href="/assets" className="inline-flex min-h-11 items-center gap-2 rounded-xl bg-blue-600 px-4 text-sm font-semibold text-white shadow-sm shadow-blue-900/15 hover:bg-blue-700">
              <Plus aria-hidden="true" size={17} /> เพิ่ม Asset
            </Link>
          ) : null}
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <KpiCard label="Assets ทั้งหมด" value={formatNumber(summary.totalAssets)} hint={`${summary.activeAssets} รายการกำลังใช้งาน`} icon={Laptop} tone="blue" trend="up" />
        <KpiCard label="License ที่ครอบครอง" value={formatNumber(summary.owned)} hint="รวมทุก Software Product" icon={KeyRound} tone="slate" />
        <KpiCard label="จัดสรรแล้ว" value={formatNumber(summary.allocated)} hint="คำนวณจาก Active allocations" icon={Boxes} tone="green" trend="up" />
        <KpiCard label="License คงเหลือ" value={formatNumber(summary.available)} hint="พร้อมจัดสรรเพิ่มเติม" icon={ShieldCheck} tone={summary.available < 0 ? "red" : "amber"} />
        <KpiCard label="ต้องตรวจสอบ" value={formatNumber(summary.overAllocated + summary.expiringSoon + summary.expired)} hint={`${summary.overAllocated} ใช้เกินสิทธิ์ · ${summary.expiringSoon} ใกล้หมดอายุ`} icon={AlertTriangle} tone="red" trend="down" />
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.7fr)_minmax(280px,0.8fr)]">
        <LicenseOverviewChart licenses={filteredLicenses} />
        <AssetDistributionChart data={summary.assetBySite} />
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.25fr)_minmax(320px,0.75fr)]">
        <AttentionPanel notifications={notifications} />
        <section className="overflow-hidden rounded-2xl bg-gradient-to-br from-blue-950 via-blue-900 to-blue-700 p-6 text-white shadow-xl shadow-blue-950/15">
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-blue-200">License health</p>
          <h2 className="mt-3 text-2xl font-bold">{summary.overAllocated ? "มีรายการใช้เกินสิทธิ์" : "สถานะ License ปกติ"}</h2>
          <p className="mt-2 max-w-md text-sm leading-6 text-blue-100">ตรวจสอบ License ที่หมดอายุ ใกล้หมดอายุ และจำนวนใช้งาน เพื่อวางแผนต่ออายุได้ทันเวลา</p>
          <div className="mt-6 grid grid-cols-3 gap-3">
            {[{ label: "Over", value: summary.overAllocated }, { label: "Expiring", value: summary.expiringSoon }, { label: "Expired", value: summary.expired }].map((item) => (
              <div key={item.label} className="rounded-xl bg-white/10 p-3 ring-1 ring-white/10"><p className="text-2xl font-bold">{item.value}</p><p className="mt-1 text-[11px] text-blue-100">{item.label}</p></div>
            ))}
          </div>
          <Link href="/licenses" className="mt-6 inline-flex min-h-11 items-center rounded-xl bg-white px-4 text-sm font-bold text-blue-900 hover:bg-blue-50">ตรวจสอบ Licenses</Link>
        </section>
      </div>
    </div>
  );
}
