"use client";

import React, { useEffect, useState, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft, Printer, Search } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassBadge, { statusToBadgeVariant } from "@/components/ui/GlassBadge";
import GlassButton from "@/components/ui/GlassButton";
import GlassStatCard from "@/components/ui/GlassStatCard";
import GlassLoader from "@/components/ui/GlassLoader";
import type { SessionAttendanceResponse, StudentRosterItem } from "@/types";

export default function SessionPreviewPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [roster, setRoster] = useState<SessionAttendanceResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    async function loadData(): Promise<void> {
      try {
        const { data } = await api.get<SessionAttendanceResponse>(
          `/teacher/sessions/${id}/attendance`
        );
        setRoster(data);
      } catch (err: unknown) {
        toast.error(getApiErrorMessage(err, "Failed to load preview data"));
      } finally {
        setLoading(false);
      }
    }
    void loadData();
  }, [id]);

  const handlePrint = (): void => {
    if (typeof window !== "undefined") {
      window.print();
    }
  };

  const counts = useMemo(() => {
    if (!roster) return { present: 0, flagged: 0, absent: 0, total: 0, rate: 0 };
    const res = roster.roster.reduce(
      (acc, r) => {
        if (r.status === "Present" || r.status === "Approved") acc.present++;
        else if (r.status === "Flagged") acc.flagged++;
        else if (r.status === "Absent") acc.absent++;
        return acc;
      },
      { present: 0, flagged: 0, absent: 0 }
    );
    const total = roster.roster.length;
    const rate = total > 0 ? Math.round(((res.present + res.flagged) / total) * 100) : 0;
    return { ...res, total, rate };
  }, [roster]);

  const filteredRoster = useMemo(() => {
    if (!roster) return [];
    if (!searchTerm) return roster.roster;
    const term = searchTerm.toLowerCase();
    return roster.roster.filter(
      (r) =>
        r.full_name.toLowerCase().includes(term) ||
        r.enrollment_number.toLowerCase().includes(term) ||
        r.email.toLowerCase().includes(term)
    );
  }, [roster, searchTerm]);

  if (loading) return <GlassLoader text="Loading attendance sheet..." />;
  if (!roster) return <div className="text-center py-20 text-slate-500">Session not found</div>;

  const columns: TableColumn<StudentRosterItem & Record<string, unknown>>[] = [
    { key: "enrollment_number", header: "Enrollment #", sortable: true },
    { key: "full_name", header: "Full Name", sortable: true },
    { key: "email", header: "Email Address", sortable: true },
    {
      key: "status",
      header: "Attendance Status",
      sortable: true,
      render: (r) => (
        <GlassBadge variant={statusToBadgeVariant(String(r.status))}>
          {String(r.status)}
        </GlassBadge>
      ),
    },
    {
      key: "final_score",
      header: "AI Match Score",
      sortable: true,
      render: (r) => {
        const score = Number(r.final_score);
        if (score === 0 && r.status === "Absent") return <span className="text-slate-500">—</span>;
        return (
          <span className={`font-mono text-sm font-semibold ${score >= 0.7 ? "text-emerald-400" : score >= 0.4 ? "text-amber-400" : "text-rose-400"}`}>
            {(score * 100).toFixed(1)}%
          </span>
        );
      },
    },
    {
      key: "marked_at",
      header: "Marked Timestamp",
      sortable: true,
      render: (r) => (
        <span className="text-xs text-slate-400">
          {r.marked_at ? new Date(String(r.marked_at)).toLocaleString() : "—"}
        </span>
      ),
    },
  ];

  return (
    <div className="animate-fade-in-up print:bg-white print:text-black">
      <div className="print:hidden">
        <GlassBreadcrumb
          items={[
            { label: "History", href: "/teacher/history" },
            { label: roster.class_name },
            { label: "Attendance Sheet Preview" },
          ]}
        />
      </div>

      <GlassPageHeader
        title={`Attendance Sheet — ${roster.class_name}`}
        description="Official tabular attendance report and student records for this closed session"
        actions={
          <div className="flex gap-2 print:hidden">
            <GlassButton
              variant="secondary"
              icon={<ArrowLeft size={14} />}
              onClick={() => router.back()}
            >
              Back
            </GlassButton>
            <GlassButton
              variant="ghost"
              icon={<Printer size={14} />}
              onClick={handlePrint}
            >
              Print Report
            </GlassButton>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6 print:grid-cols-4 print:gap-2">
        <GlassStatCard icon={<span className="text-lg">👥</span>} label="Total Students" value={counts.total} accentColor="neutral" />
        <GlassStatCard icon={<span className="text-lg">✅</span>} label="Present" value={counts.present} accentColor="emerald" />
        <GlassStatCard icon={<span className="text-lg">❌</span>} label="Absent" value={counts.absent} accentColor="rose" />
        <GlassStatCard icon={<span className="text-lg">📈</span>} label="Attendance Rate" value={`${counts.rate}%`} accentColor="emerald" />
      </div>

      <div className="mb-6 flex items-center justify-between gap-4 print:hidden">
        <div className="relative flex items-center flex-1 max-w-md">
          <Search className="absolute left-4 text-slate-500 pointer-events-none" size={16} />
          <input
            type="text"
            placeholder="Search students by name, enrollment or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="glass-input glass-input-with-icon pr-4 py-3 w-full text-sm text-slate-200 outline-none rounded-xl border border-white/10 placeholder-slate-500 focus:border-white/10/50"
          />
        </div>
      </div>

      <GlassTable
        columns={columns}
        data={filteredRoster as (StudentRosterItem & Record<string, unknown>)[]}
        emptyMessage="No students found matching your search term."
        pageSize={30}
      />
    </div>
  );
}
