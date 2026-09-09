import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { parseAssetWorkbook } from "./asset-workbook";
import { parseLicenseWorkbook } from "./license-workbook";
import type {
  InstalledSoftwareObservation, NetworkObservation, ParsedAsset, ParsedAssetWorkbook,
  ParsedLicenseWorkbook, PersonAssignmentObservation, SecretEnvelope,
  SecretFingerprinter, SourceDescriptor, StagingGateway,
} from "./types";

export const APPROVED_FILES = {
  assets: "02 203Total License(TKC) Update 2026-08-28.xlsx",
  licenses: "03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx",
} as const;
const MAX_RPC_ROWS = 100;

interface WorkbookPaths { assets: string; licenses: string }
interface FileMetadata { size: number; modifiedAt: string }
interface StageOptions {
  dryRun: boolean;
  sourceSelection: "all" | "assets-only" | "licenses-only";
  paths: WorkbookPaths;
  gateway: StagingGateway;
  log?: (line: string) => void;
  assetParser?: (filePath: string) => Promise<ParsedAssetWorkbook>;
  licenseParser?: (filePath: string, secretFingerprinter: SecretFingerprinter) => Promise<ParsedLicenseWorkbook>;
  fileMetadata?: (filePath: string) => Promise<FileMetadata>;
  secretFingerprinter?: SecretFingerprinter;
}
export interface StageResult {
  batchId: string | null;
  validation: unknown | null;
  counts: {
    assets: number; licenses: number; networkObservations: number;
    peopleAssignments: number; installedSoftware: number; licenseSecrets: number;
    parserErrors: number; parserWarnings: number;
  };
}

export async function stageApprovedWorkbooks(options: StageOptions): Promise<StageResult> {
  const log = options.log ?? console.log;
  const assetsOnly = options.sourceSelection === "assets-only";
  const licensesOnly = options.sourceSelection === "licenses-only";
  const injectedParsers = Boolean(options.assetParser && options.licenseParser);
  if (!injectedParsers) {
    if (!licensesOnly) assertApprovedPath(options.paths.assets, APPROVED_FILES.assets);
    if (!assetsOnly) assertApprovedPath(options.paths.licenses, APPROVED_FILES.licenses);
  }
  const secretFingerprinter = options.secretFingerprinter ??
    ((value: string) => createHash("sha256").update(value, "utf8").digest("hex"));
  const [assets, licenses, assetMetadata, licenseMetadata] = await Promise.all([
    licensesOnly
      ? Promise.resolve(null)
      : (options.assetParser ?? parseAssetWorkbook)(options.paths.assets),
    assetsOnly
      ? Promise.resolve(null)
      : (options.licenseParser ?? parseLicenseWorkbook)(options.paths.licenses, secretFingerprinter),
    licensesOnly ? Promise.resolve(null) : (options.fileMetadata ?? readMetadata)(options.paths.assets),
    assetsOnly ? Promise.resolve(null) : (options.fileMetadata ?? readMetadata)(options.paths.licenses),
  ]);
  const issues = [...(assets?.issues ?? []), ...(licenses?.issues ?? [])];
  const parserErrors = issues.filter((issue) => issue.severity === "error").length;
  const parserWarnings = issues.filter((issue) => issue.severity === "warning").length;
  const counts = {
    assets: assets?.assets.length ?? 0,
    licenses: licenses?.stagingRows.length ?? 0,
    networkObservations: assets?.networkData.length ?? 0,
    peopleAssignments: assets?.peopleAssignments.length ?? 0,
    installedSoftware: assets?.installedSoftware.filter((item) => item.present).length ?? 0,
    licenseSecrets: licenses?.secrets.length ?? 0,
    parserErrors,
    parserWarnings,
  };
  const sources: SourceDescriptor[] = [];
  if (assets && assetMetadata) {
    sources.push(descriptor("asset", assets.sourceFile, assets.sourceFingerprint, assetMetadata));
  }
  if (licenses && licenseMetadata) {
    sources.push(descriptor("license", licenses.sourceFile, licenses.sourceFingerprint, licenseMetadata));
  }
  log(JSON.stringify({
    mode: options.dryRun ? "dry-run" : "live",
    sources: sources.map(({ kind, fileName, fingerprint, fileSizeBytes }) =>
      ({ kind, fileName, fingerprint, fileSizeBytes })),
    counts,
    issues: issues.map(({ code, severity, sheetName, sourceRow, field }) =>
      ({ code, severity, sheetName, sourceRow, ...(field ? { field } : {}) })),
  }));
  if (options.dryRun) return { batchId: null, validation: null, counts };
  if (parserErrors > 0) throw new Error(`PARSER_ERRORS:${parserErrors}`);

  const batchId = await options.gateway.beginImportBatch(sources);
  if (assets) {
    for (const chunk of chunks(buildAssetRows(assets), MAX_RPC_ROWS)) {
      await options.gateway.stageAssetRows(batchId, chunk);
    }
  }
  if (licenses) {
    for (const [offset, chunk] of chunksWithOffset(licenses.stagingRows, MAX_RPC_ROWS)) {
      const secrets = licenses.secrets.filter(
        (secret) => secret.stagingRowIndex >= offset && secret.stagingRowIndex < offset + chunk.length,
      );
      await options.gateway.stageLicenseRows(batchId, chunk, secrets);
    }
  }
  const validation = await options.gateway.validateImportBatch(batchId);
  log(JSON.stringify({ mode: "live-complete", batchId, validation }));
  return { batchId, validation, counts };
}

