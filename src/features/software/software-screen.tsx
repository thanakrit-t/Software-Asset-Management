"use client";
import type { SoftwareProduct } from "@/features/sam/types";
import { useRole } from "@/components/app-shell/role-provider";
import { SoftwareList } from "./software-list";
export function SoftwareScreen({ products }: { products: SoftwareProduct[] }) { const { role } = useRole(); return <SoftwareList products={products} role={role} />; }
