import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LicenseKey } from "./license-key";

const keyValue = "MOCK4-O365F-ALLST-00004-PQRST";

test("masks a license key for a regular user", () => {
  render(<LicenseKey role="user" value={keyValue} />);
  expect(screen.getByText("•••••-•••••-•••••-•••••-PQRST")).toBeInTheDocument();
  expect(screen.queryByText(keyValue)).not.toBeInTheDocument();
});

test("allows an administrator to reveal a license key", async () => {
  const user = userEvent.setup();
  render(<LicenseKey role="admin" value={keyValue} />);
  await user.click(screen.getByRole("button", { name: /แสดง License Key/ }));
  expect(screen.getByText(keyValue)).toBeInTheDocument();
  expect(screen.getByText(/บันทึกเหตุการณ์ใน Audit Log/)).toBeInTheDocument();
});
