import { formatDate, formatNumber, maskLicenseKey } from "./formatters";

test("masks a license key except its final five characters", () => {
  expect(maskLicenseKey("36QJC-PNYBC-7BXCW-4CMCW-Q69TY")).toBe(
    "•••••-•••••-•••••-•••••-Q69TY",
  );
});

test("formats an ISO date in Thai-readable Gregorian order", () => {
  expect(formatDate("2026-08-28")).toBe("28 ส.ค. 2026");
});

test("formats counts with grouping separators", () => {
  expect(formatNumber(1284)).toBe("1,284");
});
