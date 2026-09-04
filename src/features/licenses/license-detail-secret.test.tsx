import { render, screen } from "@testing-library/react";
import { allocations, licenses } from "@/features/sam/mock-data";
import { LicenseDetail } from "./license-detail";

test("renders only database-masked secret fields for every role", () => {
  const license = licenses[0];
  const related = allocations.filter((item) => item.licenseId === license.id);
  const { rerender } = render(
    <LicenseDetail license={license} allocations={related} role="user" />,
  );

  expect(screen.getByLabelText("Masked License Key")).toHaveTextContent("****-MASKED");
  expect(screen.getByLabelText("Masked Serial Number")).toHaveTextContent("****-MASKED");
  expect(screen.queryByRole("button", { name: /แสดง (License Key|Serial Number)/ })).not.toBeInTheDocument();

  rerender(<LicenseDetail license={license} allocations={related} role="admin" />);
  expect(screen.getByLabelText("Masked License Key")).toHaveTextContent("****-MASKED");
  expect(screen.queryByRole("button", { name: /แสดง (License Key|Serial Number)/ })).not.toBeInTheDocument();
  expect(license).not.toHaveProperty("licenseKey");
  expect(license).not.toHaveProperty("serialNumber");
});
