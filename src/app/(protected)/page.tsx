import { DashboardScreen } from "@/features/dashboard/dashboard-screen";
import { mockSamRepository } from "@/features/sam/mock-repository";

export default async function Home() {
  const [assets, licenses, notifications] = await Promise.all([
    mockSamRepository.listAssets(),
    mockSamRepository.listLicenses(),
    mockSamRepository.listNotifications(),
  ]);

  return <DashboardScreen assets={assets} licenses={licenses} notifications={notifications} />;
}
