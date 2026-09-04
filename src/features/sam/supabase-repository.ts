import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/supabase/database.types";
import type { AssetFilters, LicenseFilters, SamRepository } from "./repository";
import {
  mapAllocationRow, mapAssetRow, mapAuditRow, mapLicenseRow, mapNotificationRow,
  mapProductRow, mapUserRow, type ActiveAllocationRow, type AssetInventoryRow,
  type AuditLogRow, type LicenseSafeRow, type NotificationFeedRow,
  type ProductReadRow, type UserProfileRow,
} from "./supabase-mappers";

export class SamRepositoryError extends Error {
  constructor(readonly code: string, readonly cause: unknown) {
    super(code, { cause });
    this.name = "SamRepositoryError";
  }
}

function failed(code: string, error: unknown): never {
  throw new SamRepositoryError(code, error);
}

export function createSupabaseSamRepository(client: SupabaseClient<Database>): SamRepository {
  return {
    async listAssets(filters: AssetFilters = {}) {
      let query = client.from("asset_inventory_v").select("*").is("archived_at", null);
      if (filters.siteId && filters.siteId !== "all") query = query.eq("site_id", filters.siteId);
      if (filters.type && filters.type !== "all") query = query.eq("asset_type_code", filters.type);
      if (filters.status && filters.status !== "all") query = query.eq("asset_status_code", filters.status);
      const { data, error } = await query.order("asset_code");
      if (error) failed("ASSET_READ_FAILED", error);
      return (data ?? []).map((row) => mapAssetRow(row as AssetInventoryRow));
    },

    async getAsset(id) {
      const { data, error } = await client.from("asset_inventory_v").select("*").eq("id", id).maybeSingle();
      if (error) failed("ASSET_READ_FAILED", error);
      return data ? mapAssetRow(data as AssetInventoryRow) : undefined;
    },

    async listProducts() {
      const { data, error } = await client
        .from("software_products")
        .select("id,name,version_edition,support_status,version,archived_at,publishers(name_en,name_th),software_categories(name_en,name_th)")
        .is("archived_at", null)
        .order("name");
      if (error) failed("PRODUCT_READ_FAILED", error);
      return (data ?? []).map((row) => mapProductRow(row as ProductReadRow));
    },

    async listLicenses(filters: LicenseFilters = {}) {
      let query = client.from("license_safe_v").select("*").is("archived_at", null);
      if (filters.lifecycleStatus && filters.lifecycleStatus !== "all") {
        query = query.eq("lifecycle_status", filters.lifecycleStatus.replaceAll("-", "_"));
      }
      const { data, error } = await query.order("license_reference");
      if (error) failed("LICENSE_READ_FAILED", error);
      let result = (data ?? []).map((row) => mapLicenseRow(row as LicenseSafeRow));
      if (filters.site && filters.site !== "all") result = result.filter((item) => item.siteScope === filters.site);
      if (filters.query) {
        const needle = filters.query.trim().toLocaleLowerCase("en-US");
        result = result.filter((item) => [item.reference, item.product.name, item.product.publisher, item.product.version]
          .some((value) => value.toLocaleLowerCase("en-US").includes(needle)));
      }
      return result;
    },

    async getLicense(id) {
      const { data, error } = await client.from("license_safe_v").select("*").eq("id", id).maybeSingle();
      if (error) failed("LICENSE_READ_FAILED", error);
      return data ? mapLicenseRow(data as LicenseSafeRow) : undefined;
    },

    async listAllocations() {
      const { data, error } = await client.from("active_allocations_v").select("*").order("allocated_at", { ascending: false });
      if (error) failed("ALLOCATION_READ_FAILED", error);
      return (data ?? []).map((row) => mapAllocationRow(row as ActiveAllocationRow));
    },

    async listNotifications() {
      const { data, error } = await client.from("notification_feed_v").select("*").eq("is_dismissed", false).order("created_at", { ascending: false });
      if (error) failed("NOTIFICATION_READ_FAILED", error);
      return (data ?? []).map((row) => mapNotificationRow(row as NotificationFeedRow));
    },

    async listAuditEvents() {
      const { data, error } = await client.from("audit_log_admin_v").select("*").order("occurred_at", { ascending: false });
      if (error) failed("AUDIT_READ_FAILED", error);
      return (data ?? []).map((row) => mapAuditRow(row as AuditLogRow));
    },

    async listUsers() {
      const { data, error } = await client.from("profiles").select("*").order("display_name");
      if (error) failed("USER_READ_FAILED", error);
      return (data ?? []).map((row) => mapUserRow(row as UserProfileRow));
    },
  };
}

