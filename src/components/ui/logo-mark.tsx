import Image from "next/image";
import { cn } from "@/lib/cn";

export function LogoMark({ className }: { className?: string }) {
  return (
    <Image
      src="/images/c_logo.png"
      alt="Thai Kurabo"
      width={255}
      height={40}
      className={cn("h-auto w-[156px] shrink-0 object-contain", className)}
    />
  );
}
