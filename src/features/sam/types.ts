export type Role = "admin" | "user";

export interface Site {
  id: string;
  name: string;
  shortName: string;
}

export type AssetType = "pc" | "notebook" | "server" | "other";
export type AssetStatus = "active" | "spare" | "repair" | "retired";

export interface NetworkInterface {
  id: string;
  type: "lan" | "wifi";
  macAddress?: string;
  ipAddress?: string;
  vlan?: string;
}

export interface Asset {
  id: string;
  assetCode: string;
  computerName: string;
  type: AssetType;
  status: AssetStatus;
  site: Site;
  location: string;
  department: string;
  primaryUser: string;
  responsiblePerson: string;
  manufacturer: string;
  model: string;
  purchaseDate?: string;
  operatingSystem: string;
  internetLevel: string;
  networkInterfaces: NetworkInterface[];
  remark?: string;
  version: number;
  archivedAt?: string;
}

export interface SoftwareProduct {
  id: string;
  publisher: string;
  name: string;
  version: string;
  category: string;
  active: boolean;
  versionNumber: number;
  archivedAt?: string;
}

export type LicenseLifecycleStatus =
  | "draft"
  | "active"
  | "perpetual"
  | "expiring-soon"
  | "expired"
  | "deactivated"
  | "archived";
export type ComplianceStatus = "compliant" | "over-allocated" | "untracked";

export interface LicenseEntitlement {
  id: string;
  reference: string;
  product: SoftwareProduct;
  vendor: string;
  classification: string;
  purchaseForm: string;
  ownedQuantity: number;
  allocatedQuantity: number;
  availableQuantity: number;
  licenseKeyMasked?: string;
  serialNumberMasked?: string;
  purchaseDate?: string;
  startDate?: string;
  endDate?: string;
  lifecycleStatus: LicenseLifecycleStatus;
  complianceStatus: ComplianceStatus;
  siteScope: "All Sites" | "Factory" | "Bangkok Office" | "Selected Sites";
  owner: string;
  remark?: string;
  version: number;
  archivedAt?: string;
}

export interface LicenseAllocation {
  id: string;
  licenseId: string;
  productName: string;
  targetType: "asset" | "person" | "site";
  targetId: string;
  targetName: string;
  site: Site;
  quantity: number;
  allocatedAt: string;
  status: "active" | "removed";
  remark?: string;
  version: number;
}

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  severity: "info" | "warning" | "critical";
  entityType: "asset" | "license";
  entityId: string;
  createdAt: string;
  read: boolean;
  recipientId?: string;
  dismissed: boolean;
}

export interface AuditEvent {
  id: string;
  action: string;
  entityType: string;
  entityId: string;
  description: string;
  actor: string;
  occurredAt: string;
}

export interface UserAccount {
  id: string;
  name: string;
  email: string;
  role: Role;
  status: "active" | "inactive";
  lastLoginAt?: string;
  version: number;
  deactivatedAt?: string;
}


export interface SecretReveal {
  value: string;
  revealedAt: string;
  correlationId: string;
}
