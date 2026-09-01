import { render, screen } from "@testing-library/react";
import { allocations, licenses } from "@/features/sam/mock-data";
import { AllocationList } from "./allocation-list";

test("shows allocation targets and hides create action from users", () => {
  render(<AllocationList allocations={allocations} licenses={licenses} role="user" />);
  expect(screen.getByText("TPO-083-PC")).toBeInTheDocument();
  expect(screen.queryByRole("button", { name: /จัดสรร License/ })).not.toBeInTheDocument();
});
