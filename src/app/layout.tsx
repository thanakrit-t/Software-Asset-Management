import type { Metadata } from "next";
import { AppShell } from "@/components/app-shell/app-shell";
import { RoleProvider } from "@/components/app-shell/role-provider";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Software Asset Management",
    template: "%s | Software Asset Management",
  },
  description: "ระบบบริหารสินทรัพย์คอมพิวเตอร์และสิทธิ์การใช้งานซอฟต์แวร์",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="th">
      <body>
        <RoleProvider>
          <AppShell>{children}</AppShell>
        </RoleProvider>
      </body>
    </html>
  );
}


