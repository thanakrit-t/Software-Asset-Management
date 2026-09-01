import { render, screen } from "@testing-library/react";
import { requireViewer } from "@/features/auth/guards";
import ProtectedLayout from "./(protected)/layout";

vi.mock("next/navigation", () => ({ usePathname: () => "/" }));
vi.mock("@/features/auth/guards", () => ({ requireViewer: vi.fn() }));

test("wraps protected content with the verified viewer shell", async () => {
  vi.mocked(requireViewer).mockResolvedValue({
    id: "admin-1",
    displayName: "Verified Admin",
    email: "admin@example.com",
    role: "admin",
  });

  render(await ProtectedLayout({ children: <h1>Protected content</h1> }));

  expect(screen.getByRole("main")).toContainElement(
    screen.getByRole("heading", { name: "Protected content" }),
  );
  expect(screen.getByText("Verified Admin")).toBeInTheDocument();
});
