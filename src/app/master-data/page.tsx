import { PageHeader } from "@/components/ui/page-header";
import { AdminScreen } from "@/features/admin/admin-screen";
export default function MasterDataPage() { return <div className="mx-auto max-w-[1500px] space-y-6"><PageHeader eyebrow="Administration" title="ข้อมูลตั้งต้น" description="กำหนดค่ามาตรฐานที่ใช้ร่วมกันในระบบ" /><AdminScreen variant="master" /></div>; }
