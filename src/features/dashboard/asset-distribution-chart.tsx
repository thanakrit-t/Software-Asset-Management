"use client";

import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";

const COLORS = ["#2563EB", "#93C5FD", "#1E3A8A", "#CBD5E1"];

export function AssetDistributionChart({ data }: { data: Array<{ name: string; value: number }> }) {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  return (
    <section className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
      <div>
        <h2 className="font-bold text-slate-950">Assets by site</h2>
        <p className="mt-1 text-xs text-slate-500">การกระจายตัวของอุปกรณ์ทั้งหมด</p>
      </div>
      {data.length ? (
        <>
          <div className="relative mx-auto h-[190px] max-w-[260px]" aria-label="กราฟสัดส่วน Asset ตาม Site">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={data} dataKey="value" nameKey="name" innerRadius={58} outerRadius={80} paddingAngle={4}>
                  {data.map((item, index) => <Cell key={item.name} fill={COLORS[index % COLORS.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
            <div className="pointer-events-none absolute inset-0 grid place-items-center text-center">
              <div><p className="text-3xl font-bold text-slate-950">{total}</p><p className="text-[11px] font-medium text-slate-500">Total assets</p></div>
            </div>
          </div>
          <ul className="space-y-2">
            {data.map((item, index) => (
              <li key={item.name} className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-2 text-slate-600"><span className="size-2.5 rounded-full" style={{ backgroundColor: COLORS[index % COLORS.length] }} />{item.name}</span>
                <span className="font-bold text-slate-900">{item.value}</span>
              </li>
            ))}
          </ul>
        </>
      ) : <p className="grid h-[270px] place-items-center text-sm text-slate-500">ยังไม่มีข้อมูล Asset</p>}
    </section>
  );
}
