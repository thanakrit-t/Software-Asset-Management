import {
  allocations,
  assets,
  auditEvents,
  licenses,
  notifications,
  products,
  userAccounts,
} from "./mock-data";
import type { AssetFilters, LicenseFilters, SamRepository } from "./repository";

function normalize(value: string): string {
  return value.trim().toLocaleLowerCase("en-US");
}

function matchesAssetQuery(asset: (typeof assets)[number], query: string): boolean {
  const needle = normalize(query);
  const searchable = [
    asset.assetCode,
    asset.computerName,
    asset.primaryUser,
    asset.responsiblePerson,
    asset.operatingSystem,
    ...asset.networkInterfaces.flatMap((network) => [network.macAddress ?? "", network.ipAddress ?? ""]),
  ];
  return searchable.some((value) => normalize(value).includes(needle));
}

function filterAssets(filters: AssetFilters = {}) {
  return assets.filter((asset) => {
    if (filters.siteId && filters.siteId !== "all" && asset.site.id !== filters.siteId) return false;
    if (filters.type && filters.type !== "all" && asset.type !== filters.type) return false;
    if (filters.status && filters.status !== "all" && asset.status !== filters.status) return false;
    if (filters.query && !matchesAssetQuery(asset, filters.query)) return false;
    return true;
  });
}

function filterLicenses(filters: LicenseFilters = {}) {
  return licenses.filter((license) => {
    if (filters.site && filters.site !== "all" && license.siteScope !== filters.site) return false;
    if (
      filters.lifecycleStatus &&
      filters.lifecycleStatus !== "all" &&
      license.lifecycleStatus !== filters.lifecycleStatus
    ) return false;
    if (filters.query) {
      const needle = normalize(filters.query);
      const searchable = [license.reference, license.product.publisher, license.product.name, license.product.version];
      if (!searchable.some((value) => normalize(value).includes(needle))) return false;
    }
    return true;
  });
}

export const mockSamRepository: SamRepository = {
  async listAssets(filters = {}) {
    return filterAssets(filters);
  },
  async getAsset(id) {
    return assets.find((asset) => asset.id === id);
  },
  async listProducts() {
    return products;
  },
  async listLicenses(filters = {}) {
    return filterLicenses(filters);
  },
  async getLicense(id) {
    return licenses.find((license) => license.id === id);
  },
  async listAllocations() {
    return allocations;
  },
  async listNotifications() {
    return notifications;
  },
  async listAuditEvents() {
    return auditEvents;
  },
  async listUsers() {
    return userAccounts;
  },
};
