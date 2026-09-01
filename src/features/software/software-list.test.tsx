import { render, screen } from "@testing-library/react";
import { products } from "@/features/sam/mock-data";
import { SoftwareList } from "./software-list";

test("shows the software catalog with publisher and version", () => {
  render(<SoftwareList products={products} role="user" />);
  expect(screen.getByText("AutoCAD")).toBeInTheDocument();
  expect(screen.getAllByText("Microsoft").length).toBeGreaterThan(0);
  expect(screen.getByText("2014")).toBeInTheDocument();
});
