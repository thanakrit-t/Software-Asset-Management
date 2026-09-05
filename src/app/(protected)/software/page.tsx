import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { SoftwareScreen } from "@/features/software/software-screen";
import { getServerSamRepository } from "@/features/sam/server-repository";
export const metadata: Metadata = { title: "Software Products" };
export default async function SoftwarePage() { const repository = await getServerSamRepository(); const products = await repository.listProducts(); return <div className="mx-auto max-w-[1600px] space-y-6"><PageHeader eyebrow="Software Catalog" title="Software Products" description="แคตตาล็อกผลิตภัณฑ์และเวอร์ชันซอฟต์แวร์ที่ใช้ร่วมกับ License Entitlements" /><SoftwareScreen products={products} /></div>; }
