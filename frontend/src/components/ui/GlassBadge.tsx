"use client";

import React from "react";

export type BadgeVariant = "success" | "warning" | "danger" | "info" | "neutral";

interface GlassBadgeProps {
  variant: BadgeVariant;
  children: React.ReactNode;
  className?: string;
}

export default function GlassBadge({ variant, children, className = "" }: GlassBadgeProps): React.ReactElement {
  return <span className={`badge badge-${variant} ${className}`}>{children}</span>;
}

const STATUS_VARIANT_MAP: Record<string, BadgeVariant> = {
  Present: "success",
  Approved: "success",
  Flagged: "warning",
  Absent: "danger",
  Rejected: "danger",
  Active: "info",
  Inactive: "neutral",
};

export function statusToBadgeVariant(status: string): BadgeVariant {
  return STATUS_VARIANT_MAP[status] || "neutral";
}
