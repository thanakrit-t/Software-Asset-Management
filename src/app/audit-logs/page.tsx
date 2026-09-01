import { PageHeader } from "@/components/ui/page-header";
import { AdminScreen } from "@/features/admin/admin-screen";
import { mockSamRepository } from "@/features/sam/mock-repository";
export default async function AuditPage() { const events = await mockSamRepository.listAuditEvents(); return <div className="mx-auto max-w-[1300px] space-y-6"><PageHeader eyebrow="Security & Traceability" title="Audit Logs" description="ประวัติการเปลี่ยนแปลง การเปิดดูข้อมูลสำคัญ และการ Export" /><AdminScreen variant="audit" events={events} /></div>; }
