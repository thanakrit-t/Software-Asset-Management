import path from "node:path";

import { describe, expect, test, vi } from "vitest";

import { stageApprovedWorkbooks } from "./stage-approved-workbooks";
import {
  createAssetFixtureWorkbook,
  createLicenseFixtureWorkbook,
  INVENTED_SERIAL,
} from "./test-workbooks";
import type {
  LicenseStagingRow,
  ParsedAsset,
  ParsedAssetWorkbook,
  ParsedLicenseWorkbook,
  SecretEnvelope,
  StagingGateway,
} from "./types";

describe("approved workbook staging orchestration", () => {
  test("assets-only mode stages only the approved Asset workbook", async () => {
    const gateway = fakeGateway();
    const licenseParser = vi.fn(async (): Promise<ParsedLicenseWorkbook> => {
      throw new Error("License parser must not run in assets-only mode");
    });

    const result = await stageApprovedWorkbooks({
      dryRun: false,
      sourceSelection: "assets-only",
      paths: {
        assets: "02 203Total License(TKC) Update 2026-08-28.xlsx",
        licenses: "03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx",
      },
      gateway,
      assetParser: async () => ({
        sourceFile: "02 203Total License(TKC) Update 2026-08-28.xlsx",
        sourceFingerprint: "1".repeat(64),
        assets: [asset(0)],
        networkData: [],
        peopleAssignments: [],
        installedSoftware: [],
        issues: [],
      }),
      licenseParser,
      fileMetadata: async () => ({ size: 10, modifiedAt: "2026-08-28T00:00:00.000Z" }),
    });

    expect(result.counts.assets).toBe(1);
    expect(result.counts.licenses).toBe(0);
    expect(licenseParser).not.toHaveBeenCalled();
    expect(gateway.beginImportBatch).toHaveBeenCalledWith([
      expect.objectContaining({
        kind: "asset",
        fileName: "02 203Total License(TKC) Update 2026-08-28.xlsx",
      }),
    ]);
    expect(gateway.stageAssetRows).toHaveBeenCalledTimes(1);
    expect(gateway.stageLicenseRows).not.toHaveBeenCalled();
  });

  test("dry-run parses and reconciles without any RPC write", async () => {
    const gateway = fakeGateway();
    const logs: string[] = [];
    const result = await stageApprovedWorkbooks({
      dryRun: true,
      paths: {
        assets: await createAssetFixtureWorkbook(),
        licenses: await createLicenseFixtureWorkbook(),
      },
      gateway,
      log: (line) => logs.push(line),
      secretFingerprinter: () => "a".repeat(64),
    });

    expect(result.batchId).toBeNull();
    expect(gateway.beginImportBatch).not.toHaveBeenCalled();
    expect(gateway.stageAssetRows).not.toHaveBeenCalled();
    expect(gateway.stageLicenseRows).not.toHaveBeenCalled();
    expect(gateway.validateImportBatch).not.toHaveBeenCalled();
    expect(logs.join("\n")).not.toContain(INVENTED_SERIAL);
    expect(logs.join("\n")).toContain('"mode":"dry-run"');
  });

  test("live mode batches at 100 and sends plaintext only in secret envelopes", async () => {
    const gateway = fakeGateway();
    const logs: string[] = [];
    const secret: SecretEnvelope = {
      sourceFile: "licenses.xlsx",
      sheetName: "Software License FACTORY",
      sourceRow: 9,
      sourceCells: { secret: "K9" },
      stagingRowIndex: 0,
      secretType: "serial",
      value: INVENTED_SERIAL,
      maskedHint: "••••-USE",
      fingerprint: "b".repeat(64),
    };
    const assetParser = vi.fn(async (): Promise<ParsedAssetWorkbook> => ({
      sourceFile: "assets.xlsx",
      sourceFingerprint: "1".repeat(64),
      assets: Array.from({ length: 205 }, (_, index) => asset(index)),
      networkData: [],
      peopleAssignments: [],
      installedSoftware: [],
      issues: [],
    }));
    const licenseParser = vi.fn(async (): Promise<ParsedLicenseWorkbook> => ({
      sourceFile: "licenses.xlsx",
      sourceFingerprint: "2".repeat(64),
      stagingRows: Array.from({ length: 101 }, (_, index) => license(index)),
      secrets: [secret],
      summaryControls: [],
      issues: [],
    }));

    await stageApprovedWorkbooks({
      dryRun: false,
      paths: { assets: "assets.xlsx", licenses: "licenses.xlsx" },
      gateway,
      log: (line) => logs.push(line),
      assetParser,
      licenseParser,
      fileMetadata: async () => ({ size: 1, modifiedAt: "2026-08-28T00:00:00.000Z" }),
      secretFingerprinter: () => "b".repeat(64),
    });

    expect(gateway.stageAssetRows.mock.calls.map((call) => call[1].length)).toEqual([100, 100, 5]);
    expect(gateway.stageLicenseRows.mock.calls.map((call) => call[1].length)).toEqual([100, 1]);
    const stagedRows = JSON.stringify(gateway.stageLicenseRows.mock.calls.map((call) => call[1]));
    expect(stagedRows).not.toContain(INVENTED_SERIAL);
    const stagedSecrets = gateway.stageLicenseRows.mock.calls.flatMap((call) => call[2]);
    expect(stagedSecrets).toContainEqual(expect.objectContaining({ value: INVENTED_SERIAL }));
    expect(logs.join("\n")).not.toContain(INVENTED_SERIAL);
    expect(gateway.validateImportBatch).toHaveBeenCalledWith("batch-fixture");
  });
});

