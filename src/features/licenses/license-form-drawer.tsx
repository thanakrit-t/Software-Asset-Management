"use client";

import { useState } from "react";
import { CheckCircle2, Info, X } from "lucide-react";
import { Button } from "@/components/ui/button";

const inputClass = "h-11 w-full rounded-xl border border-slate-200 bg-white px-3 font-normal focus:border-blue-400 focus:outline-none";

export function LicenseFormDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [reference, setReference] = useState("");
  const [product, setProduct] = useState("");
  const [vendor, setVendor] = useState("");
  const [ownedQuantity, setOwnedQuantity] = useState("1");
  const [feedback, setFeedback] = useState<{ type: "error" | "success"; text: string } | null>(null);
  if (!open) return null;

  function validate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const quantity = Number(ownedQuantity);
    if (!reference.trim() || !product || !vendor.trim() || !Number.isInteger(quantity) || quantity < 1) {
      setFeedback({ type: "error", text: "กรอกข้อมูลที่จำเป็นให้ครบ และระบุจำนวนสิทธิ์อย่างน้อย 1" });
      return;
    }
    setFeedback({ type: "success", text: "แบบฟอร์มผ่านการตรวจสอบแล้ว · เป็นข้อมูลสาธิตและยังไม่ถูกบันทึก" });
  }

  return (
    <div className="fixed inset-0 z-[70] flex justify-end">
      <button type="button" aria-label="ปิดแบบฟอร์ม" onClick={onClose} className="absolute inset-0 bg-slate-950/40 backdrop-blur-sm" />
      <section role="dialog" aria-modal="true" aria-labelledby="license-form-title" className="relative flex h-full w-full max-w-xl flex-col bg-white shadow-2xl">
        <header className="flex items-center justify-between border-b border-slate-200 px-6 py-5"><div><p className="text-xs font-bold uppercase tracking-wide text-blue-600">License Management</p><h2 id="license-form-title" className="mt-1 text-xl font-bold">เพิ่ม License ใหม่</h2></div><button type="button" aria-label="ปิด" onClick={onClose} className="grid size-11 place-items-center rounded-xl hover:bg-slate-100"><X aria-hidden="true" size={19} /></button></header>
        <form onSubmit={validate} className="flex min-h-0 flex-1 flex-col">
          <div className="flex-1 space-y-5 overflow-y-auto p-6">
            <p className="flex gap-2 rounded-xl bg-blue-50 p-4 text-sm text-blue-800"><Info aria-hidden="true" size={18} />UI-only form — ตรวจสอบความครบถ้วนได้ แต่ยังไม่บันทึกข้อมูลจริง</p>
            {feedback ? <p role={feedback.type === "error" ? "alert" : "status"} className={`rounded-xl p-4 text-sm font-semibold ${feedback.type === "error" ? "bg-red-50 text-red-700" : "flex gap-2 bg-emerald-50 text-emerald-700"}`}>{feedback.type === "success" ? <CheckCircle2 aria-hidden="true" size={18} /> : null}{feedback.text}</p> : null}
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">License Reference<input name="reference" value={reference} onChange={(event) => setReference(event.target.value)} className={inputClass} /></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">Software Product<select name="product" value={product} onChange={(event) => setProduct(event.target.value)} className={inputClass}><option value="">เลือก Product</option><option value="windows-11-pro">Windows 11 Professional</option><option value="office-365-family">Office 365 Family</option><option value="sql-server-2019">SQL Server Standard 2019</option></select></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">Vendor<input name="vendor" value={vendor} onChange={(event) => setVendor(event.target.value)} className={inputClass} /></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">Owned Quantity<input name="ownedQuantity" type="number" min="1" step="1" value={ownedQuantity} onChange={(event) => setOwnedQuantity(event.target.value)} className={inputClass} /></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">Purchase Date<input name="purchaseDate" type="date" className={inputClass} /></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">Start Date<input name="startDate" type="date" className={inputClass} /></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">End Date<input name="endDate" type="date" className={inputClass} /></label>
              <label className="space-y-1.5 text-sm font-semibold text-slate-700">Site Scope<select name="siteScope" defaultValue="All Sites" className={inputClass}><option>All Sites</option><option>Factory</option><option>Bangkok Office</option></select></label>
            </div>
          </div>
          <footer className="flex justify-end gap-2 border-t border-slate-200 p-4"><Button type="button" variant="secondary" onClick={onClose}>ยกเลิก</Button><Button type="submit">ตรวจสอบแบบฟอร์ม</Button></footer>
        </form>
      </section>
    </div>
  );
}
