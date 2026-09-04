import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";

import { describe, expect, test } from "vitest";

import { cellDate, cellNumber, cellText } from "./cell-values";
import { exactBusinessKey, findExactDuplicates } from "./exact-duplicates";
import { sha256File } from "./fingerprint";

describe("parser primitives", () => {
  test("uses a formula result without evaluating workbook formulas", () => {
    expect(cellText({ formula: "A1+B1", result: 3 })).toBe("3");
    expect(cellNumber({ formula: "A1+B1", result: 3 })).toBe(3);
  });

  test("parses typed dates and rejects arbitrary date text", () => {
    expect(cellDate(new Date(Date.UTC(2026, 7, 28)))).toBe("2026-08-28");
    expect(cellDate("28/08/2026")).toBeNull();
  });

  test("exact duplicate keys preserve case and internal whitespace", () => {
    expect(exactBusinessKey(["Microsoft", "Office 365", ""])).toBe(
      "Microsoft\u001fOffice 365\u001f",
    );
    expect(exactBusinessKey(["Microsoft", "office 365", ""])).not.toBe(
      exactBusinessKey(["Microsoft", "Office 365", ""]),
    );
    expect(exactBusinessKey(["Microsoft", "Office  365", ""])).not.toBe(
      exactBusinessKey(["Microsoft", "Office 365", ""]),
    );
  });

  test("finds every member of an exact duplicate group", () => {
    const rows = [{ key: "A" }, { key: "B" }, { key: "A" }];
    expect(findExactDuplicates(rows, (row) => row.key)).toEqual([
      { index: 0, key: "A", row: rows[0] },
      { index: 2, key: "A", row: rows[2] },
    ]);
  });

  test("file fingerprint is stable and content based", async () => {
    const directory = await mkdtemp(path.join(tmpdir(), "sam-parser-"));
    const fixturePath = path.join(directory, "fixture.bin");
    await writeFile(fixturePath, "stable fixture", "utf8");
    const first = await sha256File(fixturePath);
    expect(first).toMatch(/^[a-f0-9]{64}$/);
    expect(await sha256File(fixturePath)).toBe(first);
  });
});
