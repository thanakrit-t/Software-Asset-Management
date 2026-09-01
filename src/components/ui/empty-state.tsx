import type { LucideIcon } from "lucide-react";

export function EmptyState({ icon: Icon, title, description }: { icon: LucideIcon; title: string; description: string }) {
  return <div className="grid min-h-64 place-items-center px-6 py-12 text-center"><div><span className="mx-auto grid size-12 place-items-center rounded-2xl bg-slate-100 text-slate-500"><Icon aria-hidden="true" size={22} /></span><h3 className="mt-4 font-bold text-slate-900">{title}</h3><p className="mt-1 text-sm text-slate-500">{description}</p></div></div>;
}
