"use client";

import { useEffect, useState } from "react";
import GlassCard from "@/components/ui/GlassCard";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import { ShieldCheckIcon, MapPinIcon, CameraIcon, AlertTriangleIcon } from "lucide-react";
import api, { getApiErrorMessage } from "@/lib/api";
import { toast } from "react-hot-toast";

interface SystemConfig {
  isFaceRecognitionEnabled: boolean;
  isGpsVerificationEnabled: boolean;
  isAiBackgroundValidationEnabled: boolean;
}

export default function VerificationSettingsPage() {
  const [config, setConfig] = useState<SystemConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function fetchConfig() {
    try {
      setLoading(true);
      setError(null);
      const { data } = await api.get<SystemConfig>("/admin/config");
      setConfig(data);
    } catch (err: unknown) {
      setError(getApiErrorMessage(err, "Failed to fetch configuration"));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      void fetchConfig();
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  const handleToggle = (key: keyof SystemConfig) => {
    if (!config) return;
    setConfig({ ...config, [key]: !config[key] });
  };

  const handleSave = async () => {
    if (!config) return;
    try {
      setSaving(true);
      setError(null);
      await api.patch("/admin/config", config);
      toast.success("Configuration saved successfully");
    } catch (err: unknown) {
      setError(getApiErrorMessage(err, "Failed to save configuration"));
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <GlassLoader text="Loading configuration..." />
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <GlassPageHeader
        title="Verification Kill-Switch"
        description="Dynamically enable or disable specific verification steps for the attendance system."
      />

      {error && (
        <div className="p-4 bg-red-500/20 border border-red-500/50 rounded-xl text-red-200 flex items-start gap-3">
          <AlertTriangleIcon className="w-5 h-5 shrink-0 mt-0.5" />
          <p>{error}</p>
        </div>
      )}

      <div className="p-4 bg-amber-500/10 border border-amber-500/30 rounded-xl text-amber-200 flex items-start gap-3">
        <AlertTriangleIcon className="w-5 h-5 shrink-0 mt-0.5" />
        <div>
          <h4 className="font-semibold">Important Warning</h4>
          <p className="text-sm opacity-90 mt-1">
            Disabling a verification step will automatically mark that check as 100% successful for all users. This acts as a fallback if an AI model or external API experiences downtime. Use with caution.
          </p>
        </div>
      </div>

      {config && (
        <GlassCard className="p-6">
          <div className="space-y-8">
            <ToggleOption
              icon={<CameraIcon className="w-6 h-6 text-blue-400" />}
              title="Face Recognition"
              description="Verify student identity using facial recognition AI models."
              enabled={config.isFaceRecognitionEnabled}
              onToggle={() => handleToggle("isFaceRecognitionEnabled")}
            />
            
            <ToggleOption
              icon={<MapPinIcon className="w-6 h-6 text-emerald-400" />}
              title="GPS Geofencing"
              description="Verify student location against the classroom geofence."
              enabled={config.isGpsVerificationEnabled}
              onToggle={() => handleToggle("isGpsVerificationEnabled")}
            />

            <ToggleOption
              icon={<ShieldCheckIcon className="w-6 h-6 text-purple-400" />}
              title="AI Background Validation"
              description="Analyze background context to ensure students are in a classroom setting."
              enabled={config.isAiBackgroundValidationEnabled}
              onToggle={() => handleToggle("isAiBackgroundValidationEnabled")}
            />
          </div>

          <div className="mt-8 pt-6 border-t border-white/10 flex justify-end">
            <GlassButton
              onClick={handleSave}
              disabled={saving}
              variant="primary"
            >
              {saving ? "Saving..." : "Save Configuration"}
            </GlassButton>
          </div>
        </GlassCard>
      )}
    </div>
  );
}

function ToggleOption({ 
  icon, 
  title, 
  description, 
  enabled, 
  onToggle 
}: { 
  icon: React.ReactNode; 
  title: string; 
  description: string; 
  enabled: boolean; 
  onToggle: () => void; 
}) {
  return (
    <div className="flex items-start gap-4">
      <div className="p-3 rounded-xl bg-white/5 border border-white/10">
        {icon}
      </div>
      <div className="flex-1">
        <h3 className="text-lg font-medium text-white">{title}</h3>
        <p className="text-sm text-white/60 mt-1">{description}</p>
      </div>
      <div>
        <button
          type="button"
          onClick={onToggle}
          className={`relative inline-flex h-7 w-14 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-slate-900 ${
            enabled ? 'bg-blue-500' : 'bg-slate-700'
          }`}
          role="switch"
          aria-checked={enabled}
        >
          <span className="sr-only">Toggle {title}</span>
          <span
            aria-hidden="true"
            className={`pointer-events-none inline-block h-6 w-6 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
              enabled ? 'translate-x-7' : 'translate-x-0'
            }`}
          />
        </button>
      </div>
    </div>
  );
}
