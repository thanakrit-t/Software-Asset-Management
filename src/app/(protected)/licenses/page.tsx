import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { LicenseListScreen } from "@/features/licenses/license-screens";
import { mockSamRepository } from "@/features/sam/mock-repository";
export const metadata: Metadata = { title: "Licenses" };
export default async function LicensesPage() { const licenses = await mockSamRepository.listLicenses(); return <div className="mx-auto max-w-[1600px] space-y-6"><PageHeader eyebrow="License Management" title="Licenses" description="ติดตามจำนวนที่ครอบครอง จัดสรร คงเหลือ สถานะ Compliance และวันหมดอายุ" /><LicenseListScreen licenses={licenses} /></div>; }
