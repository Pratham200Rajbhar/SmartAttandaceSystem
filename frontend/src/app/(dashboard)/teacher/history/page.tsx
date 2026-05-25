"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Eye, Calendar, Search, SlidersHorizontal, Trash2 } from "lucide-react";
import api from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassBadge from "@/components/ui/GlassBadge";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import GlassSelect from "@/components/ui/GlassSelect";

interface SessionLogItem {
  id: string;
  academicClassId: string;
  class_name: string;
  subject: string;
  startTime: string;
  endTime: string;
  isActive: boolean;
}

interface AcademicClass {
  id: string;
  name: string;
  subject: string;
}

export default function HistoryPage(): React.ReactElement {
  const router = useRouter();
  const [sessions, setSessions] = useState<SessionLogItem[]>([]);
  const [classes, setClasses] = useState<AcademicClass[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedClass, setSelectedClass] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [dateFilter, setDateFilter] = useState("");

  useEffect(() => {
    async function initPage(): Promise<void> {
      try {
        const [sessionsRes, classesRes] = await Promise.all([
          api.get<SessionLogItem[]>("/teacher/sessions/all"),
          api.get<AcademicClass[]>("/teacher/my-classes")
        ]);
        setSessions(sessionsRes.data);
        setClasses(classesRes.data);
      } catch {
        
      } finally {
        setLoading(false);
      }
    }
    void initPage();
  }, []);

  function handleResetFilters(): void {
    setSelectedClass("all");
    setStatusFilter("all");
    setSearchTerm("");
    setDateFilter("");
  }

  const filteredSessions = sessions.filter((session) => {
    
    if (selectedClass !== "all" && session.academicClassId !== selectedClass) {
      return false;
    }

    if (statusFilter === "active" && !session.isActive) return false;
    if (statusFilter === "closed" && session.isActive) return false;

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      const matchesName = session.class_name.toLowerCase().includes(term);
      const matchesSubject = session.subject.toLowerCase().includes(term);
      const matchesId = session.id.toLowerCase().includes(term);
      if (!matchesName && !matchesSubject && !matchesId) return false;
    }

    if (dateFilter) {
      const sessionDate = new Date(session.startTime).toDateString();
      const filterDate = new Date(dateFilter).toDateString();
      if (sessionDate !== filterDate) return false;
    }

    return true;
  });

  if (loading) return <GlassLoader text="Loading session history..." />;

  const columns: TableColumn<SessionLogItem & Record<string, unknown>>[] = [
    {
      key: "class_name",
      header: "Class Name",
      sortable: true,
      render: (row) => (
        <div>
          <p className="font-semibold text-slate-200">{String(row.class_name)}</p>
          <p className="text-[11px] text-slate-500 font-mono">ID: {row.id.slice(0, 8)}...</p>
        </div>
      ),
    },
    { key: "subject", header: "Subject", sortable: true },
    {
      key: "startTime",
      header: "Session Window",
      render: (row) => (
        <div className="flex flex-col gap-0.5 text-xs text-slate-300">
          <span className="flex items-center gap-1.5 text-slate-400 font-medium">
            <Calendar size={12} />
            {new Date(String(row.startTime)).toLocaleDateString()}
          </span>
          <span className="text-[11px] text-slate-500">
            {new Date(String(row.startTime)).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })} – {new Date(String(row.endTime)).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })}
          </span>
        </div>
      ),
    },
    {
      key: "isActive",
      header: "Status",
      render: (row) => (
        <GlassBadge variant={row.isActive ? "success" : "neutral"}>
          {row.isActive ? "Active" : "Closed"}
        </GlassBadge>
      ),
    },
    {
      key: "actions",
      header: "Action",
      render: (row) => (
        <button
          onClick={() => router.push(`/teacher/sessions/${row.id}/roster`)}
          className="glass-btn glass-btn-ghost glass-btn-sm flex items-center gap-1.5 text-[12px]"
        >
          <Eye size={13} /> View Roster
        </button>
      ),
    },
  ];

  return (
    <div className="animate-fade-in-up">
      <GlassPageHeader
        title="Attendance Session Logs"
        description="Historical archives and final student rosters of all closed classes"
      />

      {}
      <div className="p-5 mb-6 rounded-2xl bg-white/[0.02] border border-white/5 shadow-inner">
        <div className="flex items-center gap-2 mb-4 text-xs font-semibold text-slate-400 uppercase tracking-widest">
          <SlidersHorizontal size={14} className="text-slate-300" />
          Filter Logs & Rosters
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 items-end">
          {}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-semibold text-slate-400">Search Logs</label>
            <div className="relative flex items-center">
              <Search className="absolute left-4 text-slate-500 pointer-events-none" size={16} />
              <input
                type="text"
                placeholder="Search class, subject or ID..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="glass-input glass-input-with-icon pr-4 py-3 w-full text-sm text-slate-200 outline-none rounded-xl border border-white/10 placeholder-slate-500 focus:border-white/10/50"
              />
            </div>
          </div>

          {}
          <div className="flex flex-col gap-1.5">
            <GlassSelect
              label="Class Filter"
              options={[
                { value: "all", label: "All Assigned Classes" },
                ...classes.map((c) => ({ value: c.id, label: `${c.name} — ${c.subject}` }))
              ]}
              value={selectedClass}
              onChange={setSelectedClass}
            />
          </div>

          {}
          <div className="flex flex-col gap-1.5">
            <GlassSelect
              label="Session State"
              options={[
                { value: "all", label: "All States" },
                { value: "closed", label: "Closed Sessions Only" },
                { value: "active", label: "Active Live Sessions" }
              ]}
              value={statusFilter}
              onChange={setStatusFilter}
            />
          </div>

          {}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-semibold text-slate-400">Filter By Date</label>
            <div className="relative flex items-center">
              <Calendar className="absolute left-4 text-slate-500 pointer-events-none" size={16} />
              <input
                type="date"
                value={dateFilter}
                onChange={(e) => setDateFilter(e.target.value)}
                className="glass-input glass-input-with-icon pr-4 py-3 w-full text-sm text-slate-200 outline-none rounded-xl border border-white/10 placeholder-slate-500 focus:border-white/10/50 block"
              />
            </div>
          </div>
        </div>

        {}
        {(selectedClass !== "all" || statusFilter !== "all" || searchTerm || dateFilter) && (
          <div className="mt-4 flex justify-end">
            <button
              onClick={handleResetFilters}
              className="glass-btn glass-btn-ghost glass-btn-sm text-slate-300 flex items-center gap-1.5 hover:bg-white/5 text-xs"
            >
              <Trash2 size={13} /> Clear Active Filters
            </button>
          </div>
        )}
      </div>

      {}
      {filteredSessions.length > 0 ? (
        <GlassTable
          columns={columns}
          data={filteredSessions as (SessionLogItem & Record<string, unknown>)[]}
          emptyMessage="No matching sessions found for current filters"
          pageSize={10}
        />
      ) : (
        <div className="p-8 text-center rounded-2xl bg-white/[0.01] border border-white/5">
          <GlassEmptyState
            title="No Sessions Match Filters"
            message="Try loosening your search terms or selecting a different class dropdown option."
          />
          {(selectedClass !== "all" || statusFilter !== "all" || searchTerm || dateFilter) && (
            <button
              onClick={handleResetFilters}
              className="glass-btn glass-btn-primary mt-4 text-xs px-4 py-2"
            >
              Reset Filters
            </button>
          )}
        </div>
      )}
    </div>
  );
}
