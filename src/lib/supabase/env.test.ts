import { readPublicSupabaseEnv } from "./env";

test("returns validated public Supabase configuration", () => {
  expect(
    readPublicSupabaseEnv({
      NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
    }),
  ).toEqual({
    url: "https://example.supabase.co",
    publishableKey: "sb_publishable_example",
  });
});

test("reports missing variable names without exposing configured values", () => {
  const configuredUrl = "https://do-not-print.supabase.co";

  expect(() =>
    readPublicSupabaseEnv({
      NEXT_PUBLIC_SUPABASE_URL: configuredUrl,
    }),
  ).toThrow("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY");

  try {
    readPublicSupabaseEnv({ NEXT_PUBLIC_SUPABASE_URL: configuredUrl });
    throw new Error("Expected environment validation to fail");
  } catch (error) {
    expect(error).toBeInstanceOf(Error);
    expect((error as Error).message).not.toContain(configuredUrl);
  }
});
