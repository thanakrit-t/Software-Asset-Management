"use client";

import { useState } from "react";
import { CheckCircle2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { LicenseEntitlement } from "@/features/sam/types";

const inputClass = "h-11 w-full rounded-xl border border-slate-200 bg-white px-3 font-normal focus:border-blue-400 focus:outline-none";

export function AllocationDrawer({ open, onClose, licenses }: { open: boolean; onClose: () => void; licenses: LicenseEntitlement[] }) {
  const [licenseId, setLicenseId] = useState("");
  const [targetType, setTargetType] = useState("");
  const [target, setTarget] = useState("");
  const [quantity, setQuantity] = useState("1");
  const [feedback, setFeedback] = useState<{ type: "error" | "success"; text: string } | null>(null);
  if (!open) return null;
  const selectedLicense = licenses.find((license) => license.id === licenseId);

  function validate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const requested = Number(quantity);
    if (!selectedLicense || !targetType || !target.trim() || !Number.isInteger(requested) || requested < 1) {
      setFeedback({ type: "error", text: "กรอก License, Target และ Quantity ให้ครบถ้วน" });
      return;
    }
    if (requested > selectedLicense.availableQuantity) {
      setFeedback({ type: "error", text: `จำนวน ${requested} เกินจำนวนคงเหลือ ${selectedLicense.availableQuantity} seats` });
      return;
    }
    setFeedback({ type: "success", text: "ข้อมูลพร้อมจัดสรร · เป็นการตรวจสอบ mock และยังไม่ถูกบันทึก" });
  }

  return (
    <div className="fixed inset-0 z-[70] grid place-items-center bg-slate-950/40 p-4 backdrop-blur-sm">
      <section role="dialog" aria-modal="true" aria-labelledby="allocation-title" className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl">
        <div className="flex justify-between"><div><p className="text-xs font-bold uppercase tracking-wide text-blue-600">UI Prototype</p><h2 id="allocation-title" className="mt-1 text-xl font-bold">จัดสรร License</h2></div><button type="button" aria-label="ปิด" onClick={onClose} className="grid size-10 place-items-center rounded-xl hover:bg-slate-100"><X aria-hidden="true" size={18} /></button></div>
        <p className="mt-4 rounded-xl bg-blue-50 p-4 text-sm text-blue-800">ตรวจสอบจำนวนคงเหลือจาก Allocation กลางได้แล้ว โดยยังไม่บันทึกข้อมูลจนกว่าจะเชื่อม Supabase</p>
        <form onSubmit={validate} className="mt-5 space-y-4">
          {feedback ? <p role={feedback.type === "error" ? "alert" : "status"} className={`rounded-xl p-4 text-sm font-semibold ${feedback.type === "error" ? "bg-red-50 text-red-700" : "flex gap-2 bg-emerald-50 text-emerald-700"}`}>{feedback.type === "success" ? <CheckCircle2 aria-hidden="true" size={18} /> : null}{feedback.text}</p> : null}
          <label className="block space-y-1.5 text-sm font-semibold text-slate-700">License<select value={licenseId} onChange={(event) => setLicenseId(event.target.value)} className={inputClass}><option value="">เลือก License</option>{licenses.map((license) => <option key={license.id} value={license.id}>{license.reference} · {license.product.name} ({license.availableQuantity} available)</option>)}</select></label>
          <label className="block space-y-1.5 text-sm font-semibold text-slate-700">Target type<select value={targetType} onChange={(event) => setTargetType(event.target.value)} className={inputClass}><option value="">เลือกประเภท</option><option value="asset">Asset</option><option value="user">User</option><option value="site">Site</option></select></label>
          <label className="block space-y-1.5 text-sm font-semibold text-slate-700">Asset / User / Site<input value={target} onChange={(event) => setTarget(event.target.value)} placeholder="เช่น TPO-083-PC" className={inputClass} /></label>
          <label className="block space-y-1.5 text-sm font-semibold text-slate-700">Quantity<input type="number" min="1" step="1" value={quantity} onChange={(event) => setQuantity(event.target.value)} className={inputClass} /></label>
          {selectedLicense ? <p className="text-xs font-semibold text-slate-500">คงเหลือ {selectedLicense.availableQuantity} seats จาก {selectedLicense.ownedQuantity} seats</p> : null}
          <div className="flex justify-end gap-2 pt-2"><Button type="button" variant="secondary" onClick={onClose}>ยกเลิก</Button><Button type="submit">ตรวจสอบ</Button></div>
        </form>
      </section>
    </div>
  );
}
