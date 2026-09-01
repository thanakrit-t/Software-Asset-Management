import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { licenses } from "@/features/sam/mock-data";
import { LicenseList } from "./license-list";

test("filters licenses by product name", async () => {
  const user = userEvent.setup();
  render(<LicenseList licenses={licenses} role="user" />);
  await user.type(screen.getByRole("searchbox", { name: /ค้นหา License/ }), "Office 365");
  expect(screen.getByText("Office 365 Family")).toBeInTheDocument();
  expect(screen.queryByText("AutoCAD")).not.toBeInTheDocument();
});

test("shows license management actions only to administrators", () => {
  const { rerender } = render(<LicenseList licenses={licenses} role="user" />);
  expect(screen.queryByRole("button", { name: /เพิ่ม License/ })).not.toBeInTheDocument();
  rerender(<LicenseList licenses={licenses} role="admin" />);
  expect(screen.getByRole("button", { name: /เพิ่ม License/ })).toBeInTheDocument();
});

test("shows owned allocated and available quantities", () => {
  render(<LicenseList licenses={[licenses[0]]} role="user" />);
  expect(screen.getByRole("columnheader", { name: "Owned" })).toBeInTheDocument();
  expect(screen.getByRole("columnheader", { name: "Allocated" })).toBeInTheDocument();
  expect(screen.getByRole("columnheader", { name: "Available" })).toBeInTheDocument();
});
