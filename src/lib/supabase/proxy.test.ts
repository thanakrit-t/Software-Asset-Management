// @vitest-environment node

import { createServerClient } from "@supabase/ssr";
import { NextRequest } from "next/server";
import { updateSupabaseSession } from "./proxy";

vi.mock("@supabase/ssr", () => ({ createServerClient: vi.fn() }));

beforeEach(() => {
  vi.clearAllMocks();
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://example.supabase.co");
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY", "sb_publishable_example");
});

afterEach(() => vi.unstubAllEnvs());

test("redirects an unauthenticated protected request and preserves refreshed cookies", async () => {
  vi.mocked(createServerClient).mockImplementation((_url, _key, options) => ({
    auth: {
      getClaims: async () => {
        options.cookies.setAll?.(
          [{ name: "refreshed", value: "cookie-value", options: { path: "/" } }],
          { "Cache-Control": "private, no-store" },
        );
        return { data: { claims: null }, error: null };
      },
    },
  }) as never);

  const response = await updateSupabaseSession(
    new NextRequest("https://sam.example/assets?site=factory"),
  );

  expect(response.status).toBe(307);
  expect(response.headers.get("location")).toBe(
    "https://sam.example/login?next=%2Fassets%3Fsite%3Dfactory",
  );
  expect(response.cookies.get("refreshed")?.value).toBe("cookie-value");
});

test("keeps the login page public without a session", async () => {
  vi.mocked(createServerClient).mockReturnValue({
    auth: { getClaims: async () => ({ data: { claims: null }, error: null }) },
  } as never);

  const response = await updateSupabaseSession(
    new NextRequest("https://sam.example/login"),
  );

  expect(response.status).toBe(200);
  expect(response.headers.get("location")).toBeNull();
});

test("allows protected requests with verified claims", async () => {
  vi.mocked(createServerClient).mockReturnValue({
    auth: {
      getClaims: async () => ({
        data: { claims: { sub: "user-id", role: "authenticated" } },
        error: null,
      }),
    },
  } as never);

  const response = await updateSupabaseSession(
    new NextRequest("https://sam.example/reports"),
  );

  expect(response.status).toBe(200);
  expect(response.headers.get("location")).toBeNull();
});