function buildAssetRows(workbook: ParsedAssetWorkbook): unknown[] {
  const networks = groupBy(workbook.networkData, (row) => row.assetBusinessKey);
  const people = groupBy(workbook.peopleAssignments, (row) => row.assetBusinessKey);
  const software = groupBy(
    workbook.installedSoftware.filter((row) => row.present),
    (row) => row.assetBusinessKey,
  );
  return workbook.assets.map((asset) => ({
    ...asset,
    networkData: networks.get(asset.businessKey) ?? [],
    peopleAssignments: people.get(asset.businessKey) ?? [],
    installedSoftware: software.get(asset.businessKey) ?? [],
  }));
}
function groupBy<T extends NetworkObservation | PersonAssignmentObservation | InstalledSoftwareObservation>(
  rows: readonly T[], keyOf: (row: T) => string,
): Map<string, T[]> {
  const grouped = new Map<string, T[]>();
  for (const row of rows) grouped.set(keyOf(row), [...(grouped.get(keyOf(row)) ?? []), row]);
  return grouped;
}
function descriptor(
  kind: SourceDescriptor["kind"], fileName: string, fingerprint: string, metadata: FileMetadata,
): SourceDescriptor {
  return { kind, fileName, fingerprint, fileSizeBytes: metadata.size, sourceModifiedAt: metadata.modifiedAt };
}
function assertApprovedPath(filePath: string, approvedName: string): void {
  if (path.basename(filePath) !== approvedName) {
    throw new Error(`UNAPPROVED_SOURCE_FILE:${path.basename(filePath)}`);
  }
}
async function readMetadata(filePath: string): Promise<FileMetadata> {
  const info = await stat(filePath);
  return { size: info.size, modifiedAt: info.mtime.toISOString() };
}
function chunks<T>(rows: readonly T[], size: number): T[][] {
  return chunksWithOffset(rows, size).map(([, chunk]) => chunk);
}
function chunksWithOffset<T>(rows: readonly T[], size: number): [number, T[]][] {
  const result: [number, T[]][] = [];
  for (let offset = 0; offset < rows.length; offset += size) {
    result.push([offset, rows.slice(offset, offset + size)]);
  }
  return result;
}

export function createSupabaseStagingGateway(client: SupabaseClient): StagingGateway {
  return {
    async beginImportBatch(sources) {
      return rpc<string>(client, "begin_import_batch", { payload: {
        batch_name: `Approved Excel migration ${new Date().toISOString()}`,
        environment: "hosted",
        sources: sources.map((source) => ({
          kind: source.kind, file_name: source.fileName, sha256: source.fingerprint,
          file_size_bytes: source.fileSizeBytes, source_modified_at: source.sourceModifiedAt,
        })),
      } });
    },
    async stageAssetRows(batchId, rows) {
      await rpc(client, "stage_asset_rows", {
        import_batch_id: batchId, rows: rows.map(toAssetPayload),
      });
    },
    async stageLicenseRows(batchId, rows, secrets) {
      const bySource = new Map(secrets.map((secret) =>
        [`${secret.sheetName}\u001f${secret.sourceRow}`, secret]));
      const payload = rows.map((value) => {
        const row = value as ParsedLicenseWorkbook["stagingRows"][number];
        return toLicensePayload(row, bySource.get(`${row.sheetName}\u001f${row.sourceRow}`));
      });
      await rpc(client, "stage_license_rows", { import_batch_id: batchId, rows: payload });
    },
    async validateImportBatch(batchId) {
      return rpc(client, "validate_import_batch", { import_batch_id: batchId });
    },
  };
}

