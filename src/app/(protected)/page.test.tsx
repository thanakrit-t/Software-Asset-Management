import { render, screen } from "@testing-library/react";
import { beforeEach, vi } from "vitest";
import { RoleProvider } from "@/components/app-shell/role-provider";
import { mapAssetRow, mapLicenseRow, mapNotificationRow } from "@/features/sam/supabase-mappers";
import type { SamRepository } from "@/features/sam/repository";
import { getServerSamRepository } from "@/features/sam/server-repository";
import Home from "./page";

vi.mock("@/features/sam/server-repository", () => ({
  getServerSamRepository: vi.fn(),
}));

const viewer = {
  id: "user-1",
  displayName: "Regular User",
  email: "user@example.com",
  role: "user" as const,
};

const liveAsset = mapAssetRow({
  id: "asset-live", asset_code: "LIVE-ASSET-001", computer_name: "LIVE-PC",
  asset_type_code: "pc", asset_status_code: "active", site_id: "site-live",
  site_name: "Factory", site_code: "FAC", version: 1, archived_at: null,
});
const liveLicense = mapLicenseRow({
  id: "license-live", license_reference: "LIVE-LIC-001", product_name: "Live Office",
  publisher_name: "Microsoft", version_edition: "2026", owned_quantity: 10,
  allocated_quantity: 1, available_quantity: 9, lifecycle_status: "active",
  compliance_status: "compliant", scope_mode: "all_sites", version: 1, archived_at: null,
});
const liveNotification = mapNotificationRow({
  id: "notification-live", recipient_id: "recipient-live", title: "Live notification",
  message: "Hosted fixture", severity: "info", notification_type: "license_expiry",
  created_at: "2026-09-01T00:00:00Z", is_read: false, is_dismissed: false,
});

beforeEach(() => {
  const repository: SamRepository = {
    listAssets: vi.fn().mockResolvedValue([liveAsset]),
    getAsset: vi.fn(),
    listProducts: vi.fn(),
    listLicenses: vi.fn().mockResolvedValue([liveLicense]),
    getLicense: vi.fn(),
    listAllocations: vi.fn(),
    listNotifications: vi.fn().mockResolvedValue([liveNotification]),
    listAuditEvents: vi.fn(),
    listUsers: vi.fn(),
  };
  vi.mocked(getServerSamRepository).mockResolvedValue(repository);
});

test("renders records returned by the server Supabase repository", async () => {
  render(<RoleProvider viewer={viewer}>{await Home()}</RoleProvider>);
  expect(screen.getByRole("heading", { name: /software asset management/i })).toBeInTheDocument();
  expect(screen.getByText("Live notification")).toBeInTheDocument();
  expect(screen.getByText("Hosted fixture")).toBeInTheDocument();
});

