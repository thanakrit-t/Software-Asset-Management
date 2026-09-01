import { createBrowserClient, createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { createBrowserSupabaseClient } from "./client";
import { createServerSupabaseClient } from "./server";

vi.mock("@supabase/ssr", () => ({
  createBrowserClient: vi.fn(),
  createServerClient: vi.fn(),
}));

vi.mock("next/headers", () => ({ cookies: vi.fn() }));

const publicEnvironment = {
  NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
};

beforeEach(() => {
  vi.clearAllMocks();
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", publicEnvironment.NEXT_PUBLIC_SUPABASE_URL);
  vi.stubEnv(
    "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
    publicEnvironment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  );
});

afterEach(() => vi.unstubAllEnvs());

test("creates a browser client from validated public configuration", () => {
  const expectedClient = { channel: "browser" };
  vi.mocked(createBrowserClient).mockReturnValue(expectedClient as never);

  expect(createBrowserSupabaseClient()).toBe(expectedClient);
  expect(createBrowserClient).toHaveBeenCalledWith(
    publicEnvironment.NEXT_PUBLIC_SUPABASE_URL,
    publicEnvironment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  );
});

test("creates a request-scoped server client with cookie forwarding", async () => {
  const getAll = vi.fn().mockReturnValue([{ name: "session", value: "cookie" }]);
  const set = vi.fn();
  vi.mocked(cookies).mockResolvedValue({ getAll, set } as never);
  vi.mocked(createServerClient).mockReturnValue({ channel: "server" } as never);

  await createServerSupabaseClient();

  const options = vi.mocked(createServerClient).mock.calls[0][2];
  expect(options.cookies.getAll()).toEqual([{ name: "session", value: "cookie" }]);
  options.cookies.setAll?.(
    [{ name: "refreshed", value: "value", options: { path: "/" } }],
    {},
  );
  expect(set).toHaveBeenCalledWith("refreshed", "value", { path: "/" });
});
