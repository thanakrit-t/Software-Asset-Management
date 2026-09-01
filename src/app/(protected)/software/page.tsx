import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { SoftwareScreen } from "@/features/software/software-screen";
import { mockSamRepository } from "@/features/sam/mock-repository";
export const metadata: Metadata = { title: "Software Products" };
export default async function SoftwarePage() { const products = await mockSamRepository.listProducts(); return <div className="mx-auto max-w-[1600px] space-y-6"><PageHeader eyebrow="Software Catalog" title="Software Products" description="แคตตาล็อกผลิตภัณฑ์และเวอร์ชันซอฟต์แวร์ที่ใช้ร่วมกับ License Entitlements" /><SoftwareScreen products={products} /></div>; }
