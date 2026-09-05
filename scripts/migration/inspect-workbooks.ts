import ExcelJS from "exceljs";
import path from "node:path";

const files = [
  "02 203Total License(TKC) Update 2026-08-28.xlsx",
  "03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx",
] as const;

async function main() {
  for (const file of files) {
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.readFile(path.resolve(file));
    console.log(JSON.stringify({
      file,
      sheets: workbook.worksheets.map((sheet) => ({
        name: sheet.name,
        rows: sheet.rowCount,
        columns: sheet.columnCount,
        merges: Object.keys((sheet.model as { merges?: string[] }).merges ?? {}).length,
      })),
    }));
  }
}

void main();
