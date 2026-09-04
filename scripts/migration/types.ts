export type SiteCode = "factory" | "bangkok-office";

export interface SourceCoordinate {
  sourceFile: string;
  sheetName: string;
  sourceRow: number;
  sourceCells: Record<string, string>;
}

export interface ParserIssue {
  code: string;
  message: string;
  severity: "error" | "warning";
  sheetName: string;
  sourceRow: number;
  field?: string;
}

export interface ParsedAsset extends SourceCoordinate {
  siteCode: SiteCode;
  assetType: "pc" | "notebook" | "unknown";
  assetCode: string;
  computerName: string;
  location: string;
  responsiblePerson: string;
  userName: string;
  maker: string;
  model: string;
  purchaseDate: string | null;
  workgroup: string;
  operatingSystem: string;
  remark: string;
  businessKey: string;
}

export interface NetworkObservation extends SourceCoordinate {
  assetBusinessKey: string;
  kind: "mac" | "ip";
  interfaceName: "lan" | "wifi";
  value: string;
}

export interface PersonAssignmentObservation extends SourceCoordinate {
  assetBusinessKey: string;
  personLabel: string;
  assignmentKind: "user" | "responsible";
}

export interface InstalledSoftwareObservation extends SourceCoordinate {
  assetBusinessKey: string;
  productLabel: string;
  present: boolean;
  sourceValue: string;
}

export interface ParsedAssetWorkbook {
  sourceFile: string;
  sourceFingerprint: string;
  assets: ParsedAsset[];
  networkData: NetworkObservation[];
  peopleAssignments: PersonAssignmentObservation[];
  installedSoftware: InstalledSoftwareObservation[];
  issues: ParserIssue[];
}

export type SecretType = "serial" | "license_key" | "product_key" | "os_key";

export interface SecretEnvelope extends SourceCoordinate {
  stagingRowIndex: number;
  secretType: SecretType;
  value: string;
  maskedHint: string;
  fingerprint: string;
}

export interface LicenseStagingRow extends SourceCoordinate {
  siteCode: SiteCode;
  normalizedPublisher: string;
  normalizedVendor: string;
  normalizedProductName: string;
  normalizedVersion: string;
  normalizedClassification: string;
  normalizedPurchaseForm: string;
  normalizedOwnedQuantity: number | null;
  normalizedUsedQuantity: number | null;
  purchaseDate: string | null;
  startDate: string | null;
  endDate: string | null;
  installDate: string | null;
  status: string;
  assignedName: string;
  remark: string;
  secretMaskedHint: string | null;
  secretFingerprint: string | null;
  businessKey: string;
  rawData: Record<string, string | number | null>;
}

export interface LicenseSummaryControl {
  siteCode: SiteCode;
  label: string;
  ownedQuantity: number;
  usedQuantity: number;
  sourceSheet: string;
  sourceRow: number;
}

export interface ParsedLicenseWorkbook {
  sourceFile: string;
  sourceFingerprint: string;
  stagingRows: LicenseStagingRow[];
  secrets: SecretEnvelope[];
  summaryControls: LicenseSummaryControl[];
  issues: ParserIssue[];
}

export interface SecretFingerprinter {
  (value: string): string | Promise<string>;
}

export interface SourceDescriptor {
  kind: "assets" | "licenses";
  fileName: string;
  fingerprint: string;
}

export interface StagingGateway {
  beginImportBatch(sources: readonly SourceDescriptor[]): Promise<string>;
  stageAssetRows(batchId: string, rows: readonly unknown[]): Promise<void>;
  stageLicenseRows(
    batchId: string,
    rows: readonly unknown[],
    secrets: readonly SecretEnvelope[],
  ): Promise<void>;
  validateImportBatch(batchId: string): Promise<unknown>;
}
