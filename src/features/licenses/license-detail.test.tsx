import { render, screen } from "@testing-library/react";
import { allocations, licenses } from "@/features/sam/mock-data";
import { LicenseDetail } from "./license-detail";

test("shows entitlement quantities and related allocations", () => {
  const license = licenses.find((item) => item.id === "lic-office-365")!;
  render(<LicenseDetail license={license} allocations={allocations.filter((item) => item.licenseId === license.id)} role="user" />);
  expect(screen.getByRole("heading", { name: "Office 365 Family" })).toBeInTheDocument();
  expect(screen.getByText("33")).toBeInTheDocument();
  expect(screen.getByText("Supachai")).toBeInTheDocument();
});
