import { render, screen } from "@testing-library/react";
import { AssetFormDrawer } from "./asset-form-drawer";

test("labels the form as non-persistent mock UI", () => {
  render(<AssetFormDrawer open onClose={() => undefined} />);
  expect(screen.getByRole("dialog", { name: /เพิ่ม Asset ใหม่/ })).toBeInTheDocument();
  expect(screen.getByText(/ข้อมูลตัวอย่างจะไม่ถูกบันทึก/)).toBeInTheDocument();
});
