import { render, screen } from "@testing-library/react";
import Home from "./page";
import { RoleProvider } from "@/components/app-shell/role-provider";

const viewer = {
  id: "user-1",
  displayName: "Regular User",
  email: "user@example.com",
  role: "user" as const,
};

test("introduces the software asset management workspace", async () => {
  render(<RoleProvider viewer={viewer}>{await Home()}</RoleProvider>);
  expect(
    screen.getByRole("heading", { name: /software asset management/i }),
  ).toBeInTheDocument();
});