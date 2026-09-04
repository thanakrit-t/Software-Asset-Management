import path from "node:path";

import ExcelJS from "exceljs";

import { cellDate, cellText } from "./cell-values";
import { exactBusinessKey } from "./exact-duplicates";
import { sha256File } from "./fingerprint";
import type {
  InstalledSoftwareObservation,
  NetworkObservation,
  ParsedAsset,
  ParsedAssetWorkbook,
  ParserIssue,
  PersonAssignmentObservation,
  SiteCode,
  SourceCoordinate,
} from "./types";

interface SheetLayout {
  sheetName: string;
  siteCode: SiteCode;
  parentHeaderRow: number;
  headerRow: number;
  dataRow: number;
  columns: {
    location: number;
    responsible: number;
    notebook: number;
    pc: number;
    assetCode: number;
    computerName: number;
    user: number;
    maker?: number;
    model?: number;
    purchaseDate?: number;
    mac: readonly [number, "lan" | "wifi"][];
    ip: readonly [number, "lan" | "wifi"][];
    extraUsers: readonly number[];
    workgroup: number;
    operatingSystem: number;
    remark: number;
  };
}

const LAYOUTS: readonly SheetLayout[] = [
  {
    sheetName: "Software(Factory)",
    siteCode: "factory",
    parentHeaderRow: 4,
    headerRow: 5,
    dataRow: 6,
    columns: {
      location: 2,
      responsible: 6,
      notebook: 8,
      pc: 9,
      assetCode: 10,
      computerName: 11,
      user: 12,
      maker: 13,
      model: 14,
      purchaseDate: 15,
      mac: [[16, "lan"], [17, "lan"], [18, "wifi"]],
      ip: [[19, "lan"], [20, "lan"], [21, "wifi"]],
      extraUsers: [25, 26, 27, 28],
      workgroup: 29,
      operatingSystem: 30,
      remark: 62,
    },
  },
  {
    sheetName: "Software(Bangkok Offic)",
    siteCode: "bangkok-office",
    parentHeaderRow: 5,
    headerRow: 6,
    dataRow: 7,
    columns: {
      location: 2,
      responsible: 6,
      notebook: 8,
      pc: 9,
      assetCode: 10,
      computerName: 11,
      user: 12,
      mac: [[13, "lan"], [14, "lan"], [15, "wifi"]],
      ip: [[16, "lan"], [17, "lan"], [18, "wifi"]],
      extraUsers: [],
      workgroup: 21,
      operatingSystem: 22,
      remark: 0,
    },
  },
] as const;

export async function parseAssetWorkbook(filePath: string): Promise<ParsedAssetWorkbook> {
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.readFile(filePath);
  const sourceFile = path.basename(filePath);
  const sourceFingerprint = await sha256File(filePath);
  const result: ParsedAssetWorkbook = {
    sourceFile,
    sourceFingerprint,
    assets: [],
    networkData: [],
    peopleAssignments: [],
    installedSoftware: [],
    issues: [],
  };

  for (const layout of LAYOUTS) {
    const sheet = workbook.getWorksheet(layout.sheetName);
    if (!sheet) {
      result.issues.push(issue("SHEET_MISSING", `Missing required sheet ${layout.sheetName}`, layout.sheetName, 0));
      continue;
    }
    parseSheet(sheet, layout, sourceFile, result);
  }
  return result;
}

function parseSheet(
  sheet: ExcelJS.Worksheet,
  layout: SheetLayout,
  sourceFile: string,
  result: ParsedAssetWorkbook,
): void {
  const softwareColumns = findSoftwareColumns(sheet, layout);
  const seenAssets = new Set<string>();

  for (let sourceRow = layout.dataRow; sourceRow <= sheet.rowCount; sourceRow += 1) {
    const row = sheet.getRow(sourceRow);
    const assetCode = textAt(row, layout.columns.assetCode).trim();
    const computerName = textAt(row, layout.columns.computerName).trim();
    const identity = assetCode || computerName;
    const meaningful = rowHasMeaningfulSafeData(row, layout, softwareColumns);
    if (!identity) {
      if (meaningful && !isTotalsOrNotesRow(row)) {
        result.issues.push(issue(
          "ASSET_BUSINESS_KEY_MISSING",
          "Asset row has data but no Asset Code or Computer Name",
          sheet.name,
          sourceRow,
          "assetIdentity",
        ));
      }
      continue;
    }

    const businessKey = exactBusinessKey([layout.siteCode, identity]);
    const coordinate = coordinateFor(sourceFile, sheet.name, sourceRow, {
      assetCode: row.getCell(layout.columns.assetCode).address,
      computerName: row.getCell(layout.columns.computerName).address,
    });

    if (!seenAssets.has(businessKey)) {
      seenAssets.add(businessKey);
      result.assets.push(buildAsset(row, layout, coordinate, businessKey, assetCode, computerName));
    }
    appendNetwork(row, layout, coordinate, businessKey, result.networkData);
    appendPeople(row, layout, coordinate, businessKey, result.peopleAssignments);
    appendSoftware(row, softwareColumns, coordinate, businessKey, result.installedSoftware);
  }
}

