"use client";

import React, { useState } from "react";
import { 
  ScanSearch, 
  AlertTriangle, 
  User, 
  Hash, 
  Calendar, 
  ShieldAlert, 
  Sparkles, 
  Copy, 
  Check, 
  Search, 
  Sliders, 
  Cpu, 
  BarChart4
} from "lucide-react";
import api, { getApiErrorMessage } from "@/lib/api";
import toast from "react-hot-toast";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassSlider from "@/components/ui/GlassSlider";
import GlassButton from "@/components/ui/GlassButton";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import GlassBadge from "@/components/ui/GlassBadge";
import type { AnomalyResult } from "@/types";

/**
 * Returns a design-token hex color for card glowing border based on anomaly risk score.
 */
function getGlowColor(score: number): string {
  if (score > 0.25) return "#f43f5e"; // Rose / red glow for high risk
  if (score > 0.15) return "#f59e0b"; // Amber glow for medium risk
  return "#10b981"; // Emerald green glow for low risk
}

/**
 * Categorizes risk level based on the anomaly score.
 */
function getRiskLevel(score: number): { label: string; variant: "danger" | "warning" | "neutral" } {
  if (score > 0.25) {
    return { label: "High Risk", variant: "danger" };
  }
  if (score > 0.15) {
    return { label: "Medium Risk", variant: "warning" };
  }
  return { label: "Low Risk", variant: "neutral" };
}

