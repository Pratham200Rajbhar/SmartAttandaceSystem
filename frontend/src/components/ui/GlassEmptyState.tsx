"use client";

import React from "react";
import { Inbox } from "lucide-react";
import GlassButton from "./GlassButton";

interface GlassEmptyStateProps {
  title?: string;
  message?: string;
  actionLabel?: string;
  onAction?: () => void;
}

export default function GlassEmptyState({
  title = "No data yet",
  message = "There is nothing to display right now.",
  actionLabel,
  onAction,
}: GlassEmptyStateProps): React.ReactElement {
  return (
    <div className="glass-panel-static p-16 text-center animate-fade-in-up">
      <Inbox size={48} className="text-slate-600 mx-auto mb-4" />
      <h3 className="text-lg font-semibold text-slate-300 mb-2">{title}</h3>
      <p className="text-sm text-slate-500 mb-6 max-w-sm mx-auto">{message}</p>
      {actionLabel && onAction && (
        <GlassButton variant="primary" onClick={onAction}>{actionLabel}</GlassButton>
      )}
    </div>
  );
}
