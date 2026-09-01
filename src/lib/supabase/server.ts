import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "./database.types";
import { readPublicSupabaseEnv } from "./env";

export async function createServerSupabaseClient() {
  const { url, publishableKey } = readPublicSupabaseEnv(process.env);
  const cookieStore = await cookies();

  return createServerClient<Database>(url, publishableKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // Server Components cannot write cookies. src/proxy.ts refreshes them.
        }
      },
    },
  });
}
