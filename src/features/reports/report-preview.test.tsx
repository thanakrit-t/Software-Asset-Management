import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ReportCatalog } from "./report-catalog";

test("offers all reports and opens a filterable mock preview", async () => {
  const user = userEvent.setup();
  render(<ReportCatalog />);

  expect(screen.getAllByRole("button", { name: /ดูตัวอย่าง/ })).toHaveLength(14);
  await user.click(screen.getByRole("button", { name: /ดูตัวอย่าง Asset Inventory Report/ }));
  expect(screen.getByRole("heading", { name: /ตัวอย่าง Asset Inventory Report/ })).toBeInTheDocument();
  expect(screen.getByRole("combobox", { name: "Site" })).toBeInTheDocument();
  expect(screen.getByLabelText("วันที่เริ่มต้น")).toBeInTheDocument();
  expect(screen.getByRole("table", { name: /Report preview/ })).toBeInTheDocument();
  expect(screen.getByRole("button", { name: /Export/ })).toBeDisabled();
  expect(screen.getByRole("columnheader", { name: "Asset" })).toBeInTheDocument();

  await user.selectOptions(screen.getByRole("combobox", { name: "Site" }), "Bangkok Office");
  expect(screen.queryByText("TPO-083-PC")).not.toBeInTheDocument();
  expect(screen.getByText("TKCBKKLT001")).toBeInTheDocument();

  await user.clear(screen.getByLabelText("วันที่เริ่มต้น"));
  await user.type(screen.getByLabelText("วันที่เริ่มต้น"), "2026-08-20");
  expect(screen.getByText("ไม่พบข้อมูลตามตัวกรอง")).toBeInTheDocument();

  await user.click(screen.getByRole("button", { name: /ดูตัวอย่าง License Inventory Report/ }));
  expect(screen.getByRole("columnheader", { name: "Owned" })).toBeInTheDocument();
  expect(screen.queryByRole("columnheader", { name: "Asset" })).not.toBeInTheDocument();
});
