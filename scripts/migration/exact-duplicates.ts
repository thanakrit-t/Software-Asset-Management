export interface ExactDuplicate<T> {
  index: number;
  key: string;
  row: T;
}

export function exactBusinessKey(parts: readonly unknown[]): string {
  return parts.map((part) => (part == null ? "" : String(part))).join("\u001f");
}

export function findExactDuplicates<T>(
  rows: readonly T[],
  keyOf: (row: T) => string,
): ExactDuplicate<T>[] {
  const indexesByKey = new Map<string, number[]>();
  rows.forEach((row, index) => {
    const key = keyOf(row);
    const indexes = indexesByKey.get(key) ?? [];
    indexes.push(index);
    indexesByKey.set(key, indexes);
  });

  const duplicates: ExactDuplicate<T>[] = [];
  for (const [key, indexes] of indexesByKey) {
    if (indexes.length < 2) continue;
    for (const index of indexes) duplicates.push({ index, key, row: rows[index] });
  }
  return duplicates.sort((left, right) => left.index - right.index);
}
