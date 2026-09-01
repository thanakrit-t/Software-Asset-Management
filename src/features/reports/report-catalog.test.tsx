import { render, screen } from "@testing-library/react";
import { ReportCatalog } from "./report-catalog";

test("offers asset license compliance and migration reports", () => {
  render(<ReportCatalog />);
  expect(screen.getByRole("heading", { name: "Asset Inventory Report" })).toBeInTheDocument();
  expect(screen.getByRole("heading", { name: "Owned vs Allocated vs Available" })).toBeInTheDocument();
  expect(screen.getByRole("heading", { name: "Migration Reconciliation Report" })).toBeInTheDocument();
});
