"use client";

import React from "react";
import { AlertTriangle } from "lucide-react";
import GlassButton from "./GlassButton";

interface GlassConfirmDialogProps {
  isOpen: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
  loading?: boolean;
  variant?: "danger" | "primary";
}

export default function GlassConfirmDialog({
  isOpen,
  title,
  message,
  confirmLabel = "Confirm",
  onConfirm,
  onCancel,
  loading = false,
  variant = "danger",
}: GlassConfirmDialogProps): React.ReactElement | null {
  if (!isOpen) return null;

  return (
    <div className="overlay" onClick={onCancel}>
      <div className="modal-panel max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-start gap-4 mb-6">
          <div className="p-2.5 rounded-xl bg-white/5">
            <AlertTriangle size={22} className="text-slate-300" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-slate-100">{title}</h3>
            <p className="text-sm text-slate-400 mt-1">{message}</p>
          </div>
        </div>
        <div className="flex justify-end gap-3">
          <GlassButton variant="ghost" onClick={onCancel} disabled={loading}>
            Cancel
          </GlassButton>
          <GlassButton variant={variant === "danger" ? "danger" : "primary"} onClick={onConfirm} loading={loading}>
            {confirmLabel}
          </GlassButton>
        </div>
      </div>
    </div>
  );
}
