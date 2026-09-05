import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { AssetListScreen } from "@/features/assets/asset-list-screen";
import { getServerSamRepository } from "@/features/sam/server-repository";

export const metadata: Metadata = { title: "Assets" };

export default async function AssetsPage() { const repository = await getServerSamRepository();
  const assets = await repository.listAssets();
  return (
    <div className="mx-auto max-w-[1600px] space-y-6">
      <PageHeader eyebrow="Asset Management" title="Assets" description="ค้นหาและตรวจสอบอุปกรณ์คอมพิวเตอร์ ผู้ใช้งาน ระบบปฏิบัติการ และข้อมูล Network จากฐานข้อมูลกลาง" />
      <AssetListScreen assets={assets} />
    </div>
  );
}
