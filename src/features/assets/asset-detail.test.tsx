import { render, screen } from "@testing-library/react";
import { allocations, assets } from "@/features/sam/mock-data";
import { AssetDetail } from "./asset-detail";

test("shows asset identity network and software allocations", () => {
  const asset = assets.find((item) => item.id === "tpo-083")!;
  render(<AssetDetail asset={asset} allocations={allocations.filter((item) => item.targetId === asset.id)} role="user" />);
  expect(screen.getByRole("heading", { name: "TPO-083" })).toBeInTheDocument();
  expect(screen.getByText("192.168.1.57")).toBeInTheDocument();
  expect(screen.getAllByText("Windows 11 Professional").length).toBeGreaterThan(0);
});

test("shows edit action only to administrators", () => {
  const asset = assets[0];
  const { rerender } = render(<AssetDetail asset={asset} allocations={[]} role="user" />);
  expect(screen.queryByRole("button", { name: /แก้ไข Asset/ })).not.toBeInTheDocument();
  rerender(<AssetDetail asset={asset} allocations={[]} role="admin" />);
  expect(screen.getByRole("button", { name: /แก้ไข Asset/ })).toBeInTheDocument();
});

