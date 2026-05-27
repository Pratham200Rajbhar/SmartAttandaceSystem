"use client";

import React, { useEffect, useState } from "react";
import toast from "react-hot-toast";
import { CheckCircle2, XCircle, ExternalLink } from "lucide-react";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import GlassCard from "@/components/ui/GlassCard";
import GlassSearch from "@/components/ui/GlassSearch";
import GlassConfirmDialog from "@/components/ui/GlassConfirmDialog";
import type { PendingLeaveItem } from "@/types";

export default function LeavesPage(): React.ReactElement {
  const [leaves, setLeaves] = useState<PendingLeaveItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedLeave, setSelectedLeave] = useState<PendingLeaveItem | null>(null);
  const [approveAction, setApproveAction] = useState<"APPROVED" | "REJECTED" | null>(null);
  const [approverNote, setApproverNote] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let mounted = true;
    async function fetchLeaves(): Promise<void> {
      try { const { data } = await api.get<PendingLeaveItem[]>("/teacher/leaves/pending"); if (mounted) setLeaves(data); }
      catch { if (mounted) setLeaves([]); }
      finally { if (mounted) setLoading(false); }
    }
    fetchLeaves();
    return () => { mounted = false; };
  }, []);

  async function handleSubmit(): Promise<void> {
    if (!selectedLeave || !approveAction) return;
    setSubmitting(true);
    try {
      await api.put(`/teacher/leaves/${selectedLeave.id}/approve`, {
        status: approveAction,
        approver_note: approverNote || undefined,
      });
      toast.success(`Leave ${approveAction === "APPROVED" ? "approved" : "rejected"}`);
      setSelectedLeave(null);
      setApproveAction(null);
      setApproverNote("");
      const { data } = await api.get<PendingLeaveItem[]>("/teacher/leaves/pending");
      setLeaves(data);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to process leave request"));
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) return <GlassLoader text="Loading leave requests..." />;

  const columns: TableColumn<PendingLeaveItem & Record<string, unknown>>[] = [
    { key: "enrollment_number", header: "Enrollment #" },
    { key: "student_name", header: "Student", sortable: true },
    { key: "start_date", header: "From", render: (r) => <span className="text-xs text-slate-400">{new Date(r.start_date).toLocaleDateString()}</span> },
    { key: "end_date", header: "To", render: (r) => <span className="text-xs text-slate-400">{new Date(r.end_date).toLocaleDateString()}</span> },
    { key: "reason", header: "Reason", render: (r) => <span className="text-xs text-slate-400 truncate max-w-[200px] block">{r.reason}</span> },
    { key: "document_url", header: "Doc", render: (r) => r.document_url ? (
      <a href={r.document_url} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:text-blue-300">
        <ExternalLink size={14} />
      </a>
    ) : <span className="text-slate-600">—</span> },
    { key: "actions", header: "", render: (row) => (
      <div className="flex gap-2">
        <button onClick={() => { setSelectedLeave(row); setApproveAction("APPROVED"); setApproverNote(""); }}
          className="glass-btn glass-btn-sm glass-btn-ghost text-emerald-400 hover:text-emerald-300">
          <CheckCircle2 size={14} /> Approve
        </button>
        <button onClick={() => { setSelectedLeave(row); setApproveAction("REJECTED"); setApproverNote(""); }}
          className="glass-btn glass-btn-sm glass-btn-ghost text-rose-400 hover:text-rose-300">
          <XCircle size={14} /> Reject
        </button>
      </div>
    )},
  ];

  const filtered = leaves.filter(r =>
    r.student_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.enrollment_number.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (leaves.length === 0) return <><GlassPageHeader title="Leave Requests" /><GlassEmptyState title="All Clear" message="No pending leave requests." /></>;

  return (
    <div className="animate-fade-in-up">
      <GlassPageHeader title="Leave Requests" description={`${leaves.length} pending leave request(s)`} />
      <GlassCard padding="sm" className="mb-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <GlassSearch placeholder="Search by name or enrollment..." onSearch={setSearchTerm} />
          </div>
        </div>
      </GlassCard>
      <GlassTable columns={columns} data={filtered as (PendingLeaveItem & Record<string, unknown>)[]} emptyMessage="No pending leaves match your search." />

      <GlassConfirmDialog
        isOpen={!!selectedLeave && !!approveAction}
        title={approveAction === "APPROVED" ? "Approve Leave" : "Reject Leave"}
        message={`${approveAction === "APPROVED" ? "Approve" : "Reject"} leave for ${selectedLeave?.student_name} (${selectedLeave?.enrollment_number})?`}
        confirmLabel={approveAction === "APPROVED" ? "Approve" : "Reject"}
        variant={approveAction === "REJECTED" ? "danger" : "primary"}
        onConfirm={handleSubmit}
        onCancel={() => { setSelectedLeave(null); setApproveAction(null); }}
        loading={submitting}
      />
    </div>
  );
}
