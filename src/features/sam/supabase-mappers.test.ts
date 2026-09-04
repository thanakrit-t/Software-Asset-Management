import { describe, expect, test } from "vitest";
import {
  mapAllocationRow,
  mapAssetRow,
  mapLicenseRow,
  mapNotificationRow,
  mapProductRow,
} from "./supabase-mappers";

describe("Supabase SAM mappers", () => {
  test("maps an asset inventory row without losing optimistic-lock state", () => {
    expect(mapAssetRow({
      id: "asset-1",
      asset_code: "TKC-001",
      computer_name: "TKC-PC-001",
      asset_type_code: "pc",
      asset_status_code: "active",
      site_id: "site-1",
      site_name: "Factory",
      site_code: "FAC",
      version: 4,
      archived_at: null,
    })).toMatchObject({
      id: "asset-1",
      assetCode: "TKC-001",
      computerName: "TKC-PC-001",
      version: 4,
      archivedAt: undefined,
    });
  });

  test("maps only masked License secret fields", () => {
    const mapped = mapLicenseRow({
      id: "license-1",
      license_reference: "LIC-001",
      product_name: "Microsoft 365",
      publisher_name: "Microsoft",
      version_edition: "Business",
      owned_quantity: 10,
      allocated_quantity: 2,
      available_quantity: 8,
      lifecycle_status: "active",
      compliance_status: "compliant",
      scope_mode: "all_sites",
      license_key_masked: "****-ABCD",
      serial_number_masked: "****-1234",
      version: 3,
      archived_at: null,
    });

    expect(mapped).toMatchObject({
      licenseKeyMasked: "****-ABCD",
      serialNumberMasked: "****-1234",
      version: 3,
    });
    expect(mapped).not.toHaveProperty("licenseKey");
    expect(mapped).not.toHaveProperty("serialNumber");
  });

  test("maps products, allocations, and notification recipient state", () => {
    expect(mapProductRow({
      id: "product-1",
      name: "Office",
      version_edition: "2024",
      support_status: "supported",
      version: 2,
      archived_at: null,
      publishers: { name_en: "Microsoft", name_th: "ไมโครซอฟท์" },
      software_categories: { name_en: "Office", name_th: "สำนักงาน" },
    })).toMatchObject({ id: "product-1", publisher: "Microsoft", category: "Office", active: true, versionNumber: 2 });

    expect(mapAllocationRow({
      id: "allocation-1",
      license_entitlement_id: "license-1",
      target_type: "person",
      person_id: "person-1",
      target_display_name: "Somchai",
      quantity: 1,
      allocated_at: "2026-09-01T00:00:00Z",
    }, { productName: "Office", site: { id: "site-1", name: "Factory", shortName: "FAC" } })).toMatchObject({
      targetType: "person",
      targetName: "Somchai",
      status: "active",
    });

    expect(mapNotificationRow({
      id: "notification-1",
      recipient_id: "recipient-1",
      title: "License expiry",
      message: "Soon",
      severity: "warning",
      notification_type: "license_expiry",
      created_at: "2026-09-01T00:00:00Z",
      is_read: false,
      is_dismissed: false,
    })).toMatchObject({ recipientId: "recipient-1", read: false, dismissed: false, entityType: "license" });
  });
});

