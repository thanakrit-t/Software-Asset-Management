"use client";

import { useMemo, useState } from "react";
import { ArrowUpRight, BarChart3, Database, Download, FileSpreadsheet, ShieldCheck } from "lucide-react";

type PreviewKind = "asset" | "license" | "allocation" | "quality";
type PreviewRow = { id: string; date: string; site: string; status: string; cells: string[] };
type ReportConfig = { name: string; kind: PreviewKind; statuses?: string[] };

const groups: Array<{ title: string; icon: typeof Database; reports: ReportConfig[] }> = [
  { title: "Asset reports", icon: Database, reports: [
    { name: "Asset Inventory Report", kind: "asset" },
    { name: "Asset by Site / Location / Department", kind: "asset" },
    { name: "Asset by Type and Status", kind: "asset" },
    { name: "Asset by Operating System", kind: "asset" },
    { name: "Software Allocated by Asset", kind: "allocation" },
  ] },
  { title: "License & compliance", icon: ShieldCheck, reports: [
    { name: "License Inventory Report", kind: "license" },
    { name: "Owned vs Allocated vs Available", kind: "license" },
    { name: "Over-allocated License Report", kind: "license", statuses: ["Over-allocated"] },
    { name: "Expired License Report", kind: "license", statuses: ["Expired"] },
    { name: "Expiring in 30 / 60 / 90 Days", kind: "license", statuses: ["Expiring soon"] },
    { name: "Unused License Report", kind: "license", statuses: ["Unused"] },
    { name: "Allocation by Asset / User", kind: "allocation" },
  ] },
  { title: "Data quality", icon: BarChart3, reports: [
    { name: "Data Quality Report", kind: "quality", statuses: ["Open"] },
    { name: "Migration Reconciliation Report", kind: "quality" },
  ] },
];

const schemas: Record<PreviewKind, { columns: string[]; rows: PreviewRow[] }> = {
  asset: { columns: ["Reference", "Asset", "Site", "Status", "Updated"], rows: [
    { id: "asset-factory", date: "2026-08-28", site: "Factory", status: "Active", cells: ["TPO-083", "TPO-083-PC", "Factory", "Active", "28 ส.ค. 2026"] },
    { id: "asset-office", date: "2026-08-15", site: "Bangkok Office", status: "Active", cells: ["TKCBKKLT001", "TKCBKKLT001 (Notebook)", "Bangkok Office", "Active", "15 ส.ค. 2026"] },
    { id: "asset-repair", date: "2026-08-30", site: "Factory", status: "Repair", cells: ["TWE-095", "SCAN01", "Factory", "Repair", "30 ส.ค. 2026"] },
  ] },
  license: { columns: ["Reference", "Product", "Owned", "Allocated", "Available"], rows: [
    { id: "license-w11", date: "2026-08-28", site: "Factory", status: "Compliant", cells: ["LIC-FAC-2025-001", "Windows 11 Professional", "120", "104", "16"] },
    { id: "license-o365", date: "2026-08-28", site: "Bangkok Office", status: "Expiring soon", cells: ["SUB-2026-0365", "Office 365 Family", "33", "30", "3"] },
    { id: "license-sql", date: "2026-08-28", site: "Factory", status: "Over-allocated", cells: ["LIC-FAC-2019-SQL", "SQL Server Standard 2019", "1", "2", "-1"] },
    { id: "license-winrar", date: "2026-08-28", site: "Factory", status: "Expired", cells: ["LIC-FAC-2009-WR", "WinRAR 3.8", "43", "40", "3"] },
  ] },
  allocation: { columns: ["License", "Target", "Type", "Quantity", "Allocated date"], rows: [
    { id: "allocation-asset", date: "2026-08-28", site: "Factory", status: "Active", cells: ["Windows 11 Professional", "TPO-083-PC", "Asset", "1", "28 ส.ค. 2026"] },
    { id: "allocation-user", date: "2026-08-15", site: "Bangkok Office", status: "Active", cells: ["Office 365 Family", "Supachai", "User", "1", "15 ส.ค. 2026"] },
  ] },
  quality: { columns: ["Rule", "Entity", "Issue", "Status", "Checked date"], rows: [
    { id: "quality-network", date: "2026-08-30", site: "Factory", status: "Open", cells: ["Missing network data", "SCAN01", "ยืนยัน IP / VLAN", "Open", "30 ส.ค. 2026"] },
    { id: "quality-reconcile", date: "2026-08-28", site: "Bangkok Office", status: "Matched", cells: ["Migration reconciliation", "License totals", "Excel เทียบ Mock staging", "Matched", "28 ส.ค. 2026"] },
  ] },
};

const DATE_FROM = "2026-08-01";
const DATE_TO = "2026-09-01";

