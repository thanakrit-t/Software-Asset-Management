import { PageHeader } from "@/components/ui/page-header";
import { AdminScreen } from "@/features/admin/admin-screen";
export default function SettingsPage() { return <div className="mx-auto max-w-5xl space-y-6"><PageHeader eyebrow="Administration" title="ตั้งค่าระบบ" description="กำหนดค่าองค์กร Session และนโยบาย License" /><AdminScreen variant="settings" /></div>; }
