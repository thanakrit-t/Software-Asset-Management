import { render, screen } from "@testing-library/react";
import { DashboardView } from "./dashboard-view";

test("labels dashboard KPIs and urgent items", () => {
  render(<DashboardView assets={[]} licenses={[]} notifications={[]} role="admin" />);
  expect(screen.getByRole("heading", { name: /ภาพรวมสินทรัพย์ซอฟต์แวร์/ })).toBeInTheDocument();
  expect(screen.getByText(/รายการที่ต้องตรวจสอบ/)).toBeInTheDocument();
  expect(screen.getByText("License ที่ครอบครอง")).toBeInTheDocument();
});
