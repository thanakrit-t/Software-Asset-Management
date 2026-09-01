import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { LicenseDetailScreen } from "@/features/licenses/license-screens";
import { mockSamRepository } from "@/features/sam/mock-repository";
export const metadata: Metadata = { title: "License Detail" };
export default async function LicenseDetailPage({ params }: { params: Promise<{ id: string }> }) { const { id } = await params; const [license, allocations] = await Promise.all([mockSamRepository.getLicense(id), mockSamRepository.listAllocations()]); if (!license) notFound(); return <LicenseDetailScreen license={license} allocations={allocations.filter((item) => item.licenseId === license.id)} />; }
