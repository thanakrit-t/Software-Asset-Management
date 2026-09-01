"use client";

import { useState } from "react";
import { CheckCircle2, Info, X } from "lucide-react";
import { Button } from "@/components/ui/button";

export function AssetFormDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [saved, setSaved] = useState(false);
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-[70] flex justify-end">
      <button type="button" aria-label="ปิดแบบฟอร์ม" onClick={onClose} className="absolute inset-0 bg-slate-950/40 backdrop-blur-sm" />
      <section role="dialog" aria-modal="true" aria-labelledby="asset-form-title" className="relative z-10 flex h-full w-full max-w-xl flex-col bg-white shadow-2xl">
        <header className="flex items-start justify-between border-b border-slate-200 px-6 py-5">
          <div><p className="text-xs font-bold uppercase tracking-[0.15em] text-blue-600">Asset Management</p><h2 id="asset-form-title" className="mt-1 text-xl font-bold text-slate-950">เพิ่ม Asset ใหม่</h2></div>
          <button type="button" aria-label="ปิด" onClick={onClose} className="grid size-11 place-items-center rounded-xl text-slate-500 hover:bg-slate-100"><X aria-hidden="true" size={20} /></button>
        </header>
        <form onSubmit={(event) => { event.preventDefault(); setSaved(true); }} className="flex flex-1 flex-col overflow-hidden">
          <div className="flex-1 space-y-6 overflow-y-auto px-6 py-5">
            <div className="flex gap-3 rounded-xl border border-blue-100 bg-blue-50 p-4 text-sm text-blue-800"><Info aria-hidden="true" className="mt-0.5 shrink-0" size={18} /><p>ข้อมูลตัวอย่างจะไม่ถูกบันทึก เนื่องจากรอบนี้ยังไม่เชื่อมต่อ Supabase</p></div>
            {saved ? <div role="status" className="flex gap-2 rounded-xl border border-emerald-100 bg-emerald-50 p-4 text-sm font-semibold text-emerald-800"><CheckCircle2 aria-hidden="true" size={18} />ตรวจสอบ UI สำเร็จ — ไม่มีการบันทึกข้อมูลจริง</div> : null}
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Asset Code" name="assetCode" placeholder="เช่น TPO-084" required />
              <Field label="Computer Name" name="computerName" placeholder="เช่น TPO-084-PC" required />
              <SelectField label="Site" name="site" options={["Factory", "Bangkok Office"]} />
              <SelectField label="Asset Type" name="type" options={["PC", "Notebook", "Server", "Other"]} />
              <Field label="Primary User" name="primaryUser" placeholder="ชื่อผู้ใช้งาน" />
              <Field label="Responsible Person" name="responsiblePerson" placeholder="ผู้รับผิดชอบ" />
              <Field label="Location" name="location" placeholder="ห้อง/พื้นที่" />
              <Field label="Department" name="department" placeholder="Workgroup" />
              <Field label="Operating System" name="os" placeholder="Windows 11 Professional" />
              <SelectField label="Status" name="status" options={["Active", "Spare", "Repair", "Retired"]} />
            </div>
          </div>
          <footer className="flex justify-end gap-2 border-t border-slate-200 px-6 py-4"><Button variant="secondary" onClick={onClose}>ยกเลิก</Button><Button type="submit">ตรวจสอบแบบฟอร์ม</Button></footer>
        </form>
      </section>
    </div>
  );
}

function Field({ label, name, placeholder, required }: { label: string; name: string; placeholder: string; required?: boolean }) {
  return <label className="space-y-1.5 text-sm font-semibold text-slate-700">{label}{required ? <span className="text-red-600"> *</span> : null}<input name={name} required={required} placeholder={placeholder} className="h-11 w-full rounded-xl border border-slate-200 px-3 text-sm font-normal focus:border-blue-400 focus:outline-none" /></label>;
}

function SelectField({ label, name, options }: { label: string; name: string; options: string[] }) {
  return <label className="space-y-1.5 text-sm font-semibold text-slate-700">{label}<select name={name} className="h-11 w-full rounded-xl border border-slate-200 bg-white px-3 text-sm font-normal focus:border-blue-400 focus:outline-none">{options.map((option) => <option key={option}>{option}</option>)}</select></label>;
}