export default function ScannerPage(): React.ReactElement {
  const [contamination, setContamination] = useState<number>(0.10);
  const [results, setResults] = useState<AnomalyResult[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [hasRun, setHasRun] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>("");
  const [copiedId, setCopiedId] = useState<string | null>(null);

  async function runScan(): Promise<void> {
    setLoading(true);
    try {
      const { data } = await api.post<AnomalyResult[]>(`/admin/scan-absentees?contamination=${contamination}`);
      setResults(data);
      setHasRun(true);
      if (data.length === 0) {
        toast.success("No anomalies detected");
      } else {
        toast("Scan complete — anomalies flagged", { icon: "⚠️" });
      }
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Scan failed"));
    } finally {
      setLoading(false);
    }
  }

  function handleCopyId(id: string): void {
    navigator.clipboard.writeText(id);
    setCopiedId(id);
    toast.success("Student ID copied");
    setTimeout(() => setCopiedId(null), 2000);
  }

  const filteredResults = results.filter((r) => {
    const name = (r.student_name || "").toLowerCase();
    const enroll = (r.enrollment_number || "").toLowerCase();
    const id = r.student_id.toLowerCase();
    const term = searchTerm.toLowerCase();
    return name.includes(term) || enroll.includes(term) || id.includes(term);
  });

  const avgScore = results.length > 0
    ? results.reduce((acc, curr) => acc + (curr.anomaly_score || 0), 0) / results.length
    : 0;

  const maxScore = results.length > 0
    ? Math.max(...results.map((r) => r.anomaly_score || 0))
    : 0;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "AI Scanner" }]} />
      
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
        <GlassPageHeader 
          title="AI Absentee Pattern Scanner" 
          description="Detect hidden class-skipping anomalies using an Isolation Forest ML model." 
        />
        <div className="flex items-center gap-2 self-start md:self-auto bg-emerald-500/10 border border-emerald-500/20 px-3 py-1.5 rounded-full text-xs font-semibold text-emerald-400">
          <Sparkles size={14} className="animate-pulse" />
          <span>Machine Learning Engine Active</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left Column: Parameter controls & ML Insights */}
        <div className="lg:col-span-4 flex flex-col gap-6">
          <GlassCard className="border-white/5 bg-slate-950/30">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-2.5 rounded-xl bg-white/5 text-emerald-400">
                <Sliders size={20} />
              </div>
              <div>
                <h3 className="text-md font-semibold text-slate-200">Scan Parameters</h3>
                <p className="text-xs text-slate-500">Configure sensitivity thresholds</p>
              </div>
            </div>

            <GlassSlider 
              label="Contamination Factor" 
              min={0.01} 
              max={0.50} 
              step={0.01} 
              value={contamination} 
              onChange={setContamination} 
            />

            <p className="text-xs text-slate-500 bg-white/5 p-3 rounded-lg mt-4 border border-white/5 leading-relaxed">
              <strong>Contamination:</strong> Estimates the proportion of outliers in the dataset. Lower values flag only extreme deviations; higher values flag more moderate patterns.
            </p>

            <div className="mt-6">
              <GlassButton 
                variant="primary" 
                size="lg" 
                loading={loading} 
                onClick={runScan}
                className={`w-full relative overflow-hidden group ${!loading ? "animate-pulse-glow" : ""}`}
                icon={<ScanSearch size={18} />}
              >
                {loading ? "Analyzing Datasets..." : "Run AI Anomaly Scan"}
              </GlassButton>
            </div>
          </GlassCard>

          <GlassCard className="border-white/5 bg-slate-950/30">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-2.5 rounded-xl bg-white/5 text-emerald-400">
                <Cpu size={20} />
              </div>
              <div>
                <h3 className="text-md font-semibold text-slate-200">How it works</h3>
                <p className="text-xs text-slate-500">Isolation Forest (iForest)</p>
              </div>
            </div>
            <p className="text-xs text-slate-400 leading-relaxed mb-3">
              Unlike normal profile clustering, Isolation Forest isolates anomalies instead of profiling normal points.
            </p>
            <p className="text-xs text-slate-400 leading-relaxed">
              By constructing random isolation trees, anomalous data points require significantly fewer splits to isolate, resulting in shorter path lengths and higher anomaly scores.
            </p>
          </GlassCard>
        </div>

        {/* Right Column: Scan results and flagged list */}
        <div className="lg:col-span-8 flex flex-col gap-6">
          
          {loading && (
            <GlassCard className="border-white/5 flex flex-col items-center justify-center py-20 text-center relative overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-r from-emerald-500/5 via-transparent to-emerald-500/5 animate-shimmer" />
              <div className="relative">
                <div className="w-16 h-16 rounded-full border-4 border-slate-800 border-t-emerald-500 animate-spin mb-6" />
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 -mt-3 text-emerald-400">
                  <ScanSearch size={24} className="animate-pulse" />
                </div>
              </div>
              <h4 className="text-lg font-medium text-slate-200 mb-2">Analyzing Attendance Matrices</h4>
              <p className="text-sm text-slate-500 max-w-sm">
                Fitting Isolation Forest decision trees, evaluating structural path splits, and computing student outlier scores...
              </p>
            </GlassCard>
          )}

          {!loading && !hasRun && (
            <GlassCard className="border-white/5 flex flex-col items-center justify-center py-24 text-center">
              <div className="p-4 bg-white/5 rounded-2xl mb-4 text-slate-400 relative">
                <div className="absolute -inset-1 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-500 opacity-20 blur-sm animate-pulse" />
                <ScanSearch size={40} className="relative" />
              </div>
              <h4 className="text-md font-semibold text-slate-300 mb-1">System Awaiting Analysis</h4>
              <p className="text-sm text-slate-500 max-w-md">
                Adjust the contamination factor and click &quot;Run AI Anomaly Scan&quot; to extract skip-patterns and generate risk profiles.
              </p>
            </GlassCard>
          )}

          {!loading && hasRun && results.length === 0 && (
            <GlassEmptyState 
              title="No Anomalies Flagged" 
              message="The ML engine checked all student records and found zero anomalous absentee patterns at this sensitivity level." 
            />
          )}

          {!loading && hasRun && results.length > 0 && (
            <div className="flex flex-col gap-4">
              
              {/* Stats Summary Panel */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="glass-panel-static p-4 flex items-center justify-between border-white/5 bg-slate-950/20">
                  <div>
                    <p className="text-xs text-slate-500 font-medium">Flagged Students</p>
                    <h5 className="text-xl font-bold text-slate-200 mt-1">{results.length}</h5>
                  </div>
                  <div className="p-2 bg-rose-500/10 rounded-xl text-rose-400">
                    <ShieldAlert size={20} />
                  </div>
                </div>
                <div className="glass-panel-static p-4 flex items-center justify-between border-white/5 bg-slate-950/20">
                  <div>
                    <p className="text-xs text-slate-500 font-medium">Avg Anomaly Score</p>
                    <h5 className="text-xl font-bold text-slate-200 mt-1">{avgScore.toFixed(3)}</h5>
                  </div>
                  <div className="p-2 bg-amber-500/10 rounded-xl text-amber-400">
                    <BarChart4 size={20} />
                  </div>
                </div>
                <div className="glass-panel-static p-4 flex items-center justify-between border-white/5 bg-slate-950/20">
                  <div>
                    <p className="text-xs text-slate-500 font-medium">Max Anomaly Score</p>
                    <h5 className="text-xl font-bold text-slate-200 mt-1">{maxScore.toFixed(3)}</h5>
                  </div>
                  <div className="p-2 bg-emerald-500/10 rounded-xl text-emerald-400">
                    <Sparkles size={20} />
                  </div>
                </div>
              </div>

              {/* Filter controls */}
              <div className="flex items-center gap-3">
                <div className="relative flex-1">
                  <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" size={18} />
                  <input 
                    type="text" 
                    placeholder="Filter by student name, enrollment, or ID..." 
                    value={searchTerm} 
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
                    className="glass-input glass-input-with-icon text-sm py-2.5"
                  />
                </div>
              </div>

              {/* Grid of Results */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {filteredResults.map((r, i) => {
                  const risk = getRiskLevel(r.anomaly_score || 0);
                  const glow = getGlowColor(r.anomaly_score || 0);
                  return (
                    <GlassCard 
                      key={i} 
                      hoverable={true} 
                      glowColor={glow} 
                      className="border-white/5 flex flex-col justify-between h-full bg-slate-950/20"
                    >
                      <div>
                        {/* Card Header: Badges & Score */}
                        <div className="flex items-center justify-between gap-2 mb-4">
                          <GlassBadge variant={risk.variant}>
                            {risk.label}
                          </GlassBadge>
                          <div className="text-right">
                            <p className="text-[10px] text-slate-500 uppercase tracking-wider font-semibold">Anomaly Score</p>
                            <p className="text-sm font-bold text-slate-200 font-mono">
                              {typeof r.anomaly_score === "number" ? r.anomaly_score.toFixed(3) : "—"}
                            </p>
                          </div>
                        </div>

                        {/* Student Main Details */}
                        <div className="mb-4">
                          <h4 className="text-base font-semibold text-slate-100 flex items-center gap-2 truncate">
                            <User size={16} className="text-slate-400 shrink-0" />
                            <span className="truncate">{r.student_name || "Unknown Student"}</span>
                          </h4>
                          
                          <p className="text-xs font-mono text-emerald-400 mt-1.5 flex items-center gap-1.5">
                            <Hash size={12} className="shrink-0" />
                            <span>{r.enrollment_number || "No Enrollment Num"}</span>
                          </p>
                        </div>
                      </div>

                      {/* Card Footer: Absences & ID Copy */}
                      <div className="pt-3 border-t border-white/5 mt-auto flex flex-col gap-2">
                        {typeof r.total_absences === "number" && (
                          <div className="flex items-center justify-between text-xs">
                            <span className="text-slate-500 flex items-center gap-1">
                              <Calendar size={12} />
                              Total Absences
                            </span>
                            <span className="text-slate-200 font-bold bg-white/5 px-2 py-0.5 rounded">
                              {r.total_absences}
                            </span>
                          </div>
                        )}

                        <div className="flex items-center justify-between gap-4 text-[10px] text-slate-500 font-mono mt-1 pt-1">
                          <span className="truncate">ID: {r.student_id}</span>
                          <button 
                            onClick={() => handleCopyId(r.student_id)}
                            className="p-1 hover:bg-white/5 rounded text-slate-400 hover:text-slate-200 transition-colors shrink-0"
                            title="Copy Student ID"
                          >
                            {copiedId === r.student_id ? <Check size={12} className="text-emerald-400" /> : <Copy size={12} />}
                          </button>
                        </div>
                      </div>
                    </GlassCard>
                  );
                })}
              </div>

              {filteredResults.length === 0 && (
                <div className="text-center py-10 glass-panel-static border-white/5">
                  <AlertTriangle className="mx-auto text-slate-500 mb-2" size={24} />
                  <p className="text-sm text-slate-400">No results match your search term.</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
