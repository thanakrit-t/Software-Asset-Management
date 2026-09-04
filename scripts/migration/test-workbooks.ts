import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";

import ExcelJS from "exceljs";

export async function createAssetFixtureWorkbook(): Promise<string> {
  const directory = await mkdtemp(path.join(tmpdir(), "sam-assets-"));
  const filePath = path.join(directory, "assets.xlsx");
  const workbook = new ExcelJS.Workbook();

  const factory = workbook.addWorksheet("Software(Factory)");
  factory.mergeCells("B4:E4");
  factory.getCell("B4").value = "Location";
  factory.getCell("F4").value = "Persons responsible.";
  factory.getCell("H5").value = "NB";
  factory.getCell("I5").value = "PC";
  factory.getCell("J5").value = "Code No";
  factory.getCell("K5").value = "Computer Name";
  factory.getCell("L5").value = "User";
  factory.getCell("P5").value = "Lan";
  factory.getCell("S5").value = "Lan";
  factory.getCell("AC5").value = "Workgroup";
  factory.getCell("AD5").value = "OS";
  factory.getCell("AF4").value = "License";
  factory.getCell("AF5").value = "Microsoft Office 365";
  factory.getCell("B6").value = "Factory-A";
  factory.getCell("F6").value = "Fixture Owner";
  factory.getCell("I6").value = "x";
  factory.getCell("J6").value = "PC-001";
  factory.getCell("K6").value = { formula: "J6", result: "FACTORY-PC" };
  factory.getCell("L6").value = "Fixture User";
  factory.getCell("P6").value = "00-00-00-00-00-01";
  factory.getCell("S6").value = "192.0.2.10";
  factory.getCell("AF6").value = "x";
  factory.getCell("J7").value = "PC-001";
  factory.getCell("K7").value = "FACTORY-PC";
  factory.getCell("AF7").value = "installed";
  factory.getCell("B8").value = "Malformed fixture row";

  const office = workbook.addWorksheet("Software(Bangkok Offic)");
  office.mergeCells("B5:E5");
  office.getCell("B5").value = "Location";
  office.getCell("H6").value = "NB";
  office.getCell("I6").value = "PC";
  office.getCell("J6").value = "Code No";
  office.getCell("K6").value = "Computer Name";
  office.getCell("L6").value = "User";
  office.getCell("M6").value = "Lan";
  office.getCell("P6").value = "Lan";
  office.getCell("U6").value = "Workgroup";
  office.getCell("V6").value = "OS";
  office.getCell("X5").value = "License";
  office.getCell("X6").value = "Microsoft Office 365";
  office.getCell("B7").value = "Bangkok";
  office.getCell("H7").value = "x";
  office.getCell("J7").value = "NB-001";
  office.getCell("K7").value = "OFFICE-NB";
  office.getCell("L7").value = "Office User";
  office.getCell("X7").value = true;

  await workbook.xlsx.writeFile(filePath);
  return filePath;
}

export const INVENTED_SERIAL = "TEST-SERIAL-DO-NOT-USE";

export async function createLicenseFixtureWorkbook(): Promise<string> {
  const directory = await mkdtemp(path.join(tmpdir(), "sam-licenses-"));
  const filePath = path.join(directory, "licenses.xlsx");
  const workbook = new ExcelJS.Workbook();

  for (const sheetName of ["Software License FACTORY", "Software License OFFICE "]) {
    const sheet = workbook.addWorksheet(sheetName);
    const headers = [
      "No.", "Maker", "Dealer", "Product Name", "Version",
      "Product Classification", "Purchase Form", "Own\nLicense", "Use\nLicense",
      "Serial No.", "Purchase Date", "Start Date", "End Date", "Status",
      "Name", "Install Date", "Remark", "Remark",
    ];
    headers.forEach((header, index) => { sheet.getCell(8, index + 2).value = header; });
  }

  const factory = workbook.getWorksheet("Software License FACTORY")!;
  for (const rowNumber of [9, 10]) {
    factory.getCell(rowNumber, 2).value = rowNumber - 8;
    factory.getCell(rowNumber, 3).value = "Example Maker";
    factory.getCell(rowNumber, 4).value = "Example Dealer";
    factory.getCell(rowNumber, 5).value = "Example Product";
    factory.getCell(rowNumber, 6).value = "2026";
    factory.getCell(rowNumber, 7).value = "Application";
    factory.getCell(rowNumber, 8).value = "Perpetual";
    factory.getCell(rowNumber, 9).value = 5;
    factory.getCell(rowNumber, 10).value = 2;
    factory.getCell(rowNumber, 11).value = INVENTED_SERIAL;
    factory.getCell(rowNumber, 12).value = new Date(Date.UTC(2026, 7, 28));
    factory.getCell(rowNumber, 15).value = "Active";
  }
  factory.getCell(11, 3).value = "Bad Date Maker";
  factory.getCell(11, 5).value = "Bad Date Product";
  factory.getCell(11, 9).value = 1;
  factory.getCell(11, 12).value = "28/08/2026";

  const office = workbook.getWorksheet("Software License OFFICE ")!;
  office.getCell(9, 3).value = "Office Maker";
  office.getCell(9, 5).value = "Office Product";
  office.getCell(9, 9).value = 3;
  office.getCell(9, 10).value = 1;

  const summaryFactory = workbook.addWorksheet("Summary Factory");
  summaryFactory.getCell("B3").value = "Row Labels";
  summaryFactory.getCell("C3").value = "Sum of Own";
  summaryFactory.getCell("D3").value = "Sum of Use";
  summaryFactory.getCell("B4").value = "Example Product";
  summaryFactory.getCell("C4").value = 10;
  summaryFactory.getCell("D4").value = 4;

  const summaryOffice = workbook.addWorksheet("Summary Office");
  summaryOffice.getCell("B3").value = "Row Labels";
  summaryOffice.getCell("C3").value = "Sum of Own";
  summaryOffice.getCell("D3").value = "Sum of Use";
  summaryOffice.getCell("B4").value = "Office Product";
  summaryOffice.getCell("C4").value = 3;
  summaryOffice.getCell("D4").value = 1;

  await workbook.xlsx.writeFile(filePath);
  return filePath;
}
