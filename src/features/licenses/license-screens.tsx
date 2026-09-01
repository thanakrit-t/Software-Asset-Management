"use client";
import type { LicenseAllocation, LicenseEntitlement } from "@/features/sam/types";
import { useRole } from "@/components/app-shell/role-provider";
import { LicenseList } from "./license-list";
import { LicenseDetail } from "./license-detail";
export function LicenseListScreen({ licenses }: { licenses: LicenseEntitlement[] }) { const { role } = useRole(); return <LicenseList licenses={licenses} role={role} />; }
export function LicenseDetailScreen({ license, allocations }: { license: LicenseEntitlement; allocations: LicenseAllocation[] }) { const { role } = useRole(); return <LicenseDetail license={license} allocations={allocations} role={role} />; }