export function ReportCatalog() {
  const [selected, setSelected] = useState<ReportConfig | null>(null);
  const [site, setSite] = useState("all");
  const [status, setStatus] = useState("all");
  const [dateFrom, setDateFrom] = useState(DATE_FROM);
  const [dateTo, setDateTo] = useState(DATE_TO);
  const schema = selected ? schemas[selected.kind] : null;
  const rows = useMemo(() => {
    if (!selected || !schema) return [];
    return schema.rows.filter((row) => {
      if (selected.statuses && !selected.statuses.includes(row.status)) return false;
      if (site !== "all" && row.site !== site) return false;
      if (status !== "all" && row.status !== status) return false;
      if (dateFrom && row.date < dateFrom) return false;
      if (dateTo && row.date > dateTo) return false;
      return true;
    });
  }, [dateFrom, dateTo, schema, selected, site, status]);

  function openPreview(report: ReportConfig) {
    setSelected(report);
    setSite("all");
    setStatus("all");
    setDateFrom(DATE_FROM);
    setDateTo(DATE_TO);
  }

  return <div className="space-y-6">
    {groups.map((group) => <section key={group.title}><h2 className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-700"><group.icon aria-hidden="true" size={18} className="text-blue-600" />{group.title}</h2><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{group.reports.map((report) => <article key={report.name} className="group rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-blue-200 hover:shadow-md"><div className="flex items-start justify-between"><span className="grid size-11 place-items-center rounded-xl bg-blue-50 text-blue-700"><FileSpreadsheet aria-hidden="true" size={20} /></span><ArrowUpRight aria-hidden="true" className="text-slate-300 group-hover:text-blue-600" size={18} /></div><h3 className="mt-4 font-bold text-slate-950">{report.name}</h3><p className="mt-2 text-xs leading-5 text-slate-500">Preview จาก mock data · Export เปิดใช้หลังเชื่อม Backend</p><button type="button" onClick={() => openPreview(report)} className="mt-4 min-h-10 rounded-xl border border-blue-200 px-3 text-xs font-semibold text-blue-700 hover:bg-blue-50">ดูตัวอย่าง {report.name}</button></article>)}</div></section>)}

    {selected && schema ? <section className="scroll-mt-6 rounded-2xl border border-blue-200 bg-white p-5 shadow-sm" aria-live="polite"><div className="flex flex-col justify-between gap-3 lg:flex-row lg:items-start"><div><p className="text-xs font-bold uppercase tracking-wide text-blue-600">Mock report preview</p><h2 className="mt-1 text-xl font-bold text-slate-950">ตัวอย่าง {selected.name}</h2><p className="mt-1 text-xs text-slate-500">ข้อมูลสาธิตเฉพาะรายงาน · ยังไม่มีการ export หรือบันทึกข้อมูล</p></div><button type="button" disabled className="inline-flex min-h-10 items-center justify-center gap-2 rounded-xl bg-slate-100 px-4 text-sm font-semibold text-slate-400"><Download aria-hidden="true" size={16} />Export (หลังเชื่อม Backend)</button></div>
      <div className="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4"><label className="text-xs font-semibold text-slate-600">Site<select aria-label="Site" value={site} onChange={(event) => setSite(event.target.value)} className="mt-1 h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm font-normal"><option value="all">All Sites</option><option value="Factory">Factory</option><option value="Bangkok Office">Bangkok Office</option></select></label><label className="text-xs font-semibold text-slate-600">Status<select aria-label="Status" value={status} onChange={(event) => setStatus(event.target.value)} className="mt-1 h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm font-normal"><option value="all">ทุกสถานะ</option>{Array.from(new Set(schema.rows.map((row) => row.status))).map((item) => <option key={item}>{item}</option>)}</select></label><label className="text-xs font-semibold text-slate-600">วันที่เริ่มต้น<input aria-label="วันที่เริ่มต้น" type="date" value={dateFrom} onChange={(event) => setDateFrom(event.target.value)} className="mt-1 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm font-normal" /></label><label className="text-xs font-semibold text-slate-600">วันที่สิ้นสุด<input aria-label="วันที่สิ้นสุด" type="date" value={dateTo} onChange={(event) => setDateTo(event.target.value)} className="mt-1 h-11 w-full rounded-xl border border-slate-200 px-3 text-sm font-normal" /></label></div>
      <div className="mt-5 overflow-x-auto rounded-xl border border-slate-200"><table aria-label="Report preview" className="w-full min-w-[720px] text-left text-sm"><thead className="bg-slate-50 text-xs uppercase text-slate-500"><tr>{schema.columns.map((heading) => <th key={heading} className="px-4 py-3">{heading}</th>)}</tr></thead><tbody className="divide-y divide-slate-100">{rows.map((row) => <tr key={row.id}>{row.cells.map((cell, index) => <td key={`${row.id}-${schema.columns[index]}`} className={`px-4 py-3 ${index === 0 ? "font-semibold text-slate-900" : "text-slate-700"}`}>{cell}</td>)}</tr>)}</tbody></table>{!rows.length ? <p className="p-8 text-center text-sm text-slate-500">ไม่พบข้อมูลตามตัวกรอง</p> : null}</div>
    </section> : null}
  </div>;
}
