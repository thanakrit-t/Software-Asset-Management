import type { Database } from "@/lib/supabase/database.types";
import type {
  Asset, AssetStatus, AssetType, AuditEvent, ComplianceStatus, LicenseAllocation,
  LicenseEntitlement, LicenseLifecycleStatus, NetworkInterface, NotificationItem,
  Site, SoftwareProduct, UserAccount,
} from "./types";

type AssetViewRow = Database["public"]["Views"]["asset_inventory_v"]["Row"];
type LicenseViewRow = Database["public"]["Views"]["license_safe_v"]["Row"];
type AllocationViewRow = Database["public"]["Views"]["active_allocations_v"]["Row"];
type NotificationViewRow = Database["public"]["Views"]["notification_feed_v"]["Row"];
type AuditViewRow = Database["public"]["Views"]["audit_log_admin_v"]["Row"];
type ProfileRow = Database["public"]["Tables"]["profiles"]["Row"];

export type AssetInventoryRow = Partial<AssetViewRow> & Pick<AssetViewRow, "id">;
export type LicenseSafeRow = Partial<LicenseViewRow> & Pick<LicenseViewRow, "id">;
export type ActiveAllocationRow = Partial<AllocationViewRow> & Pick<AllocationViewRow, "id">;
export type NotificationFeedRow = Partial<NotificationViewRow> & Pick<NotificationViewRow, "id">;
export type AuditLogRow = Partial<AuditViewRow> & Pick<AuditViewRow, "id">;
export type UserProfileRow = Partial<ProfileRow> & Pick<ProfileRow, "id">;

export interface ProductReadRow {
  id: string;
  name?: string | null;
  version_edition?: string | null;
  support_status?: string | null;
  version?: number | null;
  archived_at?: string | null;
  publishers?: { name_en?: string | null; name_th?: string | null } | null;
  software_categories?: { name_en?: string | null; name_th?: string | null } | null;
}

const text = (value: string | null | undefined, fallback = "—") => value?.trim() || fallback;
const firstName = (value: { name_en?: string | null; name_th?: string | null } | null | undefined) =>
  text(value?.name_en ?? value?.name_th);

function assetType(value: string | null | undefined): AssetType {
  return value === "pc" || value === "notebook" || value === "server" ? value : "other";
}

function assetStatus(value: string | null | undefined): AssetStatus {
  return value === "active" || value === "spare" || value === "repair" || value === "retired" ? value : "active";
}

export function mapAssetRow(row: AssetInventoryRow, networkInterfaces: NetworkInterface[] = []): Asset {
  const osName = text(row.operating_system_name, "Unknown OS");
  const osVersion = row.operating_system_version?.trim();
  return {
    id: text(row.id, "unknown-asset"),
    assetCode: text(row.asset_code, text(row.computer_name, "Unassigned")),
    computerName: text(row.computer_name, text(row.asset_code, "Unassigned")),
    type: assetType(row.asset_type_code),
    status: assetStatus(row.asset_status_code),
    site: {
      id: text(row.site_id, "unknown-site"),
      name: text(row.site_name, "Unknown Site"),
      shortName: text(row.site_code, text(row.site_name, "Unknown")),
    },
    location: text(row.location_name),
    department: text(row.department_name),
    primaryUser: text(row.primary_user_name),
    responsiblePerson: text(row.responsible_person_name),
    manufacturer: text(row.manufacturer),
    model: text(row.model),
    purchaseDate: row.purchase_date ?? undefined,
    operatingSystem: osVersion ? osName + " " + osVersion : osName,
    internetLevel: text(row.risk_access_level),
    networkInterfaces,
    remark: row.remark ?? undefined,
    version: row.version ?? 1,
    archivedAt: row.archived_at ?? undefined,
  };
}

export function mapProductRow(row: ProductReadRow): SoftwareProduct {
  return {
    id: row.id,
    publisher: firstName(row.publishers),
    name: text(row.name, "Unnamed Product"),
    version: text(row.version_edition),
    category: firstName(row.software_categories),
    active: row.archived_at == null && row.support_status !== "eol",
    versionNumber: row.version ?? 1,
    archivedAt: row.archived_at ?? undefined,
  };
}

function lifecycle(value: string | null | undefined): LicenseLifecycleStatus {
  const normalized = value?.replaceAll("_", "-");
  return normalized === "draft" || normalized === "active" || normalized === "perpetual" ||
    normalized === "expiring-soon" || normalized === "expired" || normalized === "deactivated" ||
    normalized === "archived" ? normalized : "active";
}