function buildAsset(
  row: ExcelJS.Row,
  layout: SheetLayout,
  coordinate: SourceCoordinate,
  businessKey: string,
  assetCode: string,
  computerName: string,
): ParsedAsset {
  const hasNotebook = isPresent(textAt(row, layout.columns.notebook));
  const hasPc = isPresent(textAt(row, layout.columns.pc));
  return {
    ...coordinate,
    siteCode: layout.siteCode,
    assetType: hasNotebook ? "notebook" : hasPc ? "pc" : "unknown",
    assetCode,
    computerName,
    location: textAt(row, layout.columns.location).trim(),
    responsiblePerson: textAt(row, layout.columns.responsible).trim(),
    userName: textAt(row, layout.columns.user).trim(),
    maker: layout.columns.maker ? textAt(row, layout.columns.maker).trim() : "",
    model: layout.columns.model ? textAt(row, layout.columns.model).trim() : "",
    purchaseDate: layout.columns.purchaseDate ? cellDate(row.getCell(layout.columns.purchaseDate).value) : null,
    workgroup: textAt(row, layout.columns.workgroup).trim(),
    operatingSystem: textAt(row, layout.columns.operatingSystem).trim(),
    remark: layout.columns.remark ? textAt(row, layout.columns.remark).trim() : "",
    businessKey,
  };
}

function appendNetwork(row: ExcelJS.Row, layout: SheetLayout, coordinate: SourceCoordinate, businessKey: string, output: NetworkObservation[]): void {
  for (const [column, interfaceName] of layout.columns.mac) {
    const value = textAt(row, column).trim();
    if (value) output.push({ ...coordinate, assetBusinessKey: businessKey, kind: "mac", interfaceName, value });
  }
  for (const [column, interfaceName] of layout.columns.ip) {
    const value = textAt(row, column).trim();
    if (value) output.push({ ...coordinate, assetBusinessKey: businessKey, kind: "ip", interfaceName, value });
  }
}

function appendPeople(row: ExcelJS.Row, layout: SheetLayout, coordinate: SourceCoordinate, businessKey: string, output: PersonAssignmentObservation[]): void {
  const people: readonly [number, "user" | "responsible"][] = [
    [layout.columns.responsible, "responsible"],
    [layout.columns.user, "user"],
    ...layout.columns.extraUsers.map((column) => [column, "user"] as const),
  ];
  for (const [column, assignmentKind] of people) {
    const personLabel = textAt(row, column).trim();
    if (personLabel) output.push({ ...coordinate, assetBusinessKey: businessKey, personLabel, assignmentKind });
  }
}

function appendSoftware(row: ExcelJS.Row, columns: readonly [number, string][], coordinate: SourceCoordinate, businessKey: string, output: InstalledSoftwareObservation[]): void {
  for (const [column, productLabel] of columns) {
    const sourceValue = textAt(row, column);
    if (sourceValue === "") continue;
    output.push({ ...coordinate, assetBusinessKey: businessKey, productLabel, present: isPresent(sourceValue), sourceValue });
  }
}

function findSoftwareColumns(sheet: ExcelJS.Worksheet, layout: SheetLayout): [number, string][] {
  const columns: [number, string][] = [];
  for (let column = 1; column <= sheet.columnCount; column += 1) {
    const parent = mergedText(sheet.getCell(layout.parentHeaderRow, column)).trim().toLowerCase();
    const label = mergedText(sheet.getCell(layout.headerRow, column)).trim();
    if ((parent === "license" || parent === "free ware") && label && !/license\s*key/i.test(label)) {
      columns.push([column, label]);
    }
  }
  return columns;
}

function mergedText(cell: ExcelJS.Cell): string {
  return cellText((cell.isMerged ? cell.master : cell).value);
}

function textAt(row: ExcelJS.Row, column: number): string {
  return column > 0 ? cellText(row.getCell(column).value) : "";
}

function isPresent(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  return normalized !== "" && !["0", "false", "no", "n", "-"].includes(normalized);
}

function rowHasMeaningfulSafeData(row: ExcelJS.Row, layout: SheetLayout, softwareColumns: readonly [number, string][]): boolean {
  const columns = [layout.columns.location, layout.columns.responsible, layout.columns.user, layout.columns.workgroup, layout.columns.operatingSystem, ...softwareColumns.map(([column]) => column)];
  return columns.some((column) => textAt(row, column).trim() !== "");
}

function isTotalsOrNotesRow(row: ExcelJS.Row): boolean {
  const label = [2, 6, 10, 11].map((column) => textAt(row, column).trim()).find(Boolean) ?? "";
  return /^(?:grand\s+)?total\b|^note\b|^remark\b/i.test(label);
}

function coordinateFor(sourceFile: string, sheetName: string, sourceRow: number, sourceCells: Record<string, string>): SourceCoordinate {
  return { sourceFile, sheetName, sourceRow, sourceCells };
}

function issue(code: string, message: string, sheetName: string, sourceRow: number, field?: string): ParserIssue {
  return { code, message, severity: "error", sheetName, sourceRow, ...(field ? { field } : {}) };
}
