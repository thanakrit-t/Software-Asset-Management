"use client";

import { useRole } from "@/components/app-shell/role-provider";
import type { Asset, LicenseEntitlement, NotificationItem } from "@/features/sam/types";
import { DashboardView } from "./dashboard-view";

export function DashboardScreen({
  assets,
  licenses,
  notifications,
}: {
  assets: Asset[];
  licenses: LicenseEntitlement[];
  notifications: NotificationItem[];
}) {
  const { role } = useRole();
  return <DashboardView assets={assets} licenses={licenses} notifications={notifications} role={role} />;
}
