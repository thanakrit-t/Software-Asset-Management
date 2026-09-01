import { render, screen } from "@testing-library/react";
import { RoleProvider, useViewer } from "./role-provider";
import { Topbar } from "./topbar";

const viewer = {
  id: "admin-1",
  displayName: "Admin User",
  email: "admin@example.com",
  role: "admin" as const,
};

function ViewerProbe() {
  const currentViewer = useViewer();
  return (
    <output aria-label="current viewer">
      {currentViewer.email}:{currentViewer.role}
    </output>
  );
}

test("shows the verified viewer without a client-side role preview", () => {
  render(
    <RoleProvider viewer={viewer}>
      <Topbar onOpenMenu={() => undefined} />
      <ViewerProbe />
    </RoleProvider>,
  );

  expect(screen.getByText("Admin User")).toBeInTheDocument();
  expect(screen.getByLabelText("current viewer")).toHaveTextContent(
    "admin@example.com:admin",
  );
  expect(screen.queryByRole("combobox", { name: /เลือก Role/ })).not.toBeInTheDocument();
  expect(window.sessionStorage.getItem("sam-preview-role")).toBeNull();
  expect(screen.getByRole("button", { name: "ออกจากระบบ" })).toBeInTheDocument();
});