function toAssetPayload(value: unknown): Record<string, unknown> {
  const asset = value as ParsedAsset & {
    networkData: NetworkObservation[];
    peopleAssignments: PersonAssignmentObservation[];
    installedSoftware: InstalledSoftwareObservation[];
  };
  const primaryMac = asset.networkData
    .map((item) => item.kind === "mac" ? normalizeMac(item.value) : null).find(Boolean) ?? null;
  const primaryIp = asset.networkData
    .map((item) => item.kind === "ip" ? normalizeIp(item.value) : null).find(Boolean) ?? null;
  const rawData = {
    asset_type: asset.assetType, location: asset.location,
    responsible_person: asset.responsiblePerson, user_name: asset.userName,
    manufacturer: asset.maker, model: asset.model, purchase_date: asset.purchaseDate,
    workgroup: asset.workgroup, operating_system: asset.operatingSystem, remark: asset.remark,
    network_data: asset.networkData.map(({ kind, interfaceName, value: networkValue }) =>
      ({ kind, interface_name: interfaceName, value: networkValue })),
    people_assignments: asset.peopleAssignments.map(({ personLabel, assignmentKind }) =>
      ({ person_label: personLabel, assignment_kind: assignmentKind })),
    installed_software: asset.installedSoftware.map(({ productLabel }) => ({ product_label: productLabel })),
  };
  return {
    source_file_name: asset.sourceFile, sheet_name: asset.sheetName,
    source_row_number: asset.sourceRow,
    source_row_hash: stableHash({ ...rawData, asset_code: asset.assetCode, computer_name: asset.computerName }),
    raw_data: rawData, normalized_asset_code: asset.assetCode,
    normalized_computer_name: asset.computerName,
    normalized_site_code: databaseSiteCode(asset.siteCode),
    normalized_location_code: asset.location || null, normalized_department_code: null,
    normalized_mac_address: primaryMac, normalized_ip_address: primaryIp, secret_present: false,
  };
}
function toLicensePayload(
  row: ParsedLicenseWorkbook["stagingRows"][number], secret?: SecretEnvelope,
): Record<string, unknown> {
  return {
    source_file_name: row.sourceFile, sheet_name: row.sheetName,
    source_row_number: row.sourceRow,
    source_row_hash: stableHash({ ...row.rawData, secret_fingerprint: row.secretFingerprint }),
    raw_data: { ...row.rawData, used_quantity: row.normalizedUsedQuantity,
      install_date: row.installDate, assigned_name: row.assignedName },
    normalized_publisher: row.normalizedPublisher, normalized_vendor: row.normalizedVendor,
    normalized_product_name: row.normalizedProductName, normalized_version: row.normalizedVersion,
    normalized_classification: row.normalizedClassification,
    normalized_purchase_form: row.normalizedPurchaseForm,
    normalized_owned_quantity: row.normalizedOwnedQuantity,
    normalized_purchase_date: row.purchaseDate, normalized_start_date: row.startDate,
    normalized_end_date: row.endDate, normalized_record_status: row.status,
    serial_present: Boolean(secret), serial_fingerprint: secret?.fingerprint ?? row.secretFingerprint,
    serial_masked_hint: secret?.maskedHint ?? row.secretMaskedHint,
    secret_payload: secret ? { serial_number: secret.value } : {},
  };
}
function databaseSiteCode(siteCode: ParsedAsset["siteCode"]): string {
  return siteCode === "factory" ? "FACTORY" : "BANGKOK_OFFICE";
}
function stableHash(value: unknown): string {
  return createHash("sha256").update(JSON.stringify(value), "utf8").digest("hex");
}
function normalizeMac(value: string): string | null {
  const normalized = value.trim().toUpperCase().replace(/-/g, ":");
  return /^[0-9A-F]{2}(?::[0-9A-F]{2}){5}$/.test(normalized) ? normalized : null;
}
function normalizeIp(value: string): string | null {
  const candidate = value.trim();
  const parts = candidate.split(".");
  if (
    parts.length === 4 &&
    parts.every((part) => /^\d{1,3}$/.test(part) && Number(part) <= 255)
  ) {
    return parts.map((part) => String(Number(part))).join(".");
  }
  return null;
}
async function rpc<T>(
  client: SupabaseClient, name: string, args: Record<string, unknown>,
): Promise<T> {
  const { data, error } = await client.rpc(name as never, args as never);
  if (error) throw new Error(`${name}:${error.code ?? "UNKNOWN"}:${error.message}`);
  return data as T;
}

