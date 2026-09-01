"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Building2, CalendarDays, Cpu, Edit3, Globe2, Laptop, MapPin, Network, UserRound, Wifi, X } from "lucide-react";
import type { Asset, LicenseAllocation, Role } from "@/features/sam/types";
import { formatDate } from "@/features/sam/formatters";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/ui/status-badge";

export function AssetDetail({ asset, allocations, role }: { asset: Asset; allocations: LicenseAllocation[]; role: Role }) {
  const [editOpen, setEditOpen] = useState(false);
  return (
    <div className="mx-auto max-w-[1500px] space-y-6">
      <Link href="/assets" className="inline-flex min-h-10 items-center gap-2 text-sm font-semibold text-slate-600 hover:text-blue-700"><ArrowLeft aria-hidden="true" size={17} />กลับไปหน้า Assets</Link>
      <section className="overflow-hidden rounded-3xl border border-slate-200/80 bg-white shadow-sm">
        <div className="h-2 bg-gradient-to-r from-blue-700 via-blue-500 to-cyan-400" />
        <div className="flex flex-col justify-between gap-5 p-6 lg:flex-row lg:items-center">
          <div className="flex items-center gap-4"><span className="grid size-14 place-items-center rounded-2xl bg-blue-50 text-blue-700 ring-1 ring-blue-100"><Laptop aria-hidden="true" size={26} /></span><div><div className="flex flex-wrap items-center gap-2"><h1 className="text-2xl font-bold text-slate-950">{asset.assetCode}</h1><StatusBadge status={asset.status} /></div><p className="mt-1 text-sm text-slate-500">{asset.computerName} · {asset.type.toUpperCase()}</p></div></div>
          {role === "admin" ? <Button variant="secondary" onClick={() => setEditOpen(true)}><Edit3 aria-hidden="true" size={17} />แก้ไข Asset</Button> : null}
        </div>
      </section>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.45fr)_minmax(320px,0.75fr)]">
        <div className="space-y-6">
          <Card title="ข้อมูล Asset" icon={Cpu}>
            <dl className="grid gap-x-8 gap-y-5 sm:grid-cols-2 lg:grid-cols-3">
              <Detail label="Computer Name" value={asset.computerName} icon={Laptop} />
              <Detail label="Primary User" value={asset.primaryUser} icon={UserRound} />
              <Detail label="Responsible Person" value={asset.responsiblePerson} icon={UserRound} />
              <Detail label="Site" value={asset.site.name} icon={Building2} />
              <Detail label="Location" value={asset.location} icon={MapPin} />
              <Detail label="Department" value={asset.department} icon={Building2} />
              <Detail label="Manufacturer / Model" value={`${asset.manufacturer} · ${asset.model}`} icon={Cpu} />
              <Detail label="Purchase Date" value={formatDate(asset.purchaseDate)} icon={CalendarDays} />
              <Detail label="Internet Level" value={asset.internetLevel} icon={Globe2} />
            </dl>
          </Card>

          <Card title="Network Interfaces" icon={Network}>
            <div className="grid gap-3 md:grid-cols-2">{asset.networkInterfaces.map((item) => (
              <article key={item.id} className="rounded-2xl border border-slate-200 bg-slate-50/60 p-4"><div className="flex items-center justify-between"><span className="flex items-center gap-2 text-sm font-bold text-slate-900">{item.type === "wifi" ? <Wifi aria-hidden="true" size={17} /> : <Network aria-hidden="true" size={17} />}{item.type.toUpperCase()}</span><span className="rounded-lg bg-white px-2 py-1 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">{item.vlan ?? "No VLAN"}</span></div><dl className="mt-4 space-y-3"><div><dt className="text-[11px] uppercase tracking-wide text-slate-400">IP Address</dt><dd className="mt-1 font-mono text-sm font-bold text-slate-800">{item.ipAddress ?? "—"}</dd></div><div><dt className="text-[11px] uppercase tracking-wide text-slate-400">MAC Address</dt><dd className="mt-1 font-mono text-sm text-slate-700">{item.macAddress ?? "—"}</dd></div></dl></article>
            ))}</div>
          </Card>
        </div>

        <div className="space-y-6">
          <Card title="Operating System" icon={Cpu}><p className="text-lg font-bold text-slate-950">{asset.operatingSystem}</p><p className="mt-2 text-sm text-slate-500">ข้อมูล License จะแสดงจาก Allocation หลังเชื่อมฐานข้อมูล</p></Card>
          <Card title="Software Allocations" icon={Globe2}>{allocations.length ? <div className="space-y-3">{allocations.map((allocation) => <Link key={allocation.id} href={`/licenses/${allocation.licenseId}`} className="block rounded-xl border border-slate-200 p-4 hover:border-blue-200 hover:bg-blue-50/40"><p className="text-sm font-bold text-slate-900">{allocation.productName}</p><p className="mt-1 text-xs text-slate-500">Allocated {formatDate(allocation.allocatedAt)} · {allocation.quantity} seat</p></Link>)}</div> : <p className="py-6 text-center text-sm text-slate-500">ไม่พบ Allocation เพิ่มเติม</p>}</Card>
        </div>
      </div>

      {editOpen ? <div className="fixed inset-0 z-[70] grid place-items-center bg-slate-950/40 p-4 backdrop-blur-sm"><section role="dialog" aria-labelledby="edit-asset-title" className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl"><div className="flex items-start justify-between"><div><p className="text-xs font-bold uppercase tracking-wide text-blue-600">UI Prototype</p><h2 id="edit-asset-title" className="mt-1 text-xl font-bold">แก้ไข Asset {asset.assetCode}</h2></div><button type="button" aria-label="ปิด" onClick={() => setEditOpen(false)} className="grid size-10 place-items-center rounded-xl hover:bg-slate-100"><X aria-hidden="true" size={19} /></button></div><p className="mt-4 rounded-xl bg-blue-50 p-4 text-sm text-blue-800">แบบฟอร์มแก้ไขจะบันทึกจริงหลังเชื่อม Supabase ในระยะถัดไป</p><div className="mt-5 flex justify-end"><Button onClick={() => setEditOpen(false)}>รับทราบ</Button></div></section></div> : null}
    </div>
  );
}

function Card({ title, icon: Icon, children }: { title: string; icon: typeof Cpu; children: React.ReactNode }) {
  return <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm"><h2 className="mb-5 flex items-center gap-2 font-bold text-slate-950"><span className="grid size-9 place-items-center rounded-xl bg-blue-50 text-blue-700"><Icon aria-hidden="true" size={17} /></span>{title}</h2>{children}</section>;
}

function Detail({ label, value, icon: Icon }: { label: string; value: string; icon: typeof Cpu }) {
  return <div><dt className="flex items-center gap-1.5 text-xs font-semibold text-slate-400"><Icon aria-hidden="true" size={14} />{label}</dt><dd className="mt-1.5 text-sm font-semibold text-slate-800">{value}</dd></div>;
}
