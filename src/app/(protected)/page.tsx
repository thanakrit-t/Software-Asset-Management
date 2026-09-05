import { DashboardScreen } from "@/features/dashboard/dashboard-screen";
import { getServerSamRepository } from "@/features/sam/server-repository";

export default async function Home() { const repository = await getServerSamRepository();
  const [assets, licenses, notifications] = await Promise.all([
    repository.listAssets(),
    repository.listLicenses(),
    repository.listNotifications(),
  ]);

  return <DashboardScreen assets={assets} licenses={licenses} notifications={notifications} />;
}
