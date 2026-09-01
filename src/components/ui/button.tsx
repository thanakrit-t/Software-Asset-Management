import { forwardRef, type ButtonHTMLAttributes } from "react";
import { cn } from "@/lib/cn";

type ButtonVariant = "primary" | "secondary" | "ghost" | "danger";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: "sm" | "md";
}

const variants: Record<ButtonVariant, string> = {
  primary: "bg-primary text-white shadow-sm shadow-blue-900/15 hover:bg-blue-700",
  secondary: "border border-border bg-white text-slate-700 hover:bg-slate-50",
  ghost: "text-slate-600 hover:bg-slate-100 hover:text-slate-950",
  danger: "bg-critical text-white hover:bg-red-700",
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { className, variant = "primary", size = "md", type = "button", ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cn(
        "inline-flex min-h-11 items-center justify-center gap-2 rounded-xl font-semibold transition-colors focus-visible:outline-2 disabled:cursor-not-allowed disabled:opacity-50",
        size === "sm" ? "px-3 text-sm" : "px-4 text-sm",
        variants[variant],
        className,
      )}
      {...props}
    />
  );
});
