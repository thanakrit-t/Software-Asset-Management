import path from "node:path";

import ExcelJS from "exceljs";

import { cellDate, cellNumber, cellText } from "./cell-values";
import { exactBusinessKey, findExactDuplicates } from "./exact-duplicates";
import { sha256File } from "./fingerprint";
import type {
  LicenseStagingRow,
  LicenseSummaryControl,
  ParsedLicenseWorkbook,
  ParserIssue,
  SecretEnvelope,
  SecretFingerprinter,
  SiteCode,
} from "./types";

interface DetailLayout {
  sheetName: string;
  siteCode: SiteCode;
}

const DETAIL_LAYOUTS: readonly DetailLayout[] = [
  { sheetName: "Software License FACTORY", siteCode: "factory" },
  { sheetName: "Software License OFFICE ", siteCode: "bangkok-office" },
];

const SUMMARY_LAYOUTS: readonly DetailLayout[] = [
  { sheetName: "Summary Factory", siteCode: "factory" },
  { sheetName: "Summary Office", siteCode: "bangkok-office" },
];

export async function parseLicenseWorkbook(
  filePath: string,
  secretFingerprinter: SecretFingerprinter,
): Promise<ParsedLicenseWorkbook> {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(filePath);
  const sourceFile = path.basename(filePath);
  const result: ParsedLicenseWorkbook = {
    sourceFile,
    sourceFingerprint: await sha256File(filePath),
    stagingRows: [],
    secrets: [],
    summaryControls: [],
    issues: [],
  };

  for (const layout of DETAIL_LAYOUTS) {
    const sheet = workbook.getWorksheet(layout.sheetName);
    if (!sheet) {
      result.issues.push(issue("SHEET_MISSING", `Missing required sheet ${layout.sheetName}`, layout.sheetName, 0));
      continue;
    }
    await parseDetailSheet(sheet, layout, sourceFile, secretFingerprinter, result);
  }

  for (const layout of SUMMARY_LAYOUTS) {
    const sheet = workbook.getWorksheet(layout.sheetName);
    if (!sheet) {
      result.issues.push(issue("SUMMARY_SHEET_MISSING", `Missing summary sheet ${layout.sheetName}`, layout.sheetName, 0, undefined, "warning"));
      continue;
    }
    result.summaryControls.push(...parseSummarySheet(sheet, layout));
  }

  for (const duplicate of findExactDuplicates(result.stagingRows, (row) => row.businessKey)) {
    result.issues.push(issue(
      "LICENSE_DUPLICATE_EXACT",
      "License row exactly duplicates another normalized license record",
      duplicate.row.sheetName,
      duplicate.row.sourceRow,
      undefined,
      "warning",
    ));
  }
  return result;
}

async function parseDetailSheet(
  sheet: ExcelJS.Worksheet,
  layout: DetailLayout,
  sourceFile: string,
  secretFingerprinter: SecretFingerprinter,
  result: ParsedLicenseWorkbook,
): Promise<void> {
  assertDetailHeaders(sheet, result.issues);
  for (let sourceRow = 9; sourceRow <= sheet.rowCount; sourceRow += 1) {
    const row = sheet.getRow(sourceRow);
    if (!detailRowHasData(row)) continue;

    const rawSecret = cellText(row.getCell(11).value).trim();
    const secretFingerprint = rawSecret ? await secretFingerprinter(rawSecret) : null;
    const secretMaskedHint = rawSecret ? maskSecret(rawSecret) : null;
    const normalizedPublisher = sanitizedText(row, 3, rawSecret);
    const normalizedVendor = sanitizedText(row, 4, rawSecret);
    const normalizedProductName = sanitizedText(row, 5, rawSecret);
    const normalizedVersion = sanitizedText(row, 6, rawSecret);
    const normalizedClassification = sanitizedText(row, 7, rawSecret);
    const normalizedPurchaseForm = sanitizedText(row, 8, rawSecret);
    const normalizedOwnedQuantity = cellNumber(row.getCell(9).value);
    const normalizedUsedQuantity = cellNumber(row.getCell(10).value);
    const purchaseDate = parseDate(row, 12, "purchaseDate", result.issues, sheet.name, sourceRow);
    const startDate = parseDate(row, 13, "startDate", result.issues, sheet.name, sourceRow);
    const endDate = parseDate(row, 14, "endDate", result.issues, sheet.name, sourceRow);
    const installDate = parseDate(row, 17, "installDate", result.issues, sheet.name, sourceRow);
    const status = sanitizedText(row, 15, rawSecret);
    const assignedName = sanitizedText(row, 16, rawSecret);
    const remark = [sanitizedText(row, 18, rawSecret), sanitizedText(row, 19, rawSecret)].filter(Boolean).join(" | ");

    if (!normalizedProductName) {
      result.issues.push(issue("LICENSE_BUSINESS_KEY_MISSING", "License row has no Product Name", sheet.name, sourceRow, "productName"));
    }
    validateQuantity(normalizedOwnedQuantity, "ownedQuantity", sheet.name, sourceRow, result.issues);
    validateQuantity(normalizedUsedQuantity, "usedQuantity", sheet.name, sourceRow, result.issues);

    const stagingRowIndex = result.stagingRows.length;
    const sourceCells = {
      publisher: row.getCell(3).address,
      productName: row.getCell(5).address,
      ownedQuantity: row.getCell(9).address,
      usedQuantity: row.getCell(10).address,
    };
    const businessKey = exactBusinessKey([
      layout.siteCode,
      normalizedPublisher,
      normalizedProductName,
      normalizedVersion,
      secretFingerprint,
    ]);
    const stagingRow: LicenseStagingRow = {
      sourceFile,
      sheetName: sheet.name,
      sourceSheet: sheet.name,
      sourceRow,
      sourceCells,
      siteCode: layout.siteCode,
      normalizedPublisher,
      normalizedVendor,
      normalizedProductName,
      normalizedVersion,
      normalizedClassification,
      normalizedPurchaseForm,
      normalizedOwnedQuantity,
      normalizedUsedQuantity,
      purchaseDate,
      startDate,
      endDate,
      installDate,
      status,
      assignedName,
      remark,
      secretMaskedHint,
      secretFingerprint,
      businessKey,
      rawData: {
        publisher: normalizedPublisher,
        vendor: normalizedVendor,
        productName: normalizedProductName,
        version: normalizedVersion,
        classification: normalizedClassification,
        purchaseForm: normalizedPurchaseForm,
        ownedQuantity: normalizedOwnedQuantity,
        usedQuantity: normalizedUsedQuantity,
        purchaseDate,
        startDate,
        endDate,
        installDate,
        status,
        assignedName,
        remark,
      },
    };
    result.stagingRows.push(stagingRow);

    if (rawSecret && secretFingerprint && secretMaskedHint) {
      const envelope: SecretEnvelope = {
        sourceFile,
        sheetName: sheet.name,
        sourceRow,
        sourceCells: { secret: row.getCell(11).address },
        stagingRowIndex,
        secretType: "serial",
        value: rawSecret,
        maskedHint: secretMaskedHint,
        fingerprint: secretFingerprint,
      };
      result.secrets.push(envelope);
    }
  }
}

