"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { CheckCircle2, XCircle, MessageSquare } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassTextarea from "@/components/ui/GlassTextarea";
import GlassButton from "@/components/ui/GlassButton";
import GlassConfirmDialog from "@/components/ui/GlassConfirmDialog";
import GlassLoader from "@/components/ui/GlassLoader";
import type { FlaggedAttendanceResponse } from "@/types";

function ScoreGauge({ label, score, color }: { label: string; score: number; color: string }): React.ReactElement {
  const pct = score * 100;
  const r = 40, c = 2 * Math.PI * r, offset = c - (pct / 100) * c;
  return (
    <div className="flex flex-col items-center gap-2">
      <svg width="100" height="100" viewBox="0 0 100 100">
        <circle cx="50" cy="50" r={r} fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="8" />
        <circle cx="50" cy="50" r={r} fill="none" stroke={color} strokeWidth="8" strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={offset} className="score-ring" transform="rotate(-90 50 50)" />
        <text x="50" y="50" textAnchor="middle" dominantBaseline="central" fill="#f1f5f9" fontSize="16" fontWeight="700">{pct.toFixed(0)}%</text>
      </svg>
      <p className="text-xs text-slate-400">{label}</p>
    </div>
  );
}

export default function ReviewDetailPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [record, setRecord] = useState<FlaggedAttendanceResponse | null>(null);
  const [remarks, setRemarks] = useState("");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [confirmAction, setConfirmAction] = useState<"Approved" | "Rejected" | null>(null);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try { const { data } = await api.get<FlaggedAttendanceResponse>(`/teacher/attendance/${id}`); setRecord(data); }
      catch (err: unknown) { toast.error(getApiErrorMessage(err, "Failed to load record")); setRecord(null); } finally { setLoading(false); }
    }
    fetch();
  }, [id]);

  async function handleSubmit(): Promise<void> {
    if (!confirmAction) { toast.error("Please select an action"); return; }
    setSubmitting(true);
    try { await api.put(`/teacher/attendance/${id}/review`, { status: confirmAction, remarks }); toast.success(`Record ${confirmAction.toLowerCase()}`); router.push("/teacher/review"); }
    catch { toast.error("Review failed"); } finally { setSubmitting(false); setConfirmAction(null); }
  }

  if (loading) return <GlassLoader />;
  if (!record) return <div className="text-center py-20 text-slate-500">Not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Review Queue", href: "/teacher/review" }, { label: record.student_name }]} />
      <GlassPageHeader title="Review Flagged Record" description={`${record.class_name} — ${record.subject}`} />
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <GlassCard>
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-6">AI Evidence</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
              <ScoreGauge label="Face" score={record.face_score ?? 0} color="#3b82f6" />
              <ScoreGauge label="Liveness" score={record.liveness_score ?? 0} color="#10b981" />
              <ScoreGauge label="Background" score={record.background_score ?? 0} color="#8b5cf6" />
              <ScoreGauge label="Final" score={record.final_ai_score ?? 0} color={(record.final_ai_score ?? 0) >= 0.75 ? "#10b981" : "#f43f5e"} />
            </div>
          </GlassCard>
          <GlassCard>
            <div className="grid grid-cols-2 gap-4">
              <div><p className="text-xs text-slate-500">Student</p><p className="text-sm text-slate-200">{record.student_name}</p></div>
              <div><p className="text-xs text-slate-500">Enrollment</p><p className="text-sm text-slate-200">{record.enrollment_number}</p></div>
              <div><p className="text-xs text-slate-500">GPS</p><p className="text-xs font-mono text-slate-400">{record.gps_latitude?.toFixed(4) ?? "N/A"}, {record.gps_longitude?.toFixed(4) ?? "N/A"}</p></div>
              <div><p className="text-xs text-slate-500">Date</p><p className="text-sm text-slate-400">{new Date(record.created_at).toLocaleString()}</p></div>
            </div>
          </GlassCard>
          {record.student_note && (
            <GlassCard>
              <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3 flex items-center gap-2">
                <MessageSquare size={16} /> Student Note
              </h3>
              <p className="text-sm text-slate-300 bg-white/[0.03] p-4 rounded-xl border border-white/5 italic">
                &ldquo;{record.student_note}&rdquo;
              </p>
            </GlassCard>
          )}
        </div>
        <GlassCard>
          <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Decision</h3>
          <div className="space-y-4">
            <GlassTextarea label="Remarks" placeholder="Justification..." value={remarks} onChange={(e) => setRemarks(e.target.value)} />
            <GlassButton variant="primary" className="w-full" icon={<CheckCircle2 size={16} />} onClick={() => setConfirmAction("Approved")}>Approve</GlassButton>
            <GlassButton variant="danger" className="w-full" icon={<XCircle size={16} />} onClick={() => setConfirmAction("Rejected")}>Reject</GlassButton>
          </div>
        </GlassCard>
      </div>
      <GlassConfirmDialog isOpen={!!confirmAction} title={confirmAction === "Approved" ? "Approve" : "Reject"}
        message={`Mark as ${confirmAction === "Approved" ? "Present" : "Absent"}?`} confirmLabel={confirmAction || "Confirm"}
        variant={confirmAction === "Rejected" ? "danger" : "primary"} onConfirm={handleSubmit} onCancel={() => setConfirmAction(null)} loading={submitting} />
    </div>
  );
}
