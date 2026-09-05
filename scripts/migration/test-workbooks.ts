import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";

import ExcelJS from "exceljs";

export async function createAssetFixtureWorkbook(): Promise<string> {
  const directory = await mkdtemp(path.join(tmpdir(), "sam-assets-"));
  const filePath = path.join(directory, "02 203Total License(TKC) Update 2026-08-28.xlsx");
  const workbook = new ExcelJS.Workbook();

  const factory = workbook.addWorksheet("Software(Factory)");
  factory.mergeCells("A4:D4");
  factory.getCell("A4").value = "Location";
  factory.getCell("E4").value = "Persons responsible.";
  factory.getCell("G5").value = "NB";
  factory.getCell("H5").value = "PC";
  factory.getCell("I5").value = "Code No";
  factory.getCell("J5").value = "Computer Name";
  factory.getCell("K5").value = "User";
  factory.getCell("O5").value = "Lan";
  factory.getCell("R5").value = "Lan";
  factory.getCell("AB5").value = "Workgroup";
  factory.getCell("AC5").value = "OS";
  factory.getCell("AE4").value = "License";
  factory.getCell("AE5").value = "Microsoft Office 365";
  factory.getCell("A6").value = "Factory-A";
  factory.getCell("E6").value = "Fixture Owner";
  factory.getCell("H6").value = "x";
  factory.getCell("I6").value = "PC-001";
  factory.getCell("J6").value = { formula: "I6", result: "FACTORY-PC" };
  factory.getCell("K6").value = "Fixture User";
  factory.getCell("O6").value = "00-00-00-00-00-01";
  factory.getCell("R6").value = "192.0.2.10";
  factory.getCell("AE6").value = "x";
  factory.getCell("I7").value = "PC-001";
  factory.getCell("J7").value = "FACTORY-PC";
  factory.getCell("AE7").value = "installed";
  factory.getCell("A8").value = "Malformed fixture row";
  factory.getCell("H8").value = "x";

  const office = workbook.addWorksheet("Software(Bangkok Offic)");
  office.mergeCells("A5:D5");
  office.getCell("A5").value = "Location";
  office.getCell("G6").value = "NB";
  office.getCell("H6").value = "PC";
  office.getCell("I6").value = "Code No";
  office.getCell("J6").value = "Computer Name";
  office.getCell("K6").value = "User";
  office.getCell("L6").value = "Lan";
  office.getCell("O6").value = "Lan";
  office.getCell("T6").value = "Workgroup";
  office.getCell("U6").value = "OS";
  office.getCell("W5").value = "License";
  office.getCell("W6").value = "Microsoft Office 365";
  office.getCell("A7").value = "Bangkok";
  office.getCell("G7").value = "x";
  office.getCell("I7").value = "NB-001";
  office.getCell("J7").value = "OFFICE-NB";
  office.getCell("K7").value = "Office User";
  office.getCell("W7").value = true;

  await workbook.xlsx.writeFile(filePath);
  return filePath;
}

export const INVENTED_SERIAL = "TEST-SERIAL-DO-NOT-USE";

export async function createLicenseFixtureWorkbook(): Promise<string> {
  const directory = await mkdtemp(path.join(tmpdir(), "sam-licenses-"));
  const filePath = path.join(directory, "03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx");
  const workbook = new ExcelJS.Workbook();

  for (const sheetName of ["Software License FACTORY", "Software License OFFICE "]) {
    const sheet = workbook.addWorksheet(sheetName);
    const headers = [
      "No.", "Maker", "Dealer", "Product Name", "Version",
      "Product Classification", "Purchase Form", "Own\nLicense", "Use\nLicense",
      "Serial No.", "Purchase Date", "Start Date", "End Date", "Status",
      "Name", "Install Date", "Remark", "Remark",
    ];
    headers.forEach((header, index) => { sheet.getCell(8, index + 1).value = header; });
  }

  const factory = workbook.getWorksheet("Software License FACTORY")!;
  for (const rowNumber of [9, 10]) {
    factory.getCell(rowNumber, 1).value = rowNumber - 8;
    factory.getCell(rowNumber, 2).value = "Example Maker";
    factory.getCell(rowNumber, 3).value = "Example Dealer";
    factory.getCell(rowNumber, 4).value = "Example Product";
    factory.getCell(rowNumber, 5).value = "2026";
    factory.getCell(rowNumber, 6).value = "Application";
    factory.getCell(rowNumber, 7).value = "Perpetual";
    factory.getCell(rowNumber, 8).value = 5;
    factory.getCell(rowNumber, 9).value = 2;
    factory.getCell(rowNumber, 10).value = INVENTED_SERIAL;
    factory.getCell(rowNumber, 11).value = new Date(Date.UTC(2026, 7, 28));
    factory.getCell(rowNumber, 14).value = "Active";
  }
  factory.getCell(11, 2).value = "Bad Date Maker";
  factory.getCell(11, 4).value = "Bad Date Product";
  factory.getCell(11, 8).value = 1;
  factory.getCell(11, 11).value = "28/08/";

  const office = workbook.getWorksheet("Software License OFFICE ")!;
  office.getCell(9, 2).value = "Office Maker";
  office.getCell(9, 4).value = "Office Product";
  office.getCell(9, 8).value = 3;
  office.getCell(9, 9).value = 1;

  const summaryFactory = workbook.addWorksheet("Summary Factory");
  summaryFactory.getCell("A3").value = "Row Labels";
  summaryFactory.getCell("B3").value = "Sum of Own";
  summaryFactory.getCell("C3").value = "Sum of Use";
  summaryFactory.getCell("A4").value = "Example Product";
  summaryFactory.getCell("B4").value = 10;
  summaryFactory.getCell("C4").value = 4;

  const summaryOffice = workbook.addWorksheet("Summary Office");
  summaryOffice.getCell("A3").value = "Row Labels";
  summaryOffice.getCell("B3").value = "Sum of Own";
  summaryOffice.getCell("C3").value = "Sum of Use";
  summaryOffice.getCell("A4").value = "Office Product";
  summaryOffice.getCell("B4").value = 3;
  summaryOffice.getCell("C4").value = 1;

  await workbook.xlsx.writeFile(filePath);
  return filePath;
}
