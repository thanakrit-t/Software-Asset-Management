import { AppShell } from "@/components/app-shell/app-shell";
import { RoleProvider } from "@/components/app-shell/role-provider";
import { requireViewer } from "@/features/auth/guards";

export default async function ProtectedLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const viewer = await requireViewer();

  return (
    <RoleProvider viewer={viewer}>
      <AppShell>{children}</AppShell>
    </RoleProvider>
  );
}