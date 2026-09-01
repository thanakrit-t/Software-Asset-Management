import type {
  ComplianceStatus,
  LicenseAllocation,
  LicenseEntitlement,
  LicenseLifecycleStatus,
} from "./types";

const DAY_MS = 86_400_000;

function utcDay(value: string): number {
  const [year, month, day] = value.split("-").map(Number);
  return Date.UTC(year, month - 1, day);
}

export function deriveLifecycleStatus(
  license: { endDate?: string; classification?: string },
  asOfDate = "2026-09-01",
  thresholdDays = 30,
): LicenseLifecycleStatus {
  if (license.classification?.toLocaleLowerCase("en-US") === "perpetual") return "perpetual";
  if (!license.endDate) return "active";
  const daysRemaining = (utcDay(license.endDate) - utcDay(asOfDate)) / DAY_MS;
  if (daysRemaining < 0) return "expired";
  if (daysRemaining > 0 && daysRemaining <= thresholdDays) return "expiring-soon";
  return "active";
}

export function deriveEntitlement(
  license: Omit<LicenseEntitlement, "allocatedQuantity" | "availableQuantity" | "complianceStatus" | "lifecycleStatus">,
  allocations: LicenseAllocation[],
  asOfDate = "2026-09-01",
): LicenseEntitlement {
  const allocatedQuantity = allocations
    .filter((item) => item.licenseId === license.id && item.status === "active")
    .reduce((sum, item) => sum + item.quantity, 0);
  const availableQuantity = license.ownedQuantity - allocatedQuantity;
  const complianceStatus: ComplianceStatus = availableQuantity < 0 ? "over-allocated" : "compliant";
  return {
    ...license,
    allocatedQuantity,
    availableQuantity,
    complianceStatus,
    lifecycleStatus: deriveLifecycleStatus(license, asOfDate),
  };
}
