"use client";
import { AlertTriangle } from "lucide-react";
import { Button } from "@/components/ui/button";
export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) { return <section className="grid min-h-[60vh] place-items-center text-center"><div><span className="mx-auto grid size-16 place-items-center rounded-2xl bg-red-50 text-red-700"><AlertTriangle aria-hidden="true" size={28} /></span><h1 className="mt-5 text-2xl font-bold text-slate-950">ไม่สามารถโหลดข้อมูลได้</h1><p className="mt-2 text-sm text-slate-500">กรุณาลองใหม่อีกครั้ง หากปัญหายังอยู่ให้ติดต่อผู้ดูแลระบบ</p><Button className="mt-5" onClick={reset}>ลองใหม่</Button></div></section>; }
