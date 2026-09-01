import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import * as serverActions from "./actions";
import { initialAuthActionState } from "./types";

const { login, logout } = serverActions;

vi.mock("next/navigation", () => ({
  redirect: vi.fn((path: string) => {
    throw new Error(`NEXT_REDIRECT:${path}`);
  }),
}));

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabaseClient: vi.fn(),
}));

function credentials(email: string, password: string) {
  const formData = new FormData();
  formData.set("email", email);
  formData.set("password", password);
  return formData;
}

test("exports only functions from the server action module", () => {
  expect(Object.values(serverActions).every((value) => typeof value === "function")).toBe(true);
});

test("rejects invalid credentials before contacting Supabase", async () => {
  const result = await login(initialAuthActionState, credentials("invalid", ""));

  expect(result.fieldErrors).toEqual({
    email: "กรุณากรอกอีเมลให้ถูกต้อง",
    password: "กรุณากรอกรหัสผ่าน",
  });
  expect(createServerSupabaseClient).not.toHaveBeenCalled();
});

test("returns one generic message for provider login failures", async () => {
  const signInWithPassword = vi.fn().mockResolvedValue({
    data: { user: null, session: null },
    error: new Error("User not found"),
  });
  vi.mocked(createServerSupabaseClient).mockResolvedValue({
    auth: { signInWithPassword },
  } as never);

  await expect(
    login(initialAuthActionState, credentials("user@example.com", "incorrect")),
  ).resolves.toEqual({
    error: "อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองอีกครั้ง",
  });
});

test("redirects a successful login to the dashboard", async () => {
  vi.mocked(createServerSupabaseClient).mockResolvedValue({
    auth: {
      signInWithPassword: vi.fn().mockResolvedValue({
        data: { user: { id: "user-1" }, session: {} },
        error: null,
      }),
    },
  } as never);

  await expect(
    login(initialAuthActionState, credentials(" USER@example.com ", "password")),
  ).rejects.toThrow("NEXT_REDIRECT:/");
  expect(redirect).toHaveBeenCalledWith("/");
});

test("signs out and redirects to login", async () => {
  const signOut = vi.fn().mockResolvedValue({ error: null });
  vi.mocked(createServerSupabaseClient).mockResolvedValue({
    auth: { signOut },
  } as never);

  await expect(logout()).rejects.toThrow("NEXT_REDIRECT:/login");
  expect(signOut).toHaveBeenCalledOnce();
  expect(redirect).toHaveBeenCalledWith("/login");
});
