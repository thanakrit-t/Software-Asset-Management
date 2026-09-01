"use client";

import { useState } from "react";
import Link from "next/link";
import { Link2, Plus } from "lucide-react";
import type { LicenseAllocation, LicenseEntitlement, Role } from "@/features/sam/types";
import { formatDate } from "@/features/sam/formatters";
import { TableShell } from "@/components/data-table/table-shell";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";
import { AllocationDrawer } from "./allocation-drawer";

export function AllocationList({ allocations, licenses, role }: { allocations: LicenseAllocation[]; licenses: LicenseEntitlement[]; role: Role }) {
  const [open, setOpen] = useState(false);
  return <div className="space-y-4">{role === "admin" ? <div className="flex justify-end"><Button onClick={() => setOpen(true)}><Plus aria-hidden="true" size={17} />จัดสรร License</Button></div> : null}<TableShell footer={<p className="text-xs text-slate-500">Active allocation {allocations.filter((item) => item.status === "active").length} รายการ</p>}><table className="w-full min-w-[900px] text-left text-sm"><thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr>{["Software / License", "Target", "Type", "Site", "Quantity", "Allocated date", "Status"].map((item) => <th key={item} className="border-b border-slate-200 px-5 py-3.5">{item}</th>)}</tr></thead><tbody className="divide-y divide-slate-100">{allocations.map((item) => <tr key={item.id} className="hover:bg-blue-50/30"><td className="px-5 py-4"><Link href={`/licenses/${item.licenseId}`} className="flex items-center gap-2 font-bold text-slate-900 hover:text-blue-700"><Link2 aria-hidden="true" size={17} />{item.productName}</Link></td><td className="px-5 py-4 font-semibold text-slate-800">{item.targetName}</td><td className="px-5 py-4 capitalize text-slate-600">{item.targetType}</td><td className="px-5 py-4 text-slate-600">{item.site.shortName}</td><td className="px-5 py-4 font-bold">{item.quantity}</td><td className="px-5 py-4 text-slate-600">{formatDate(item.allocatedAt)}</td><td className="px-5 py-4"><StatusBadge status={item.status} /></td></tr>)}</tbody></table></TableShell><AllocationDrawer open={open} onClose={() => setOpen(false)} licenses={licenses} /></div>;
}
