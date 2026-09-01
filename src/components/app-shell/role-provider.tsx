"use client";

import { createContext, useContext, useMemo, useSyncExternalStore } from "react";
import type { Role } from "@/features/sam/types";

interface RoleContextValue { role: Role; setRole: (role: Role) => void }
const RoleContext = createContext<RoleContextValue | null>(null);
const STORAGE_KEY = "sam-preview-role";
const CHANGE_EVENT = "sam-preview-role-change";

function subscribe(callback: () => void) {
  window.addEventListener(CHANGE_EVENT, callback);
  window.addEventListener("storage", callback);
  return () => { window.removeEventListener(CHANGE_EVENT, callback); window.removeEventListener("storage", callback); };
}

function getSnapshot(): Role {
  const savedRole = window.sessionStorage.getItem(STORAGE_KEY);
  return savedRole === "user" ? "user" : "admin";
}

export function RoleProvider({ children }: { children: React.ReactNode }) {
  const role = useSyncExternalStore(subscribe, getSnapshot, (): Role => "admin");
  const value = useMemo<RoleContextValue>(() => ({ role, setRole(nextRole) { window.sessionStorage.setItem(STORAGE_KEY, nextRole); window.dispatchEvent(new Event(CHANGE_EVENT)); } }), [role]);
  return <RoleContext.Provider value={value}>{children}</RoleContext.Provider>;
}

export function useRole(): RoleContextValue {
  const context = useContext(RoleContext);
  if (!context) throw new Error("useRole must be used within RoleProvider");
  return context;
}

