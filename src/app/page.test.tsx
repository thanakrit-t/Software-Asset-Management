import { render, screen } from "@testing-library/react";
import Home from "./page";
import { RoleProvider } from "@/components/app-shell/role-provider";

test("introduces the software asset management workspace", async () => {
  render(<RoleProvider>{await Home()}</RoleProvider>);
  expect(
    screen.getByRole("heading", { name: /software asset management/i }),
  ).toBeInTheDocument();
});

