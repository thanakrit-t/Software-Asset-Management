import type ExcelJS from "exceljs";

type CellLikeValue = ExcelJS.CellValue | undefined;

export function safeFormulaValue(value: CellLikeValue): unknown {
  if (value && typeof value === "object") {
    if ("formula" in value || "sharedFormula" in value) {
      return value.result ?? null;
    }
  }
  return value ?? null;
}

export function cellText(value: CellLikeValue): string {
  const resolved = safeFormulaValue(value);
  if (resolved == null) return "";
  if (resolved instanceof Date) return formatIsoDate(resolved);
  if (typeof resolved === "string") return resolved;
  if (typeof resolved === "number" || typeof resolved === "boolean") {
    return String(resolved);
  }
  if (typeof resolved === "object") {
    if ("richText" in resolved && Array.isArray(resolved.richText)) {
      return resolved.richText.map((fragment: { text?: unknown }) =>
        typeof fragment.text === "string" ? fragment.text : "").join("");
    }
    if ("text" in resolved && typeof resolved.text === "string") {
      return resolved.text;
    }
    if ("error" in resolved) return "";
  }
  return "";
}

export function cellNumber(value: CellLikeValue): number | null {
  const resolved = safeFormulaValue(value);
  if (typeof resolved === "number" && Number.isFinite(resolved)) return resolved;
  if (typeof resolved !== "string") return null;
  const candidate = resolved.trim();
  if (!/^-?(?:\d+|\d*\.\d+)$/.test(candidate)) return null;
  const parsed = Number(candidate);
  return Number.isFinite(parsed) ? parsed : null;
}

export function cellDate(value: CellLikeValue): string | null {
  const resolved = safeFormulaValue(value);
  return resolved instanceof Date && !Number.isNaN(resolved.valueOf())
    ? formatIsoDate(resolved)
    : null;
}

function formatIsoDate(value: Date): string {
  const year = value.getUTCFullYear();
  const month = String(value.getUTCMonth() + 1).padStart(2, "0");
  const day = String(value.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}
