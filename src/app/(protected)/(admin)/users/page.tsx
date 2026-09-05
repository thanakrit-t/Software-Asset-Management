import { PageHeader } from "@/components/ui/page-header";
import { AdminScreen } from "@/features/admin/admin-screen";
import { getServerSamRepository } from "@/features/sam/server-repository";
export default async function UsersPage() { const repository = await getServerSamRepository(); const users = await repository.listUsers(); return <div className="mx-auto max-w-[1500px] space-y-6"><PageHeader eyebrow="Administration" title="จัดการผู้ใช้งาน" description="ตัวอย่างบัญชีผู้ใช้ Role และสถานะการเข้าใช้งาน" /><AdminScreen variant="users" users={users} /></div>; }
