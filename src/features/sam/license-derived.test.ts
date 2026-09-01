import { describe, expect, test } from "vitest";
import { allocations, licenses } from "./mock-data";
import { deriveLifecycleStatus } from "./license-derived";

describe("license derived values", () => {
  test("derives every allocated quantity from active allocation records", () => {
    for (const license of licenses) {
      const allocated = allocations
        .filter((item) => item.licenseId === license.id && item.status === "active")
        .reduce((sum, item) => sum + item.quantity, 0);
      expect(license.allocatedQuantity).toBe(allocated);
      expect(license.availableQuantity).toBe(license.ownedQuantity - allocated);
    }
  });

  test("derives lifecycle status with timezone-stable threshold boundaries", () => {
    expect(deriveLifecycleStatus({ endDate: "2026-09-01" }, "2026-09-01", 30)).toBe("active");
    expect(deriveLifecycleStatus({ endDate: "2026-10-01" }, "2026-09-01", 30)).toBe("expiring-soon");
    expect(deriveLifecycleStatus({ endDate: "2026-10-02" }, "2026-09-01", 30)).toBe("active");
    expect(deriveLifecycleStatus({ endDate: "2026-08-31" }, "2026-09-01", 30)).toBe("expired");
    expect(deriveLifecycleStatus({ classification: "Perpetual" }, "2026-09-01", 30)).toBe("perpetual");
  });
});
