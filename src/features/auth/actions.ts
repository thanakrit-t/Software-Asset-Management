"use server";

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { AuthActionState } from "./types";

export const initialAuthActionState: AuthActionState = {};
const invalidLoginMessage = "อีเมลหรือรหัสผ่านไม่ถูกต้อง กรุณาลองอีกครั้ง";
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function login(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const email = String(formData.get("email") ?? "").trim().toLowerCase();
  const password = String(formData.get("password") ?? "");
  const fieldErrors: NonNullable<AuthActionState["fieldErrors"]> = {};

  if (!emailPattern.test(email)) {
    fieldErrors.email = "กรุณากรอกอีเมลให้ถูกต้อง";
  }
  if (!password) {
    fieldErrors.password = "กรุณากรอกรหัสผ่าน";
  }
  if (Object.keys(fieldErrors).length > 0) return { fieldErrors };

  const supabase = await createServerSupabaseClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: invalidLoginMessage };

  redirect("/");
}

export async function logout(): Promise<never> {
  const supabase = await createServerSupabaseClient();
  await supabase.auth.signOut();
  redirect("/login");
}
