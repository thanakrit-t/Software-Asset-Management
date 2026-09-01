import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { licenses } from "@/features/sam/mock-data";
import { AllocationDrawer } from "./allocation-drawer";

test("validates allocation input and warns when quantity exceeds availability", async () => {
  const user = userEvent.setup();
  render(<AllocationDrawer open onClose={() => undefined} licenses={licenses} />);

  await user.selectOptions(screen.getByLabelText("License"), licenses[0].id);
  await user.selectOptions(screen.getByLabelText("Target type"), "asset");
  await user.type(screen.getByLabelText("Asset / User / Site"), "TPO-083-PC");
  await user.clear(screen.getByLabelText("Quantity"));
  await user.type(screen.getByLabelText("Quantity"), String(licenses[0].availableQuantity + 1));
  await user.click(screen.getByRole("button", { name: "ตรวจสอบ" }));
  expect(screen.getByRole("alert")).toHaveTextContent(/เกินจำนวนคงเหลือ/);

  await user.clear(screen.getByLabelText("Quantity"));
  await user.type(screen.getByLabelText("Quantity"), "1");
  await user.click(screen.getByRole("button", { name: "ตรวจสอบ" }));
  expect(screen.getByRole("status")).toHaveTextContent(/พร้อมจัดสรร/);
});
