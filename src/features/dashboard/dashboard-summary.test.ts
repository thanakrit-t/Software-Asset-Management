import type { LicenseEntitlement } from "@/features/sam/types";
import { buildDashboardSummary } from "./dashboard-summary";

test("counts owned allocated available and over-allocated seats", () => {
  const licenses = [
    { ownedQuantity: 10, allocatedQuantity: 7, availableQuantity: 3, lifecycleStatus: "active" },
    { ownedQuantity: 2, allocatedQuantity: 4, availableQuantity: -2, lifecycleStatus: "active" },
  ] as LicenseEntitlement[];

  const summary = buildDashboardSummary([], licenses);

  expect(summary).toMatchObject({
    owned: 12,
    allocated: 11,
    available: 1,
    overAllocated: 1,
  });
});

test("counts expiring and expired entitlements separately", () => {
  const licenses = [
    { ownedQuantity: 1, allocatedQuantity: 1, availableQuantity: 0, lifecycleStatus: "expiring-soon" },
    { ownedQuantity: 1, allocatedQuantity: 0, availableQuantity: 1, lifecycleStatus: "expired" },
  ] as LicenseEntitlement[];

  expect(buildDashboardSummary([], licenses)).toMatchObject({ expiringSoon: 1, expired: 1 });
});
