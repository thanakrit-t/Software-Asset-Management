import { AccessDenied } from "@/features/admin/access-denied";
import { requireAdmin } from "@/features/auth/guards";

export default async function AdminLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const viewer = await requireAdmin();
  return viewer ? children : <AccessDenied />;
}