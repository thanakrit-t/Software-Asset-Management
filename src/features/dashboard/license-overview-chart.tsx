"use client";

import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import type { LicenseEntitlement } from "@/features/sam/types";

export function LicenseOverviewChart({ licenses }: { licenses: LicenseEntitlement[] }) {
  const data = licenses.slice(0, 6).map((license) => ({
    name: `${license.product.name} ${license.product.version}`,
    owned: license.ownedQuantity,
    allocated: license.allocatedQuantity,
  }));
  return (
    <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
      <div className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h2 className="font-bold text-slate-950">License utilization</h2>
          <p className="mt-1 text-xs text-slate-500">เปรียบเทียบจำนวนที่ครอบครองและจัดสรร</p>
        </div>
        <span className="rounded-lg bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">Top products</span>
      </div>
      {data.length ? (
        <div className="h-[260px]" aria-label="กราฟเปรียบเทียบ License ที่ครอบครองและจัดสรร">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data} margin={{ top: 6, right: 6, left: -20, bottom: 36 }}>
              <CartesianGrid stroke="#E2E8F0" strokeDasharray="3 3" vertical={false} />
              <XAxis dataKey="name" tick={{ fill: "#64748B", fontSize: 10 }} angle={-18} textAnchor="end" interval={0} />
              <YAxis tick={{ fill: "#64748B", fontSize: 11 }} allowDecimals={false} />
              <Tooltip cursor={{ fill: "#F8FAFC" }} />
              <Bar dataKey="owned" name="Owned" fill="#BFDBFE" radius={[6, 6, 0, 0]} />
              <Bar dataKey="allocated" name="Allocated" fill="#2563EB" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      ) : <p className="grid h-[260px] place-items-center text-sm text-slate-500">ยังไม่มีข้อมูล License</p>}
    </section>
  );
}
