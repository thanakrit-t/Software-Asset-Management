import { describe, expect, test } from "vitest";

import { parseAssetWorkbook } from "./asset-workbook";
import { createAssetFixtureWorkbook } from "./test-workbooks";

describe("asset workbook adapter", () => {
  test("parses both fixed sheet layouts and groups continuation rows", async () => {
    const filePath = await createAssetFixtureWorkbook();
    const result = await parseAssetWorkbook(filePath);

    expect(result.assets).toHaveLength(2);
    expect(result.assets).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          siteCode: "factory",
          assetType: "pc",
          computerName: "FACTORY-PC",
          sourceRow: 6,
        }),
        expect.objectContaining({
          siteCode: "bangkok-office",
          assetType: "notebook",
          sourceRow: 7,
        }),
      ]),
    );
    expect(result.installedSoftware).toContainEqual(
      expect.objectContaining({
        assetBusinessKey: result.assets[0].businessKey,
        productLabel: "Microsoft Office 365",
        present: true,
      }),
    );
    expect(
      result.installedSoftware.filter(
        (item) => item.assetBusinessKey === result.assets[0].businessKey,
      ),
    ).toHaveLength(2);
    expect(result.networkData).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ kind: "mac", interfaceName: "lan" }),
        expect.objectContaining({ kind: "ip", interfaceName: "lan" }),
      ]),
    );
  });

  test("reports a meaningful row with no exact asset identity", async () => {
    const result = await parseAssetWorkbook(await createAssetFixtureWorkbook());
    expect(result.issues).toContainEqual(
      expect.objectContaining({ code: "ASSET_BUSINESS_KEY_MISSING", sourceRow: 8 }),
    );
  });
});
