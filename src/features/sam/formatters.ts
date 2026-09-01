const THAI_SHORT_MONTHS = [
  "ม.ค.",
  "ก.พ.",
  "มี.ค.",
  "เม.ย.",
  "พ.ค.",
  "มิ.ย.",
  "ก.ค.",
  "ส.ค.",
  "ก.ย.",
  "ต.ค.",
  "พ.ย.",
  "ธ.ค.",
] as const;

export function maskLicenseKey(value: string): string {
  const secretIndexes = [...value]
    .map((character, index) => ({ character, index }))
    .filter(({ character }) => !/[-\s]/.test(character))
    .map(({ index }) => index);
  const revealedIndexes = new Set(secretIndexes.slice(-5));

  return [...value]
    .map((character, index) => {
      if (/[-\s]/.test(character) || revealedIndexes.has(index)) return character;
      return "•";
    })
    .join("");
}

export function formatDate(value?: string): string {
  if (!value) return "—";
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  if (!year || !month || !day || month < 1 || month > 12) return "—";
  return `${day} ${THAI_SHORT_MONTHS[month - 1]} ${year}`;
}

export function formatNumber(value: number): string {
  return new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 }).format(value);
}
