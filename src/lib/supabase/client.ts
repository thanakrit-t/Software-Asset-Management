import { createBrowserClient } from "@supabase/ssr";
import type { Database } from "./database.types";
import { readPublicSupabaseEnv } from "./env";

export function createBrowserSupabaseClient() {
  const { url, publishableKey } = readPublicSupabaseEnv(process.env);
  return createBrowserClient<Database>(url, publishableKey);
}
