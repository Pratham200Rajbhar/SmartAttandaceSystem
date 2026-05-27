"use client";

import React, { useState } from "react";

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  hoverable?: boolean;
  padding?: "none" | "sm" | "md" | "lg";
  onClick?: () => void;
  glowColor?: string;
}

export default function GlassCard({
  children,
  className = "",
  hoverable = false,
  padding = "md",
  onClick,
  glowColor,
}: GlassCardProps): React.ReactElement {
  const [isHovered, setIsHovered] = useState(false);
  const padMap = { none: "p-0", sm: "p-4", md: "p-6", lg: "p-8" };

  const glowStyle =
    hoverable && isHovered && glowColor
      ? { boxShadow: `0 24px 48px rgba(0, 0, 0, 0.8), 0 0 40px ${glowColor}20, inset 0 1px 0 0 rgba(255, 255, 255, 0.25)` }
      : {};

  return (
    <div
      className={`${hoverable ? "glass-panel" : "glass-panel-static"} ${padMap[padding]} ${
        onClick ? "cursor-pointer" : ""
      } ${className}`}
      onClick={onClick}
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
      onKeyDown={onClick ? (e) => e.key === "Enter" && onClick() : undefined}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={glowStyle}
    >
      {children}
    </div>
  );
}
