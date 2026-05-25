"use client";

import React from "react";

type BadgeVariant = "success" | "warning" | "danger" | "info" | "neutral";

interface GlassBadgeProps {
  variant: BadgeVariant;
  children: React.ReactNode;
  className?: string;
}


export default function GlassBadge({ variant, children, className = "" }: GlassBadgeProps): React.ReactElement {
  return <span className={`badge badge-${variant} ${className}`}>{children}</span>;
}


export function statusToBadgeVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    Present: "success",
    Approved: "success",
    Flagged: "warning",
    Absent: "danger",
    Rejected: "danger",
    Active: "info",
    Inactive: "neutral",
  };
  return map[status] || "neutral";
}
