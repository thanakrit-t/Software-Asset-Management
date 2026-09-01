export function TableShell({ children, footer }: { children: React.ReactNode; footer?: React.ReactNode }) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-sm">
      <div className="overflow-x-auto">{children}</div>
      {footer ? <footer className="border-t border-slate-100 px-5 py-3">{footer}</footer> : null}
    </section>
  );
}
