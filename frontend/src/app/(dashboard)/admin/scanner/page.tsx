"use client";

import React, { useState } from "react";
import { ScanSearch, AlertTriangle } from "lucide-react";
import api from "@/lib/api";
import toast from "react-hot-toast";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassSlider from "@/components/ui/GlassSlider";
import GlassButton from "@/components/ui/GlassButton";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import type { AnomalyResult } from "@/types";


export default function ScannerPage(): React.ReactElement {
  const [contamination, setContamination] = useState(0.10);
  const [results, setResults] = useState<AnomalyResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasRun, setHasRun] = useState(false);

  async function runScan(): Promise<void> {
    setLoading(true);
    try {
      const { data } = await api.post<AnomalyResult[]>(`/admin/scan-absentees?contamination=${contamination}`);
      setResults(data);
      setHasRun(true);
      if (data.length === 0) toast.success("No anomalies detected");
      else toast("Scan complete — anomalies found", { icon: "⚠️" });
    } catch (err: unknown) {
      toast.error((err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || "Scan failed");
    } finally { setLoading(false); }
  }

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "AI Scanner" }]} />
      <GlassPageHeader title="AI Absentee Pattern Scanner" description="Detect hidden skipping patterns using Isolation Forest anomaly detection" />

      <GlassCard className="max-w-2xl mb-8">
        <div className="flex items-start gap-4 mb-6">
          <div className="p-3 rounded-xl bg-white/5">
            <ScanSearch size={28} className="text-slate-300" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-slate-200">Anomaly Detection Engine</h3>
            <p className="text-sm text-slate-400 mt-1">Adjust contamination factor to control sensitivity. Higher values flag more students.</p>
          </div>
        </div>

        <GlassSlider label="Contamination Factor" min={0.01} max={0.50} step={0.01} value={contamination} onChange={setContamination} />

        <div className="mt-6">
          <GlassButton variant="primary" size="lg" loading={loading} onClick={runScan}
            className={`w-full ${!loading ? "animate-pulse-glow" : ""}`}
            icon={<ScanSearch size={18} />}>
            Run AI Anomaly Scan
          </GlassButton>
        </div>
      </GlassCard>

      {hasRun && results.length === 0 && (
        <GlassEmptyState title="All Clear" message="No anomalous absentee patterns detected in the system." />
      )}

      {results.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold text-slate-200 mb-4 flex items-center gap-2">
            <AlertTriangle size={20} className="text-slate-300" />
            Flagged Students ({results.length})
          </h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {results.map((r, i) => (
              <GlassCard key={i} className="border-white/10">
                <div className="flex items-center justify-between mb-3">
                  <span className="badge badge-warning">Anomaly</span>
                  <span className="text-xs text-slate-500">Score: {typeof r.anomaly_score === "number" ? r.anomaly_score.toFixed(3) : "—"}</span>
                </div>
                <p className="text-xs text-slate-500">Student ID</p>
                <p className="text-sm font-mono text-slate-300 truncate">{r.student_id}</p>
                {typeof r.total_absences === "number" && (
                  <p className="text-xs text-slate-500 mt-2">Total absences: <span className="text-slate-300 font-semibold">{r.total_absences}</span></p>
                )}
              </GlassCard>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
