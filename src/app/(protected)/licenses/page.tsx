import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { LicenseListScreen } from "@/features/licenses/license-screens";
import { getServerSamRepository } from "@/features/sam/server-repository";
export const metadata: Metadata = { title: "Licenses" };
export default async function LicensesPage() { const repository = await getServerSamRepository(); const licenses = await repository.listLicenses(); return <div className="mx-auto max-w-[1600px] space-y-6"><PageHeader eyebrow="License Management" title="Licenses" description="ติดตามจำนวนที่ครอบครอง จัดสรร คงเหลือ สถานะ Compliance และวันหมดอายุ" /><LicenseListScreen licenses={licenses} /></div>; }
