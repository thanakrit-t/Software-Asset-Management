import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { RoleProvider, useRole } from "./role-provider";
import { Topbar } from "./topbar";

function RoleProbe() {
  const { role } = useRole();
  return <output aria-label="current role">{role}</output>;
}

test("switches the UI preview role and persists it for the session", async () => {
  const user = userEvent.setup();
  render(
    <RoleProvider>
      <Topbar onOpenMenu={() => undefined} />
      <RoleProbe />
    </RoleProvider>,
  );
  await user.selectOptions(screen.getByRole("combobox", { name: /เลือก Role/ }), "user");
  expect(screen.getByLabelText("current role")).toHaveTextContent("user");
  expect(window.sessionStorage.getItem("sam-preview-role")).toBe("user");
});
