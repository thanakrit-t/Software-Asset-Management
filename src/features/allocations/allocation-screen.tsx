"use client";
import type { LicenseAllocation, LicenseEntitlement } from "@/features/sam/types";
import { useRole } from "@/components/app-shell/role-provider";
import { AllocationList } from "./allocation-list";
export function AllocationScreen({ allocations, licenses }: { allocations: LicenseAllocation[]; licenses: LicenseEntitlement[] }) { const { role } = useRole(); return <AllocationList allocations={allocations} licenses={licenses} role={role} />; }
