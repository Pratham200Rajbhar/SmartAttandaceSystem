import React, { useState } from "react";
import { KeyRound, Lock } from "lucide-react";
import GlassButton from "./GlassButton";
import GlassInput from "./GlassInput";
import toast from "react-hot-toast";

interface GlassResetPasswordDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (newPassword: string) => Promise<void>;
  title: string;
  description: string;
}

export default function GlassResetPasswordDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  description,
}: GlassResetPasswordDialogProps): React.ReactElement | null {
  const [newPassword, setNewPassword] = useState("");
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword.length < 8) {
      toast.error("Password must be at least 8 characters");
      return;
    }
    setLoading(true);
    try {
      await onConfirm(newPassword);
      setNewPassword(""); // clear on success
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-fade-in">
      <div className="glass-panel-static w-full max-w-sm p-6 shadow-2xl relative">
        <div className="flex items-center gap-3 mb-2 text-warning">
          <div className="p-2 rounded-lg bg-warning/10 border border-warning/20">
            <KeyRound size={20} />
          </div>
          <h2 className="text-lg font-bold font-[Outfit] text-slate-200">{title}</h2>
        </div>
        <p className="text-sm text-slate-400 mb-6">{description}</p>
        
        <form onSubmit={handleSubmit}>
          <div className="mb-6">
            <GlassInput
              type="password"
              placeholder="New Password (min 8 chars)"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              icon={<Lock size={16} className="text-slate-400" />}
              autoComplete="new-password"
            />
          </div>

          <div className="flex gap-3 justify-end mt-4">
            <GlassButton
              type="button"
              variant="ghost"
              onClick={() => {
                setNewPassword("");
                onClose();
              }}
              disabled={loading}
            >
              Cancel
            </GlassButton>
            <GlassButton type="submit" variant="primary" loading={loading}>
              Reset Password
            </GlassButton>
          </div>
        </form>
      </div>
    </div>
  );
}
