import { cache } from "react";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { Viewer } from "./types";

interface ViewerProfileRow {
  id: string;
  display_name: string;
  email: string;
  app_role: string;
  account_status: string;
}

export interface ViewerGateway {
  getClaims(): Promise<{ sub?: string } | null>;
  getProfile(id: string): Promise<ViewerProfileRow | null>;
}

export async function resolveViewer(gateway: ViewerGateway): Promise<Viewer | null> {
  const claims = await gateway.getClaims();
  if (!claims?.sub) return null;

  const profile = await gateway.getProfile(claims.sub);
  if (!profile || profile.account_status !== "active") return null;
  if (profile.app_role !== "admin" && profile.app_role !== "user") return null;

  return {
    id: profile.id,
    displayName: profile.display_name,
    email: profile.email,
    role: profile.app_role,
  };
}

export const loadViewer = cache(async (): Promise<Viewer | null> => {
  const supabase = await createServerSupabaseClient();

  return resolveViewer({
    async getClaims() {
      const { data, error } = await supabase.auth.getClaims();
      if (error) return null;
      return data?.claims?.sub ? { sub: data.claims.sub } : null;
    },
    async getProfile(id) {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, display_name, email, app_role, account_status")
        .eq("id", id)
        .maybeSingle();
      return error ? null : data;
    },
  });
});
