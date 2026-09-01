"use client";
import type { AuditEvent, UserAccount } from "@/features/sam/types";
import { useRole } from "@/components/app-shell/role-provider";
import { MasterDataView } from "./master-data-view";
import { UserManagementView } from "./user-management-view";
import { AuditLogView } from "./audit-log-view";
import { SettingsView } from "./settings-view";
export function AdminScreen({ variant, users = [], events = [] }: { variant: "master" | "users" | "audit" | "settings"; users?: UserAccount[]; events?: AuditEvent[] }) { const { role } = useRole(); if (variant === "master") return <MasterDataView role={role} />; if (variant === "users") return <UserManagementView role={role} users={users} />; if (variant === "audit") return <AuditLogView role={role} events={events} />; return <SettingsView role={role} />; }
