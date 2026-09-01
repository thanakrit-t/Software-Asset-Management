"use client";

import type { Asset, LicenseAllocation } from "@/features/sam/types";
import { useRole } from "@/components/app-shell/role-provider";
import { AssetDetail } from "./asset-detail";

export function AssetDetailScreen({ asset, allocations }: { asset: Asset; allocations: LicenseAllocation[] }) {
  const { role } = useRole();
  return <AssetDetail asset={asset} allocations={allocations} role={role} />;
}
