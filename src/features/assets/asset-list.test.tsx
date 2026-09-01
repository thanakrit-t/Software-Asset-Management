import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { assets } from "@/features/sam/mock-data";
import { AssetList } from "./asset-list";

test("filters assets by computer name", async () => {
  const user = userEvent.setup();
  render(<AssetList role="user" assets={assets} />);
  await user.type(screen.getByRole("searchbox", { name: /ค้นหา Asset/ }), "TPO-083");
  expect(screen.getByText("TPO-083-PC")).toBeInTheDocument();
  expect(screen.queryByText("TKCBKKLT001")).not.toBeInTheDocument();
});

test("shows the add action only to administrators", () => {
  const { rerender } = render(<AssetList role="user" assets={assets} />);
  expect(screen.queryByRole("button", { name: /เพิ่ม Asset/ })).not.toBeInTheDocument();
  rerender(<AssetList role="admin" assets={assets} />);
  expect(screen.getByRole("button", { name: /เพิ่ม Asset/ })).toBeInTheDocument();
});

test("filters assets by site and status", async () => {
  const user = userEvent.setup();
  render(<AssetList role="user" assets={assets} />);
  await user.selectOptions(screen.getByRole("combobox", { name: /Site/ }), "bangkok-office");
  await user.selectOptions(screen.getByRole("combobox", { name: /Status/ }), "spare");
  expect(screen.getByText("TKCBKKLT014")).toBeInTheDocument();
  expect(screen.queryByText("TPO-083-PC")).not.toBeInTheDocument();
});