function fakeGateway() {
  return {
    beginImportBatch: vi.fn(async () => "batch-fixture"),
    stageAssetRows: vi.fn(async () => undefined),
    stageLicenseRows: vi.fn(async () => undefined),
    validateImportBatch: vi.fn(async () => ({ valid_count: 1 })),
  } satisfies StagingGateway as StagingGateway & {
    beginImportBatch: ReturnType<typeof vi.fn>;
    stageAssetRows: ReturnType<typeof vi.fn>;
    stageLicenseRows: ReturnType<typeof vi.fn>;
    validateImportBatch: ReturnType<typeof vi.fn>;
  };
}

function asset(index: number): ParsedAsset {
  return {
    sourceFile: path.basename("assets.xlsx"),
    sheetName: "Software(Factory)",
    sourceRow: index + 6,
    sourceCells: { assetCode: `J${index + 6}` },
    siteCode: "factory",
    assetType: "pc",
    assetCode: `A-${index}`,
    computerName: `PC-${index}`,
    location: "Factory",
    responsiblePerson: "",
    userName: "",
    maker: "",
    model: "",
    purchaseDate: null,
    workgroup: "",
    operatingSystem: "",
    remark: "",
    businessKey: `factory-${index}`,
  };
}

function license(index: number): LicenseStagingRow {
  return {
    sourceFile: "licenses.xlsx",
    sheetName: "Software License FACTORY",
    sourceSheet: "Software License FACTORY",
    sourceRow: index + 9,
    sourceCells: { productName: `E${index + 9}` },
    siteCode: "factory",
    normalizedPublisher: "Maker",
    normalizedVendor: "Vendor",
    normalizedProductName: `Product-${index}`,
    normalizedVersion: "",
    normalizedClassification: "",
    normalizedPurchaseForm: "",
    normalizedOwnedQuantity: 1,
    normalizedUsedQuantity: 0,
    purchaseDate: null,
    startDate: null,
    endDate: null,
    installDate: null,
    status: "Active",
    assignedName: "",
    remark: "",
    secretMaskedHint: index === 0 ? "••••-USE" : null,
    secretFingerprint: index === 0 ? "b".repeat(64) : null,
    businessKey: `license-${index}`,
    rawData: { productName: `Product-${index}` },
  };
}
