"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Eye } from "lucide-react";
import api from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassBadge from "@/components/ui/GlassBadge";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import type { FlaggedAttendanceResponse } from "@/types";

import GlassSearch from "@/components/ui/GlassSearch";
import GlassSelect from "@/components/ui/GlassSelect";

import GlassCard from "@/components/ui/GlassCard";

export default function ReviewQueuePage(): React.ReactElement {
  const router = useRouter();
  const [records, setRecords] = useState<FlaggedAttendanceResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterClass, setFilterClass] = useState("all");

  useEffect(() => {
    async function fetch(): Promise<void> {
      try { const { data } = await api.get<FlaggedAttendanceResponse[]>("/teacher/attendance/flagged"); setRecords(data); }
      catch { setRecords([]); }
      finally { setLoading(false); }
    }
    fetch();
  }, []);

  if (loading) return <GlassLoader text="Loading flagged records..." />;
  if (records.length === 0) return <><GlassPageHeader title="Review Queue" /><GlassEmptyState title="All Clear" message="No flagged records require review." /></>;

  const columns: TableColumn<FlaggedAttendanceResponse & Record<string, unknown>>[] = [
    { key: "enrollment_number", header: "Enrollment #" },
    { key: "student_name", header: "Student", sortable: true },
    { key: "class_name", header: "Class" },
    { key: "final_ai_score", header: "AI Score", render: (r) => {
      const score = Number(r.final_ai_score);
      return <span className={`font-mono text-sm ${score < 0.5 ? "text-slate-300" : "text-slate-300"}`}>{(score * 100).toFixed(1)}%</span>;
    }},
    { key: "created_at", header: "Date", render: (r) => <span className="text-xs text-slate-400">{new Date(String(r.created_at)).toLocaleDateString()}</span> },
    { key: "actions", header: "", render: (row) => (
      <button onClick={() => router.push(`/teacher/review/${row.id}`)} className="glass-btn glass-btn-ghost glass-btn-sm"><Eye size={14} /> Review</button>
    )},
  ];

  const uniqueClasses = Array.from(new Set(records.map(r => r.class_name)));
  const classOptions = [
    { value: "all", label: "All Classes" },
    ...uniqueClasses.map(c => ({ value: c, label: c }))
  ];

  const filteredRecords = records.filter(r => {
    const matchesSearch = r.student_name.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          r.enrollment_number.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesClass = filterClass === "all" || r.class_name === filterClass;
    return matchesSearch && matchesClass;
  });

  return (
    <div className="animate-fade-in-up">
      <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 mb-6">
        <GlassPageHeader title="Review Queue" description={`${records.length} flagged records awaiting review`} />
        <GlassBadge variant="warning" className="mt-2">Requires Teacher Decision</GlassBadge>
      </div>
      
      <GlassCard padding="sm" className="mb-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <GlassSearch placeholder="Search by name or enrollment..." onSearch={setSearchTerm} />
          </div>
          <div className="w-full sm:w-64">
            <GlassSelect 
              options={classOptions} 
              value={filterClass} 
              onChange={setFilterClass} 
              placeholder="Filter by Class"
            />
          </div>
        </div>
      </GlassCard>

      <GlassTable columns={columns} data={filteredRecords as (FlaggedAttendanceResponse & Record<string, unknown>)[]} emptyMessage="No records match your search." />
    </div>
  );
}
