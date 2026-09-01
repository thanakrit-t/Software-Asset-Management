import { render, screen } from "@testing-library/react";
import { SettingsView } from "./settings-view";

test("blocks settings content in regular user preview", () => {
  render(<SettingsView role="user" />);
  expect(screen.getByRole("heading", { name: /ไม่มีสิทธิ์เข้าถึง/ })).toBeInTheDocument();
  expect(screen.queryByLabelText(/Session timeout/)).not.toBeInTheDocument();
});

test("shows system settings to administrators", () => {
  render(<SettingsView role="admin" />);
  expect(screen.getByLabelText(/Session timeout/)).toBeInTheDocument();
  expect(screen.getByLabelText(/Expiration threshold/)).toBeInTheDocument();
});
