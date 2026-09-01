"use client";

import { useMemo, useState } from "react";
import { AppWindow, Plus } from "lucide-react";
import type { Role, SoftwareProduct } from "@/features/sam/types";
import { SearchField } from "@/components/data-table/search-field";
import { TableShell } from "@/components/data-table/table-shell";
import { StatusBadge } from "@/components/ui/status-badge";
import { Button } from "@/components/ui/button";

export function SoftwareList({ products, role }: { products: SoftwareProduct[]; role: Role }) {
  const [query, setQuery] = useState("");
  const filtered = useMemo(() => products.filter((product) => `${product.name} ${product.publisher} ${product.version} ${product.category}`.toLowerCase().includes(query.toLowerCase())), [products, query]);
  return <div className="space-y-4"><div className="flex gap-3 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"><SearchField value={query} onChange={setQuery} label="ค้นหา Software Product" placeholder="Product, Publisher, Version หรือ Category" />{role === "admin" ? <Button><Plus aria-hidden="true" size={17} />เพิ่ม Product</Button> : null}</div><TableShell footer={<p className="text-xs text-slate-500">Software catalog {filtered.length} รายการ</p>}><table className="w-full min-w-[800px] text-left text-sm"><thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500"><tr>{["Product", "Publisher", "Version", "Category", "Status"].map((item) => <th key={item} className="border-b border-slate-200 px-5 py-3.5">{item}</th>)}</tr></thead><tbody className="divide-y divide-slate-100">{filtered.map((product) => <tr key={product.id} className="hover:bg-blue-50/30"><td className="px-5 py-4"><span className="flex items-center gap-3"><span className="grid size-10 place-items-center rounded-xl bg-violet-50 text-violet-700"><AppWindow aria-hidden="true" size={18} /></span><strong className="text-slate-950">{product.name}</strong></span></td><td className="px-5 py-4 text-slate-700">{product.publisher}</td><td className="px-5 py-4 font-semibold text-slate-800">{product.version}</td><td className="px-5 py-4"><span className="rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">{product.category}</span></td><td className="px-5 py-4"><StatusBadge status={product.active ? "active" : "retired"} label={product.active ? "Active" : "Archived"} /></td></tr>)}</tbody></table></TableShell></div>;
}
