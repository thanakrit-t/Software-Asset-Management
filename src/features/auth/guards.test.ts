import { redirect } from "next/navigation";
import { loadViewer } from "./viewer";
import { requireAdmin, requireViewer } from "./guards";

vi.mock("next/navigation", () => ({
  redirect: vi.fn(() => {
    throw new Error("NEXT_REDIRECT:/login");
  }),
}));

vi.mock("./viewer", () => ({ loadViewer: vi.fn() }));

test("redirects unauthenticated requests to login", async () => {
  vi.mocked(loadViewer).mockResolvedValue(null);

  await expect(requireViewer()).rejects.toThrow("NEXT_REDIRECT:/login");
  expect(redirect).toHaveBeenCalledWith("/login");
});

test("returns an authenticated viewer", async () => {
  const viewer = {
    id: "user-1",
    displayName: "Report Viewer",
    email: "viewer@example.com",
    role: "user" as const,
  };
  vi.mocked(loadViewer).mockResolvedValue(viewer);

  await expect(requireViewer()).resolves.toEqual(viewer);
});

test("returns null from the admin guard for a regular user", async () => {
  vi.mocked(loadViewer).mockResolvedValue({
    id: "user-1",
    displayName: "Report Viewer",
    email: "viewer@example.com",
    role: "user",
  });

  await expect(requireAdmin()).resolves.toBeNull();
});

test("returns the viewer from the admin guard for an admin", async () => {
  const admin = {
    id: "admin-1",
    displayName: "Admin User",
    email: "admin@example.com",
    role: "admin" as const,
  };
  vi.mocked(loadViewer).mockResolvedValue(admin);

  await expect(requireAdmin()).resolves.toEqual(admin);
});