function compliance(value: string | null | undefined): ComplianceStatus {
  const normalized = value?.replaceAll("_", "-");
  return normalized === "over-allocated" || normalized === "untracked" ? normalized : "compliant";
}

export function mapLicenseRow(row: LicenseSafeRow): LicenseEntitlement {
  return {
    id: text(row.id, "unknown-license"),
    reference: text(row.license_reference, "Unassigned"),
    product: {
      id: text(row.software_product_id, "unknown-product"),
      publisher: text(row.publisher_name),
      name: text(row.product_name, "Unnamed Product"),
      version: text(row.version_edition),
      category: "—",
      active: true,
      versionNumber: 1,
    },
    vendor: row.vendor_id ? "Vendor " + row.vendor_id : "—",
    classification: "—",
    purchaseForm: "—",
    ownedQuantity: row.owned_quantity ?? 0,
    allocatedQuantity: row.allocated_quantity ?? 0,
    availableQuantity: row.available_quantity ?? 0,
    licenseKeyMasked: row.license_key_masked ?? undefined,
    serialNumberMasked: row.serial_number_masked ?? undefined,
    purchaseDate: row.purchase_date ?? undefined,
    startDate: row.start_date ?? undefined,
    endDate: row.end_date ?? undefined,
    lifecycleStatus: lifecycle(row.lifecycle_status),
    complianceStatus: compliance(row.compliance_status),
    siteScope: row.scope_mode === "all_sites" ? "All Sites" : "Selected Sites",
    owner: "Thai Kurabo",
    remark: row.remark ?? undefined,
    version: row.version ?? 1,
    archivedAt: row.archived_at ?? undefined,
  };
}

export function mapAllocationRow(
  row: ActiveAllocationRow,
  context: { productName?: string; site?: Site; version?: number } = {},
): LicenseAllocation {
  const targetId = row.asset_id ?? row.person_id ?? row.site_id ?? text(row.id, "unknown-target");
  return {
    id: text(row.id, "unknown-allocation"),
    licenseId: text(row.license_entitlement_id, "unknown-license"),
    productName: context.productName ?? "Unknown Product",
    targetType: row.target_type ?? "asset",
    targetId,
    targetName: text(row.target_display_name, "Unknown Target"),
    site: context.site ?? { id: row.site_id ?? "unknown-site", name: "Unknown Site", shortName: "Unknown" },
    quantity: row.quantity ?? 0,
    allocatedAt: row.allocated_at ?? "",
    status: "active",
    remark: row.remark ?? undefined,
    version: context.version ?? 1,
  };
}

export function mapNotificationRow(row: NotificationFeedRow): NotificationItem {
  const kind = row.notification_type?.toLocaleLowerCase("en-US") ?? "";
  return {
    id: text(row.id, "unknown-notification"),
    title: text(row.title, "Notification"),
    message: text(row.message, ""),
    severity: row.severity === "critical" || row.severity === "warning" ? row.severity : "info",
    entityType: kind.includes("asset") ? "asset" : "license",
    entityId: text(row.id, "unknown-notification"),
    createdAt: row.created_at ?? "",
    read: row.is_read ?? row.read_at != null,
    recipientId: row.recipient_id ?? undefined,
    dismissed: row.is_dismissed ?? row.dismissed_at != null,
  };
}

export function mapAuditRow(row: AuditLogRow): AuditEvent {
  return {
    id: text(row.id, "unknown-audit"),
    action: text(row.action, "unknown"),
    entityType: text(row.entity_type, "Unknown"),
    entityId: text(row.entity_id, "unknown"),
    description: text(row.description, ""),
    actor: row.actor_profile_id ? "User " + row.actor_profile_id : text(row.actor_type, "System"),
    occurredAt: row.occurred_at ?? "",
  };
}

export function mapUserRow(row: UserProfileRow): UserAccount {
  return {
    id: row.id,
    name: text(row.display_name, "Unknown User"),
    email: text(row.email, ""),
    role: row.app_role ?? "user",
    status: row.account_status === "inactive" ? "inactive" : "active",
    lastLoginAt: row.last_login_at ?? undefined,
    version: row.version ?? 1,
    deactivatedAt: row.deactivated_at ?? undefined,
  };
}

