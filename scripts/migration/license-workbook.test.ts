import { createHash } from "node:crypto";

import { describe, expect, test } from "vitest";

import { parseLicenseWorkbook } from "./license-workbook";
import { createLicenseFixtureWorkbook, INVENTED_SERIAL } from "./test-workbooks";

const fingerprint = (value: string) => createHash("sha256").update(value).digest("hex");

describe("license workbook adapter", () => {
  test("sanitizes secrets and maps detail and summary sheets", async () => {
    const result = await parseLicenseWorkbook(await createLicenseFixtureWorkbook(), fingerprint);

    expect(JSON.stringify(result.stagingRows)).not.toContain(INVENTED_SERIAL);
    expect(result.secrets[0]).toMatchObject({ maskedHint: "••••-USE" });
    expect(result.secrets[0].value).toBe(INVENTED_SERIAL);
    expect(result.stagingRows[0]).toMatchObject({
      normalizedPublisher: "Example Maker",
      normalizedOwnedQuantity: 5,
      sheetName: "Software License FACTORY",
      sourceRow: 9,
    });
    expect(result.summaryControls).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          siteCode: "factory",
          label: "Example Product",
          ownedQuantity: 10,
          usedQuantity: 4,
        }),
        expect.objectContaining({
          siteCode: "bangkok-office",
          label: "Office Product",
        }),
      ]),
    );
  });

  test("reports exact duplicate records and invalid typed dates", async () => {
    const result = await parseLicenseWorkbook(await createLicenseFixtureWorkbook(), fingerprint);
    expect(result.issues).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ code: "LICENSE_DUPLICATE_EXACT", sourceRow: 9 }),
        expect.objectContaining({ code: "LICENSE_DUPLICATE_EXACT", sourceRow: 10 }),
        expect.objectContaining({
          code: "LICENSE_DATE_INVALID",
          sourceRow: 11,
          field: "purchaseDate",
        }),
      ]),
    );
  });
});
