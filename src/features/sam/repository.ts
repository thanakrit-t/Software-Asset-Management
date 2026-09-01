import type {
  Asset,
  AssetStatus,
  AssetType,
  AuditEvent,
  LicenseAllocation,
  LicenseEntitlement,
  LicenseLifecycleStatus,
  NotificationItem,
  Site,
  SoftwareProduct,
  UserAccount,
} from "./types";

export interface AssetFilters {
  query?: string;
  siteId?: Site["id"] | "all";
  type?: AssetType | "all";
  status?: AssetStatus | "all";
}

export interface LicenseFilters {
  query?: string;
  site?: LicenseEntitlement["siteScope"] | "all";
  lifecycleStatus?: LicenseLifecycleStatus | "all";
}

export interface SamRepository {
  listAssets(filters?: AssetFilters): Promise<Asset[]>;
  getAsset(id: string): Promise<Asset | undefined>;
  listProducts(): Promise<SoftwareProduct[]>;
  listLicenses(filters?: LicenseFilters): Promise<LicenseEntitlement[]>;
  getLicense(id: string): Promise<LicenseEntitlement | undefined>;
  listAllocations(): Promise<LicenseAllocation[]>;
  listNotifications(): Promise<NotificationItem[]>;
  listAuditEvents(): Promise<AuditEvent[]>;
  listUsers(): Promise<UserAccount[]>;
}
