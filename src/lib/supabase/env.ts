export interface PublicSupabaseEnv {
  url: string;
  publishableKey: string;
}

export function readPublicSupabaseEnv(
  source: NodeJS.ProcessEnv,
): PublicSupabaseEnv {
  const url = source.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const publishableKey = source.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();
  const missing = [
    !url && "NEXT_PUBLIC_SUPABASE_URL",
    !publishableKey && "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
  ].filter((name): name is string => Boolean(name));

  if (missing.length > 0) {
    throw new Error(`Missing Supabase environment variable: ${missing.join(", ")}`);
  }

  return { url, publishableKey };
}
