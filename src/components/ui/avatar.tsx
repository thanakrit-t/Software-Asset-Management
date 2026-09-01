export function Avatar({ name }: { name: string }) {
  const initials = name.split(" ").map((part) => part[0]).join("").slice(0, 2).toUpperCase();
  return (
    <span aria-label={name} className="grid size-10 place-items-center rounded-xl bg-blue-100 text-sm font-bold text-blue-800">
      {initials}
    </span>
  );
}
