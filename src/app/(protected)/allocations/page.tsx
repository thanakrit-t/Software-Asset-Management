import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { AllocationScreen } from "@/features/allocations/allocation-screen";
import { mockSamRepository } from "@/features/sam/mock-repository";
export const metadata: Metadata = { title: "License Allocations" };
export default async function AllocationsPage() { const [allocations, licenses] = await Promise.all([mockSamRepository.listAllocations(), mockSamRepository.listLicenses()]); return <div className="mx-auto max-w-[1600px] space-y-6"><PageHeader eyebrow="Entitlement Tracking" title="License Allocations" description="ตรวจสอบความสัมพันธ์ระหว่าง License กับ Asset ผู้ใช้งาน หรือ Site" /><AllocationScreen allocations={allocations} licenses={licenses} /></div>; }
