"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { ArrowRight, KeyRound, Plus } from "lucide-react";
import type { LicenseEntitlement, Role } from "@/features/sam/types";
import { formatDate, formatNumber } from "@/features/sam/formatters";
import { SearchField } from "@/components/data-table/search-field";
import { FilterSelect } from "@/components/data-table/filter-select";
import { TableShell } from "@/components/data-table/table-shell";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { LicenseFormDrawer } from "./license-form-drawer";

export function LicenseList({ licenses, role }: { licenses: LicenseEntitlement[]; role: Role }) {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("all");
  const [formOpen, setFormOpen] = useState(false);
  const filtered = useMemo(() => licenses.filter((license) => {
    if (status !== "all" && license.lifecycleStatus !== status) return false;
    const haystack = `${license.product.name} ${license.product.version} ${license.product.publisher} ${license.reference}`.toLowerCase();
    return haystack.includes(query.toLowerCase());
  }), [licenses, query, status]);
  return <div className="space-y-4"><div className="flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm lg:flex-row"><SearchField value={query} onChange={setQuery} label="ค้นหา License" placeholder="Product, Publisher หรือ Reference" /><FilterSelect label="Lifecycle Status" value={status} onChange={setStatus} options={[{ value: "all", label: "ทุกสถานะ" }, { value: "active", label: "Active" }, { value: "expiring-soon", label: "Expiring soon" }, { value: "expired", label: "Expired" }]} />{role === "admin" ? <Button onClick={() => setFormOpen(true)}><Plus aria-hidden="true" size={17} />เพิ่ม License</Button> : null}</div><TableShell footer={<p className="text-xs text-slate-500">แสดง {filtered.length} จาก {licenses.length} รายการ</p>}><table className="w-full min-w-[1100px] text-left text-sm"><thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr>{["Product", "Reference / Scope", "Owned", "Allocated", "Available", "Lifecycle", "Compliance", "End date", ""].map((item) => <th key={item} className="border-b border-slate-200 px-5 py-3.5">{item}</th>)}</tr></thead><tbody className="divide-y divide-slate-100">{filtered.map((license) => <tr key={license.id} className="hover:bg-blue-50/30"><td className="px-5 py-4"><div className="flex gap-3"><span className="grid size-10 place-items-center rounded-xl bg-blue-50 text-blue-700"><KeyRound aria-hidden="true" size={18} /></span><div><Link href={`/licenses/${license.id}`} className="font-bold text-slate-950 hover:text-blue-700">{license.product.name}</Link><p className="mt-0.5 text-xs text-slate-500">{license.product.version} · {license.product.publisher}</p></div></div></td><td className="px-5 py-4"><p className="font-semibold text-slate-800">{license.reference}</p><p className="mt-0.5 text-xs text-slate-500">{license.siteScope}</p></td><Quantity value={license.ownedQuantity} /><Quantity value={license.allocatedQuantity} /><Quantity value={license.availableQuantity} critical={license.availableQuantity < 0} /><td className="px-5 py-4"><StatusBadge status={license.lifecycleStatus} /></td><td className="px-5 py-4"><StatusBadge status={license.complianceStatus} /></td><td className="px-5 py-4 text-slate-600">{formatDate(license.endDate)}</td><td className="px-5 py-4"><Link aria-label={`ดู ${license.reference}`} href={`/licenses/${license.id}`} className="grid size-10 place-items-center rounded-xl text-slate-400 hover:bg-blue-100 hover:text-blue-700"><ArrowRight aria-hidden="true" size={17} /></Link></td></tr>)}</tbody></table></TableShell><LicenseFormDrawer open={formOpen} onClose={() => setFormOpen(false)} /></div>;
}

function Quantity({ value, critical }: { value: number; critical?: boolean }) { return <td className={`px-5 py-4 text-lg font-bold ${critical ? "text-red-700" : "text-slate-900"}`}>{formatNumber(value)}</td>; }
