import { render, screen } from "@testing-library/react";
import LoginPage from "./page";

test("shows the Thai Kurabo logo above the login form", () => {
  render(<LoginPage />);

  expect(screen.getByRole("img", { name: "Thai Kurabo" })).toBeInTheDocument();
  expect(screen.getByRole("heading", { name: "Software Asset Management" })).toBeInTheDocument();
});
