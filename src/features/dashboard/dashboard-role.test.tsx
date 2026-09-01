import { render, screen } from "@testing-library/react";
import { DashboardView } from "./dashboard-view";

test("hides the asset mutation action from regular users", () => {
  const { rerender } = render(
    <DashboardView assets={[]} licenses={[]} notifications={[]} role="user" />,
  );
  expect(screen.queryByRole("link", { name: /เพิ่ม Asset/ })).not.toBeInTheDocument();

  rerender(<DashboardView assets={[]} licenses={[]} notifications={[]} role="admin" />);
  expect(screen.getByRole("link", { name: /เพิ่ม Asset/ })).toBeInTheDocument();
});
