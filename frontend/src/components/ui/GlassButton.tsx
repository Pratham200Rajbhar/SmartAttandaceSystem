"use client";

import React from "react";

type ButtonVariant = "primary" | "secondary" | "danger" | "ghost";
type ButtonSize = "sm" | "md" | "lg";

interface GlassButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  icon?: React.ReactNode;
}

export default function GlassButton({
  variant = "primary",
  size = "md",
  loading = false,
  icon,
  children,
  className = "",
  disabled,
  ...props
}: GlassButtonProps): React.ReactElement {
  const variantClass = `glass-btn-${variant}`;
  const sizeClass = size !== "md" ? `glass-btn-${size}` : "";

  return (
    <button
      className={`glass-btn ${variantClass} ${sizeClass} ${className}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? <span className="spinner" /> : icon}
      {children}
    </button>
  );
}
