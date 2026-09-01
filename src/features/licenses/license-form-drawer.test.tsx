import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LicenseFormDrawer } from "./license-form-drawer";

test("validates required license fields and confirms a mock submission", async () => {
  const user = userEvent.setup();
  render(<LicenseFormDrawer open onClose={() => undefined} />);
  await user.click(screen.getByRole("button", { name: "ตรวจสอบแบบฟอร์ม" }));
  expect(screen.getByRole("alert")).toHaveTextContent(/กรอกข้อมูลที่จำเป็น/);

  await user.type(screen.getByLabelText("License Reference"), "LIC-TEST-001");
  await user.selectOptions(screen.getByLabelText("Software Product"), "windows-11-pro");
  await user.type(screen.getByLabelText("Vendor"), "Mock Vendor");
  await user.clear(screen.getByLabelText("Owned Quantity"));
  await user.type(screen.getByLabelText("Owned Quantity"), "5");
  await user.click(screen.getByRole("button", { name: "ตรวจสอบแบบฟอร์ม" }));
  expect(screen.getByRole("status")).toHaveTextContent(/ผ่านการตรวจสอบ/);
});