async function loadLocalEnvironment(): Promise<void> {
  let content: string;
  try {
    content = await readFile(path.resolve(process.cwd(), ".env.local"), "utf8");
  } catch {
    return;
  }
  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!match || process.env[match[1]]) continue;
    process.env[match[1]] = match[2].replace(/^(['"])(.*)\1$/, "$2");
  }
}
async function main(): Promise<void> {
  await loadLocalEnvironment();
  const dryRun = process.argv.includes("--dry-run");
  if (process.argv.includes("--publish")) {
    throw new Error("PUBLISH_REQUIRES_SEPARATE_BATCH_COMMAND");
  }
  const paths = {
    assets: path.resolve(process.cwd(), APPROVED_FILES.assets),
    licenses: path.resolve(process.cwd(), APPROVED_FILES.licenses),
  };
  let gateway: StagingGateway;
  let client: SupabaseClient | null = null;
  if (dryRun) {
    gateway = unavailableGateway();
  } else {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !serviceRoleKey) {
      throw new Error("Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    }
    client = createClient(url, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    gateway = createSupabaseStagingGateway(client);
  }
  const publishBatchId = optionValue("--publish-batch");
  if (publishBatchId) {
    if (dryRun || !client) throw new Error("PUBLISH_REQUIRES_LIVE_CLIENT");
    await publishReviewedBatch(client, publishBatchId);
    return;
  }
  const sourceSelection = explicitSourceSelection(process.argv);
  const staged = await stageApprovedWorkbooks({
    dryRun,
    sourceSelection,
    paths,
    gateway,
  });
  if (!dryRun && client && staged.batchId) {
    const review = await rpc<Record<string, unknown>>(client, "get_import_batch_review", {
      import_batch_id: staged.batchId,
    });
    console.log(JSON.stringify({
      mode: "hosted-review",
      batchId: staged.batchId,
      summary: review.summary,
      reconciliation: review.reconciliation,
      nextCommand: `--publish-batch=${staged.batchId} --expected-version=${String((review.batch as Record<string, unknown>)?.version)} --expected-warning-count=${String((review.summary as Record<string, unknown>)?.warning_count)}`,
    }));
  }
}

async function publishReviewedBatch(client: SupabaseClient, batchId: string): Promise<void> {
  const review = await rpc<Record<string, unknown>>(client, "get_import_batch_review", {
    import_batch_id: batchId,
  });
  const summary = (review.summary ?? {}) as Record<string, unknown>;
  const batch = (review.batch ?? {}) as Record<string, unknown>;
  const errorCount = Number(summary.error_count ?? 0);
  const warningCount = Number(summary.warning_count ?? 0);
  const expectedVersion = Number(optionValue("--expected-version"));
  const expectedWarningCount = Number(optionValue("--expected-warning-count"));
  let version = Number(batch.version);
  if (errorCount > 0 || !Number.isInteger(version)) {
    throw new Error(`IMPORT_NOT_ELIGIBLE:errors=${errorCount}`);
  }
  if (version !== expectedVersion || warningCount !== expectedWarningCount) {
    throw new Error("REVIEW_CHANGED_RESTAGE_OR_REVIEW_REQUIRED");
  }
  if (warningCount > 0) {
    if (!process.argv.includes("--acknowledge-warnings")) {
      throw new Error("WARNING_ACKNOWLEDGEMENT_REQUIRED");
    }
    version = await rpc<number>(client, "acknowledge_import_warnings", {
      import_batch_id: batchId,
      expected_version: version,
    });
  }
  const published = await rpc<Record<string, unknown>>(client, "publish_import_batch", {
    import_batch_id: batchId,
    expected_version: version,
    acknowledge_warnings: warningCount > 0,
  });
  console.log(JSON.stringify({
    mode: "hosted-published",
    batchId,
    published,
  }));
}

function explicitSourceSelection(args: string[]): StageOptions["sourceSelection"] {
  const selected = [
    args.includes("--assets-only") ? "assets-only" : null,
    args.includes("--licenses-only") ? "licenses-only" : null,
    args.includes("--all-sources") ? "all" : null,
  ].filter((value): value is StageOptions["sourceSelection"] => value !== null);
  if (selected.length !== 1) throw new Error("EXPLICIT_SOURCE_MODE_REQUIRED");
  return selected[0];
}

function optionValue(name: string): string | null {
  const prefix = `${name}=`;
  return process.argv.find((argument) => argument.startsWith(prefix))?.slice(prefix.length) ?? null;
}
function unavailableGateway(): StagingGateway {
  const fail = async () => { throw new Error("Dry-run gateway must not be called"); };
  return { beginImportBatch: fail, stageAssetRows: fail, stageLicenseRows: fail,
    validateImportBatch: fail };
}
const executedPath = process.argv[1] ? pathToFileURL(path.resolve(process.argv[1])).href : "";
if (import.meta.url === executedPath) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : "Unknown migration error";
    console.error(JSON.stringify({ status: "error", message }));
    process.exitCode = 1;
  });
}
