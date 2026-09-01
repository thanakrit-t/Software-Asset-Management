"use client";

import type { Asset } from "@/features/sam/types";
import { useRole } from "@/components/app-shell/role-provider";
import { AssetList } from "./asset-list";

export function AssetListScreen({ assets }: { assets: Asset[] }) {
  const { role } = useRole();
  return <AssetList assets={assets} role={role} />;
}
