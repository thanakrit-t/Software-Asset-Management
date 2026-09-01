import { render, screen } from "@testing-library/react";
import { requireAdmin } from "@/features/auth/guards";
import AdminLayout from "./(protected)/(admin)/layout";

vi.mock("@/features/auth/guards", () => ({ requireAdmin: vi.fn() }));

test("does not render admin children for a regular user", async () => {
  vi.mocked(requireAdmin).mockResolvedValue(null);
  render(await AdminLayout({ children: <h1>Secret admin content</h1> }));
  expect(screen.getByRole("heading", { name: "ไม่มีสิทธิ์เข้าถึง" })).toBeInTheDocument();
  expect(screen.queryByText("Secret admin content")).not.toBeInTheDocument();
});

test("renders admin children for a verified admin", async () => {
  vi.mocked(requireAdmin).mockResolvedValue({
    id: "admin-1",
    displayName: "Admin",
    email: "admin@example.com",
    role: "admin",
  });
  render(await AdminLayout({ children: <h1>Admin content</h1> }));
  expect(screen.getByRole("heading", { name: "Admin content" })).toBeInTheDocument();
});
