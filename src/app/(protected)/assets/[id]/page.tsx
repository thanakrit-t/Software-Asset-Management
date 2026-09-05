import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { AssetDetailScreen } from "@/features/assets/asset-detail-screen";
import { getServerSamRepository } from "@/features/sam/server-repository";

export const metadata: Metadata = { title: "Asset Detail" };

export default async function AssetDetailPage({ params }: { params: Promise<{ id: string }> }) { const repository = await getServerSamRepository();
  const { id } = await params;
  const [asset, allocations] = await Promise.all([
    repository.getAsset(id),
    repository.listAllocations(),
  ]);
  if (!asset) notFound();
  return <AssetDetailScreen asset={asset} allocations={allocations.filter((item) => item.targetId === asset.id)} />;
}
