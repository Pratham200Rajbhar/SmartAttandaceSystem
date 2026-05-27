"use client";

import React from "react";
import GlassCard from "./GlassCard";

interface GlassStatCardProps {
  icon: React.ReactNode;
  label: string;
  value: string | number;
  trend?: string;
  trendUp?: boolean;
  accentColor?: string;
}

const iconColors: Record<string, string> = {
  blue: "text-blue-400 bg-blue-500/[0.15] shadow-[0_0_15px_rgba(59,130,246,0.3)]",
  emerald: "text-emerald-400 bg-emerald-500/[0.15] shadow-[0_0_15px_rgba(16,185,129,0.3)]",
  amber: "text-amber-400 bg-amber-500/[0.15] shadow-[0_0_15px_rgba(245,158,11,0.3)]",
  rose: "text-rose-400 bg-rose-500/[0.15] shadow-[0_0_15px_rgba(244,63,94,0.3)]",
  purple: "text-purple-400 bg-purple-500/[0.15] shadow-[0_0_15px_rgba(168,85,247,0.3)]",
};

const hexColors: Record<string, string> = {
  blue: "#3b82f6",
  emerald: "#10b981",
  amber: "#f59e0b",
  rose: "#f43f5e",
  purple: "#a855f7",
};

const bgGradients: Record<string, string> = {
  blue: "bg-gradient-to-br from-blue-500/[0.04] to-transparent",
  emerald: "bg-gradient-to-br from-emerald-500/[0.04] to-transparent",
  amber: "bg-gradient-to-br from-amber-500/[0.04] to-transparent",
  rose: "bg-gradient-to-br from-rose-500/[0.04] to-transparent",
  purple: "bg-gradient-to-br from-purple-500/[0.04] to-transparent",
};

export default function GlassStatCard({
  icon,
  label,
  value,
  trend,
  trendUp,
  accentColor = "blue",
}: GlassStatCardProps): React.ReactElement {
  return (
    <GlassCard 
      hoverable 
      padding="lg" 
      className={`relative overflow-hidden ${bgGradients[accentColor] || bgGradients.blue}`}
      glowColor={hexColors[accentColor] || hexColors.blue}
    >
      <div className="flex items-start justify-between mb-4">
        <div className={`p-3 rounded-xl ${iconColors[accentColor] || iconColors.blue}`}>
          {icon}
        </div>
        {trend && (
          <span className={`text-xs font-semibold px-2.5 py-1 rounded-md flex items-center gap-1 ${
            trendUp 
              ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 shadow-[0_0_10px_rgba(16,185,129,0.1)]" 
              : "bg-rose-500/10 text-rose-400 border border-rose-500/20 shadow-[0_0_10px_rgba(244,63,94,0.1)]"
            }`}>
            {trendUp ? "↑" : "↓"} {trend}
          </span>
        )}
      </div>
      <p className="text-3xl font-bold text-white mb-1.5 tracking-tight drop-shadow-md">{value}</p>
      <p className="text-sm font-semibold text-slate-400 uppercase tracking-wider">{label}</p>
    </GlassCard>
  );
}
