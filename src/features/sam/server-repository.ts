import "server-only";
import type { SamRepository } from "./repository";
import { createSupabaseSamRepository } from "./supabase-repository";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export async function getServerSamRepository(): Promise<SamRepository> {
  const client = await createServerSupabaseClient();
  return createSupabaseSamRepository(client);
}

