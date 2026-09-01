"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, FileSearch, Laptop, Monitor, Plus, Server } from "lucide-react";
import type { Asset, AssetStatus, AssetType, Role, Site } from "@/features/sam/types";
import { SearchField } from "@/components/data-table/search-field";
import { FilterSelect } from "@/components/data-table/filter-select";
import { TableShell } from "@/components/data-table/table-shell";
import { StatusBadge } from "@/components/ui/status-badge";
import { EmptyState } from "@/components/ui/empty-state";
import { Button } from "@/components/ui/button";
import { AssetFormDrawer } from "./asset-form-drawer";

export function AssetList({ assets, role }: { assets: Asset[]; role: Role }) {
  const [query, setQuery] = useState("");
  const [site, setSite] = useState<Site["id"] | "all">("all");
  const [type, setType] = useState<AssetType | "all">("all");
  const [status, setStatus] = useState<AssetStatus | "all">("all");
  const [formOpen, setFormOpen] = useState(false);
  const filtered = useMemo(() => assets.filter((asset) => {
    if (site !== "all" && asset.site.id !== site) return false;
    if (type !== "all" && asset.type !== type) return false;
    if (status !== "all" && asset.status !== status) return false;
    if (query) {
      const needle = query.toLowerCase();
      const values = [asset.assetCode, asset.computerName, asset.primaryUser, asset.operatingSystem, ...asset.networkInterfaces.flatMap((network) => [network.macAddress ?? "", network.ipAddress ?? ""])];
      if (!values.some((value) => value.toLowerCase().includes(needle))) return false;
    }
    return true;
  }), [assets, query, site, type, status]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 rounded-2xl border border-slate-200/80 bg-white p-4 shadow-sm xl:flex-row xl:items-center">
        <SearchField value={query} onChange={setQuery} label="ค้นหา Asset" placeholder="Asset code, Computer name, User, MAC หรือ IP" />
        <div className="flex flex-wrap gap-2">
          <FilterSelect label="Site" value={site} onChange={(value) => setSite(value as typeof site)} options={[{ value: "all", label: "ทุก Site" }, { value: "factory", label: "Factory" }, { value: "bangkok-office", label: "Bangkok Office" }]} />
          <FilterSelect label="Asset Type" value={type} onChange={(value) => setType(value as typeof type)} options={[{ value: "all", label: "ทุกประเภท" }, { value: "pc", label: "PC" }, { value: "notebook", label: "Notebook" }, { value: "server", label: "Server" }, { value: "other", label: "Other" }]} />
          <FilterSelect label="Status" value={status} onChange={(value) => setStatus(value as typeof status)} options={[{ value: "all", label: "ทุกสถานะ" }, { value: "active", label: "Active" }, { value: "spare", label: "Spare" }, { value: "repair", label: "Repair" }, { value: "retired", label: "Retired" }]} />
          {role === "admin" ? <Button onClick={() => setFormOpen(true)}><Plus aria-hidden="true" size={17} />เพิ่ม Asset</Button> : null}
        </div>
      </div>

      <TableShell footer={<div className="flex items-center justify-between text-xs text-slate-500"><span>แสดง {filtered.length} จาก {assets.length} รายการ</span><span>Mock data · หน้า 1 จาก 1</span></div>}>
        {filtered.length ? (
          <table className="w-full min-w-[1050px] border-collapse text-left text-sm">
            <thead className="bg-slate-50/80 text-xs uppercase tracking-wide text-slate-500"><tr>{["Asset", "ผู้ใช้งาน", "Site / Location", "Operating System", "Network", "Status", ""].map((heading) => <th key={heading} className="border-b border-slate-200 px-5 py-3.5 font-bold">{heading}</th>)}</tr></thead>
            <tbody className="divide-y divide-slate-100">{filtered.map((asset) => <AssetRow key={asset.id} asset={asset} />)}</tbody>
          </table>
        ) : <EmptyState icon={FileSearch} title="ไม่พบ Asset" description="ลองเปลี่ยนคำค้นหาหรือเงื่อนไขตัวกรอง" />}
      </TableShell>
      <AssetFormDrawer open={formOpen} onClose={() => setFormOpen(false)} />
    </div>
  );
}

function AssetRow({ asset }: { asset: Asset }) {
  const Icon = asset.type === "server" ? Server : asset.type === "notebook" ? Laptop : Monitor;
  const primaryNetwork = asset.networkInterfaces[0];
  return (
    <tr className="group transition hover:bg-blue-50/30">
      <td className="px-5 py-4"><div className="flex items-center gap-3"><span className="grid size-10 place-items-center rounded-xl bg-slate-100 text-slate-600 group-hover:bg-blue-100 group-hover:text-blue-700"><Icon aria-hidden="true" size={19} /></span><div><Link href={`/assets/${asset.id}`} className="font-bold text-slate-950 hover:text-blue-700">{asset.assetCode}</Link>{asset.computerName !== asset.assetCode ? <p className="mt-0.5 text-xs text-slate-500">{asset.computerName}</p> : null}</div></div></td>
      <td className="px-5 py-4"><p className="font-semibold text-slate-800">{asset.primaryUser}</p><p className="mt-0.5 text-xs text-slate-500">Owner: {asset.responsiblePerson}</p></td>
      <td className="px-5 py-4"><p className="font-semibold text-slate-800">{asset.site.shortName}</p><p className="mt-0.5 text-xs text-slate-500">{asset.location}</p></td>
      <td className="max-w-48 px-5 py-4"><p className="truncate font-medium text-slate-700">{asset.operatingSystem}</p><p className="mt-0.5 text-xs text-slate-500">{asset.department}</p></td>
      <td className="px-5 py-4"><p className="font-mono text-xs font-semibold text-slate-700">{primaryNetwork?.ipAddress ?? "—"}</p><p className="mt-1 font-mono text-[11px] text-slate-400">{primaryNetwork?.vlan ?? "No VLAN"}</p></td>
      <td className="px-5 py-4"><StatusBadge status={asset.status} /></td>
      <td className="px-5 py-4 text-right"><Link aria-label={`ดูรายละเอียด ${asset.assetCode}`} href={`/assets/${asset.id}`} className="inline-grid size-10 place-items-center rounded-xl text-slate-400 hover:bg-blue-100 hover:text-blue-700"><ArrowRight aria-hidden="true" size={18} /></Link></td>
    </tr>
  );
}
