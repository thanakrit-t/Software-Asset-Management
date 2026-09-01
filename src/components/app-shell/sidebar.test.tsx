import { render, screen } from "@testing-library/react";
import { Sidebar } from "./sidebar";

test("shows settings navigation to administrators", () => {
  render(<Sidebar role="admin" pathname="/" />);
  expect(screen.getByRole("link", { name: /ตั้งค่าระบบ/ })).toBeInTheDocument();
  expect(screen.getByRole("link", { name: /ข้อมูลตั้งต้น/ })).toBeInTheDocument();
});

test("hides management navigation from regular users", () => {
  render(<Sidebar role="user" pathname="/" />);
  expect(screen.queryByRole("link", { name: /ตั้งค่าระบบ/ })).not.toBeInTheDocument();
  expect(screen.queryByRole("link", { name: /ข้อมูลตั้งต้น/ })).not.toBeInTheDocument();
  expect(screen.getByRole("link", { name: /รายงาน/ })).toBeInTheDocument();
});

test("marks the matching route as current", () => {
  render(<Sidebar role="admin" pathname="/licenses" />);
  expect(screen.getByRole("link", { name: /^Licenses$/ })).toHaveAttribute(
    "aria-current",
    "page",
  );
});
