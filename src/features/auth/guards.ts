import { redirect } from "next/navigation";
import type { Viewer } from "./types";
import { loadViewer } from "./viewer";

export async function requireViewer(): Promise<Viewer> {
  const viewer = await loadViewer();
  if (!viewer) redirect("/login");
  return viewer;
}

export async function requireAdmin(): Promise<Viewer | null> {
  const viewer = await requireViewer();
  return viewer.role === "admin" ? viewer : null;
}
