import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { allocations, licenses } from "@/features/sam/mock-data";
import { LicenseDetail } from "./license-detail";

test("masks serial numbers for users and lets admins reveal them", async () => {
  const license = licenses[0];
  const related = allocations.filter((item) => item.licenseId === license.id);
  const { rerender } = render(
    <LicenseDetail license={license} allocations={related} role="user" />,
  );
  expect(screen.queryByText(license.serialNumber)).not.toBeInTheDocument();
  expect(screen.queryByRole("button", { name: /แสดง Serial Number/ })).not.toBeInTheDocument();

  rerender(<LicenseDetail license={license} allocations={related} role="admin" />);
  await userEvent.click(screen.getByRole("button", { name: /แสดง Serial Number/ }));
  expect(screen.getByText(license.serialNumber)).toBeInTheDocument();
});