function parseSummarySheet(sheet: ExcelJS.Worksheet, layout: DetailLayout): LicenseSummaryControl[] {
  const controls: LicenseSummaryControl[] = [];
  for (let sourceRow = 4; sourceRow <= sheet.rowCount; sourceRow += 1) {
    const row = sheet.getRow(sourceRow);
    const label = cellText(row.getCell(2).value).trim();
    if (!label || /^grand total$/i.test(label)) continue;
    const ownedQuantity = cellNumber(row.getCell(3).value);
    const usedQuantity = cellNumber(row.getCell(4).value);
    if (ownedQuantity == null && usedQuantity == null) continue;
    controls.push({
      siteCode: layout.siteCode,
      label,
      ownedQuantity: ownedQuantity ?? 0,
      usedQuantity: usedQuantity ?? 0,
      sourceSheet: sheet.name,
      sourceRow,
    });
  }
  return controls;
}

function assertDetailHeaders(sheet: ExcelJS.Worksheet, issues: ParserIssue[]): void {
  const expected = new Map([[3, "Maker"], [5, "Product Name"], [9, "Own License"], [10, "Use License"], [11, "Serial No."]]);
  for (const [column, label] of expected) {
    const actual = cellText(sheet.getRow(8).getCell(column).value).replace(/\s+/g, " ").trim();
    if (actual !== label) issues.push(issue("LICENSE_HEADER_INVALID", `Expected header ${label}`, sheet.name, 8, label));
  }
}

function parseDate(row: ExcelJS.Row, column: number, field: string, issues: ParserIssue[], sheetName: string, sourceRow: number): string | null {
  const value = row.getCell(column).value;
  const text = cellText(value).trim();
  if (!text) return null;
  const parsed = cellDate(value);
  if (!parsed) issues.push(issue("LICENSE_DATE_INVALID", `Date field ${field} is not a typed Excel date`, sheetName, sourceRow, field));
  return parsed;
}

function validateQuantity(value: number | null, field: string, sheetName: string, sourceRow: number, issues: ParserIssue[]): void {
  if (value != null && (!Number.isInteger(value) || value < 0)) {
    issues.push(issue("LICENSE_QUANTITY_INVALID", `${field} must be a non-negative integer`, sheetName, sourceRow, field));
  }
}

function sanitizedText(row: ExcelJS.Row, column: number, rawSecret: string): string {
  const value = cellText(row.getCell(column).value).trim();
  return rawSecret ? value.split(rawSecret).join("[REDACTED]") : value;
}

function detailRowHasData(row: ExcelJS.Row): boolean {
  return [3, 4, 5, 6, 9, 10, 11, 15, 16, 18, 19].some((column) => cellText(row.getCell(column).value).trim() !== "");
}

function maskSecret(value: string): string {
  const suffix = value.slice(-3);
  return suffix ? `••••-${suffix}` : "••••";
}

function issue(code: string, message: string, sheetName: string, sourceRow: number, field?: string, severity: "error" | "warning" = "error"): ParserIssue {
  return { code, message, severity, sheetName, sourceRow, ...(field ? { field } : {}) };
}
