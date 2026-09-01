import type { Asset, LicenseEntitlement } from "@/features/sam/types";

export interface DashboardSummary {
  totalAssets: number;
  activeAssets: number;
  owned: number;
  allocated: number;
  available: number;
  overAllocated: number;
  expiringSoon: number;
  expired: number;
  assetBySite: Array<{ name: string; value: number }>;
  assetByType: Array<{ name: string; value: number }>;
}

export function buildDashboardSummary(
  assets: Asset[],
  licenses: LicenseEntitlement[],
): DashboardSummary {
  const licenseTotals = licenses.reduce(
    (totals, license) => ({
      owned: totals.owned + license.ownedQuantity,
      allocated: totals.allocated + license.allocatedQuantity,
      available: totals.available + license.availableQuantity,
      overAllocated: totals.overAllocated + (license.availableQuantity < 0 ? 1 : 0),
      expiringSoon: totals.expiringSoon + (license.lifecycleStatus === "expiring-soon" ? 1 : 0),
      expired: totals.expired + (license.lifecycleStatus === "expired" ? 1 : 0),
    }),
    { owned: 0, allocated: 0, available: 0, overAllocated: 0, expiringSoon: 0, expired: 0 },
  );

  const countBy = (values: string[]) =>
    Object.entries(values.reduce<Record<string, number>>((counts, value) => {
      counts[value] = (counts[value] ?? 0) + 1;
      return counts;
    }, {})).map(([name, value]) => ({ name, value }));

  return {
    totalAssets: assets.length,
    activeAssets: assets.filter((asset) => asset.status === "active").length,
    ...licenseTotals,
    assetBySite: countBy(assets.map((asset) => asset.site.shortName)),
    assetByType: countBy(assets.map((asset) => asset.type.toUpperCase())),
  };
}
