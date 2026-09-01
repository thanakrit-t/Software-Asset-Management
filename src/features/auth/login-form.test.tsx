import { render, screen } from "@testing-library/react";
import { LoginForm } from "./login-form";

test("shows an accessible email and password login without public registration", () => {
  render(<LoginForm />);

  expect(screen.getByRole("textbox", { name: "อีเมล" })).toHaveAttribute(
    "autocomplete",
    "email",
  );
  expect(screen.getByLabelText("รหัสผ่าน")).toHaveAttribute(
    "type",
    "password",
  );
  expect(screen.getByRole("button", { name: "เข้าสู่ระบบ" })).toBeInTheDocument();
  expect(screen.queryByRole("link", { name: /สมัคร|register/i })).not.toBeInTheDocument();
});

test("announces field and generic errors", () => {
  render(
    <LoginForm
      initialState={{
        error: "ไม่สามารถเข้าสู่ระบบได้",
        fieldErrors: {
          email: "กรุณากรอกอีเมลให้ถูกต้อง",
          password: "กรุณากรอกรหัสผ่าน",
        },
      }}
    />,
  );

  expect(screen.getByRole("alert")).toHaveTextContent("ไม่สามารถเข้าสู่ระบบได้");
  expect(screen.getByText("กรุณากรอกอีเมลให้ถูกต้อง")).toBeInTheDocument();
  expect(screen.getByText("กรุณากรอกรหัสผ่าน")).toBeInTheDocument();
});
