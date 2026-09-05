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
    if (!cellText(row.getCell(4).value).trim()) continue;

    const rawSecret = cellText(row.getCell(10).value).trim();
    const secretFingerprint = rawSecret ? await secretFingerprinter(rawSecret) : null;
    const secretMaskedHint = rawSecret ? maskSecret(rawSecret) : null;
    const normalizedPublisher = sanitizedText(row, 2, rawSecret);
    const normalizedVendor = sanitizedText(row, 3, rawSecret);
    const normalizedProductName = sanitizedText(row, 4, rawSecret);
    const normalizedVersion = sanitizedText(row, 5, rawSecret);
    const normalizedClassification = sanitizedText(row, 6, rawSecret);
    const normalizedPurchaseForm = sanitizedText(row, 7, rawSecret);
    const normalizedOwnedQuantity = cellNumber(row.getCell(8).value);
    const normalizedUsedQuantity = cellNumber(row.getCell(9).value);
    const purchaseDate = parseDate(row, 11, "purchaseDate", result.issues, sheet.name, sourceRow);
    const startDate = parseDate(row, 12, "startDate", result.issues, sheet.name, sourceRow);
    const endDate = parseDate(row, 13, "endDate", result.issues, sheet.name, sourceRow);
    const installDate = parseDate(row, 16, "installDate", result.issues, sheet.name, sourceRow);
    const status = sanitizedText(row, 14, rawSecret);
    const assignedName = sanitizedText(row, 15, rawSecret);
    const remark = [sanitizedText(row, 17, rawSecret), sanitizedText(row, 18, rawSecret)].filter(Boolean).join(" | ");

    if (!normalizedProductName) {
      result.issues.push(issue("LICENSE_BUSINESS_KEY_MISSING", "License row has no Product Name", sheet.name, sourceRow, "productName"));
    }
    validateQuantity(normalizedOwnedQuantity, "ownedQuantity", sheet.name, sourceRow, result.issues);
    validateQuantity(normalizedUsedQuantity, "usedQuantity", sheet.name, sourceRow, result.issues);

    const stagingRowIndex = result.stagingRows.length;
    const sourceCells = {
      publisher: row.getCell(2).address,
      productName: row.getCell(4).address,
      ownedQuantity: row.getCell(8).address,
      usedQuantity: row.getCell(9).address,
    };
    const businessKey = exactBusinessKey([
      layout.siteCode,
      normalizedPublisher,
      normalizedVendor,
      normalizedProductName,
      normalizedVersion,
      purchaseDate,
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
        sourceCells: { secret: row.getCell(10).address },
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
    const label = cellText(row.getCell(1).value).trim();
    if (!label || /^grand total$/i.test(label)) continue;
    const ownedQuantity = cellNumber(row.getCell(2).value);
    const usedQuantity = cellNumber(row.getCell(3).value);
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
  const expected = new Map([[2, "Maker"], [4, "Product Name"], [8, "Own License"], [9, "Use License"], [10, "Serial No."]]);
  for (const [column, label] of expected) {
    const actual = cellText(sheet.getRow(8).getCell(column).value).replace(/\s+/g, " ").trim();
    if (actual !== label) issues.push(issue("LICENSE_HEADER_INVALID", `Expected header ${label}`, sheet.name, 8, label));
  }
}

function parseDate(row: ExcelJS.Row, column: number, field: string, issues: ParserIssue[], sheetName: string, sourceRow: number): string | null {
  const value = row.getCell(column).value;
  const text = cellText(value).trim();
  if (!text) return null;
  const parsed = cellDate(value) ?? parseTextDate(text);
  if (!parsed) {
    issues.push(issue(
      "LICENSE_DATE_INVALID",
      `Date field ${field} is not a supported date`,
      sheetName,
      sourceRow,
      field,
      "warning",
    ));
  }
  return parsed;
}

function parseTextDate(text: string): string | null {
  const normalized = text.trim().replace(/\/+/g, "/");
  const iso = normalized.match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$/);
  if (iso) return validIsoDate(Number(iso[1]), Number(iso[2]), Number(iso[3]));
  const dayFirst = normalized.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (dayFirst) {
    return validIsoDate(Number(dayFirst[3]), Number(dayFirst[2]), Number(dayFirst[1]));
  }
  return null;
}

function validIsoDate(year: number, month: number, day: number): string | null {
  const value = new Date(Date.UTC(year, month - 1, day));
  if (
    value.getUTCFullYear() !== year ||
    value.getUTCMonth() !== month - 1 ||
    value.getUTCDate() !== day
  ) return null;
  return [
    String(year).padStart(4, "0"),
    String(month).padStart(2, "0"),
    String(day).padStart(2, "0"),
  ].join("-");
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


function maskSecret(value: string): string {
  const suffix = value.slice(-3);
  return suffix ? `••••-${suffix}` : "••••";
}

function issue(code: string, message: string, sheetName: string, sourceRow: number, field?: string, severity: "error" | "warning" = "error"): ParserIssue {
  return { code, message, severity, sheetName, sourceRow, ...(field ? { field } : {}) };
}
