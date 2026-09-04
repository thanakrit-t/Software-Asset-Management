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
