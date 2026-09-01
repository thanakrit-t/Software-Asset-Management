import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { ReportCatalog } from "@/features/reports/report-catalog";
export const metadata: Metadata = { title: "Reports" };
export default function ReportsPage() { return <div className="mx-auto max-w-[1600px] space-y-6"><PageHeader eyebrow="Analytics & Export" title="รายงาน" description="รายงาน Asset, License Compliance, Data Quality และ Migration สำหรับ Factory, Bangkok Office และภาพรวมองค์กร" /><ReportCatalog /></div>; }
