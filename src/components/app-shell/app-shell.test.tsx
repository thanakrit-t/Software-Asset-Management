import { render, screen } from "@testing-library/react";
import { RoleProvider } from "./role-provider";
import { AppShell } from "./app-shell";

vi.mock("next/navigation", () => ({ usePathname: () => "/" }));

test("exposes navigation and main content landmarks", () => {
  render(
    <RoleProvider>
      <AppShell><h1>Dashboard</h1></AppShell>
    </RoleProvider>,
  );
  expect(screen.getByRole("navigation", { name: /เมนูหลัก/ })).toBeInTheDocument();
  expect(screen.getByRole("main")).toContainElement(screen.getByRole("heading", { name: "Dashboard" }));
});
