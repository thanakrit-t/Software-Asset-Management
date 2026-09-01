import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { AssetDetailScreen } from "@/features/assets/asset-detail-screen";
import { mockSamRepository } from "@/features/sam/mock-repository";

export const metadata: Metadata = { title: "Asset Detail" };

export default async function AssetDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [asset, allocations] = await Promise.all([
    mockSamRepository.getAsset(id),
    mockSamRepository.listAllocations(),
  ]);
  if (!asset) notFound();
  return <AssetDetailScreen asset={asset} allocations={allocations.filter((item) => item.targetId === asset.id)} />;
}
