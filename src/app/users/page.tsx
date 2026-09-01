import { PageHeader } from "@/components/ui/page-header";
import { AdminScreen } from "@/features/admin/admin-screen";
import { mockSamRepository } from "@/features/sam/mock-repository";
export default async function UsersPage() { const users = await mockSamRepository.listUsers(); return <div className="mx-auto max-w-[1500px] space-y-6"><PageHeader eyebrow="Administration" title="จัดการผู้ใช้งาน" description="ตัวอย่างบัญชีผู้ใช้ Role และสถานะการเข้าใช้งาน" /><AdminScreen variant="users" users={users} /></div>; }
