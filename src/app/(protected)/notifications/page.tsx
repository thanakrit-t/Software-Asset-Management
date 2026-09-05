import type { Metadata } from "next";
import { PageHeader } from "@/components/ui/page-header";
import { NotificationList } from "@/features/notifications/notification-list";
import { getServerSamRepository } from "@/features/sam/server-repository";
export const metadata: Metadata = { title: "Notifications" };
export default async function NotificationsPage() { const repository = await getServerSamRepository(); const notifications = await repository.listNotifications(); return <div className="mx-auto max-w-5xl space-y-6"><PageHeader eyebrow="Alerts & Reminders" title="การแจ้งเตือน" description="ติดตาม License ใกล้หมดอายุ หมดอายุ ใช้เกินสิทธิ์ และรายการ Asset ที่ต้องตรวจสอบ" /><NotificationList notifications={notifications} /></div>; }
