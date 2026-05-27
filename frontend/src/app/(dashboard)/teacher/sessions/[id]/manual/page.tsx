"use client";

import React, { useEffect, useState, useCallback, useRef, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import { Search, Users, AlertCircle, Check, X } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassButton from "@/components/ui/GlassButton";
import GlassInput from "@/components/ui/GlassInput";
import GlassLoader from "@/components/ui/GlassLoader";
import type { SessionAttendanceResponse, BulkMarkRequest } from "@/types";

type AttendanceStatus = "Present" | "Absent";

export default function ManualAttendancePage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [roster, setRoster] = useState<SessionAttendanceResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [statusMap, setStatusMap] = useState<Map<string, AttendanceStatus>>(new Map());
  
  // Keyboard navigation states
  const [focusedIndex, setFocusedIndex] = useState<number>(0);
  const itemRefs = useRef<Map<string, HTMLDivElement>>(new Map());

  const fetchRoster = useCallback(async (): Promise<void> => {
    try {
      setLoading(true);
      const { data } = await api.get<SessionAttendanceResponse>(
        `/teacher/sessions/${id}/attendance`
      );
      setRoster(data);
      
      const initMap = new Map<string, AttendanceStatus>();
      data.roster.forEach((s) => {
        const isPresent = s.status === "Present" || s.status === "Flagged" || s.status === "Approved";
        initMap.set(s.student_id, isPresent ? "Present" : "Absent");
      });
      setStatusMap(initMap);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Could not load session roster"));
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    void (async () => {
      await fetchRoster();
    })();
  }, [fetchRoster]);

  const toggleStatus = useCallback((studentId: string): void => {
    setStatusMap((prev) => {
      const next = new Map(prev);
      const current = prev.get(studentId) ?? "Absent";
      next.set(studentId, current === "Present" ? "Absent" : "Present");
      return next;
    });
  }, []);

  function handleMarkAll(status: AttendanceStatus): void {
    if (!roster) return;
    setStatusMap((prev) => {
      const next = new Map(prev);
      roster.roster.forEach((s) => {
        next.set(s.student_id, status);
      });
      return next;
    });
    toast.success(`Marked all students as ${status}`);
  }

  function handleReset(): void {
    if (!roster) return;
    const next = new Map<string, AttendanceStatus>();
    roster.roster.forEach((s) => {
      const isPresent = s.status === "Present" || s.status === "Flagged" || s.status === "Approved";
      next.set(s.student_id, isPresent ? "Present" : "Absent");
    });
    setStatusMap(next);
    toast("Reset to original attendance status", { icon: "🔄" });
  }

  async function handleSubmit(): Promise<void> {
    setSubmitting(true);
    try {
      const records = Array.from(statusMap.entries()).map(([student_id, status]) => ({
        student_id,
        status,
      }));
      const payload: BulkMarkRequest = { records };
      await api.post(`/teacher/sessions/${id}/mark-bulk`, payload);
      toast.success("Attendance override applied successfully");
      router.push(`/teacher/sessions/${id}/roster`);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to submit attendance"));
    } finally {
      setSubmitting(false);
    }
  }

  const totalCount = roster ? roster.roster.length : 0;
  const presentCount = Array.from(statusMap.values()).filter((s) => s === "Present").length;
  const absentCount = totalCount - presentCount;
  const presentPercent = totalCount > 0 ? Math.round((presentCount / totalCount) * 100) : 0;

  // SVG ring logic
  const radius = 32;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (presentPercent / 100) * circumference;

  const filteredStudents = useMemo(() => {
    return roster
      ? roster.roster.filter(
          (s) =>
            s.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            s.enrollment_number.toLowerCase().includes(searchQuery.toLowerCase())
        )
      : [];
  }, [roster, searchQuery]);

  // Clamp focused index
  useEffect(() => {
    const timer = setTimeout(() => {
      setFocusedIndex((prev) => {
        if (filteredStudents.length === 0) return 0;
        return Math.min(prev, filteredStudents.length - 1);
      });
    }, 0);
    return () => clearTimeout(timer);
  }, [filteredStudents]);

  // Scroll focused item
  useEffect(() => {
    if (filteredStudents.length === 0) return;
    const focusedStudent = filteredStudents[focusedIndex];
    if (focusedStudent) {
      const itemEl = itemRefs.current.get(focusedStudent.student_id);
      itemEl?.scrollIntoView({ block: "nearest", behavior: "smooth" });
    }
  }, [focusedIndex, filteredStudents]);

  // Keyboard controls
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (
        document.activeElement?.tagName === "INPUT" ||
        document.activeElement?.tagName === "TEXTAREA"
      ) {
        return;
      }

      if (filteredStudents.length === 0) return;

      if (e.key === "ArrowDown") {
        e.preventDefault();
        setFocusedIndex((prev) => Math.min(prev + 1, filteredStudents.length - 1));
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setFocusedIndex((prev) => Math.max(prev - 1, 0));
      } else if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        const targetStudent = filteredStudents[focusedIndex];
        if (targetStudent) {
          toggleStatus(targetStudent.student_id);
        }
      }
    },
    [filteredStudents, focusedIndex, toggleStatus]
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [handleKeyDown]);

  if (loading) return <GlassLoader text="Loading session roster..." />;
  if (!roster) return <div className="text-center py-20 text-slate-500 font-medium">Session not found</div>;

  return (
    <div className="animate-fade-in-up pb-12">
      <GlassBreadcrumb
        items={[
          { label: "Sessions", href: "/teacher/sessions" },
          { label: roster.class_name, href: `/teacher/sessions/${id}/roster` },
          { label: "Manual Entry" },
        ]}
      />
      <GlassPageHeader
        title={`Manual Override — ${roster.class_name}`}
        description="A split-pane dashboard built for fast, keyboard-driven manual overrides."
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start mt-4">
        {/* Left Control Pane (Unified & Compact) */}
        <div className="space-y-4 lg:sticky lg:top-4">
          <GlassCard className="p-5 space-y-5">
            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider text-center">
              Roster Health
            </h3>
            
            {/* Radial SVG Widget */}
            <div className="relative w-24 h-24 flex items-center justify-center mx-auto">
              <svg className="absolute w-full h-full transform -rotate-90" viewBox="0 0 80 80">
                {/* Background Ring */}
                <circle
                  cx="40"
                  cy="40"
                  r={radius}
                  className="stroke-white/5 fill-none"
                  strokeWidth="5"
                />
                {/* Foreground Active Ring */}
                <circle
                  cx="40"
                  cy="40"
                  r={radius}
                  className="stroke-emerald-500 fill-none transition-all duration-500 ease-out"
                  strokeWidth="5"
                  strokeDasharray={circumference}
                  strokeDashoffset={strokeDashoffset}
                  strokeLinecap="round"
                />
              </svg>
              <div className="text-center">
                <span className="text-xl font-black text-slate-100">{presentPercent}%</span>
                <p className="text-[9px] text-slate-500 font-semibold uppercase">Present</p>
              </div>
            </div>

            {/* Health Roster Stats */}
            <div className="grid grid-cols-2 gap-2 border-t border-white/5 pt-3.5 text-xs">
              <div className="text-center border-r border-white/5">
                <span className="text-slate-400 block mb-0.5 text-[10px]">Present</span>
                <span className="text-sm font-bold text-emerald-400">{presentCount}</span>
              </div>
              <div className="text-center">
                <span className="text-slate-400 block mb-0.5 text-[10px]">Absent</span>
                <span className="text-sm font-bold text-rose-400">{absentCount}</span>
              </div>
            </div>

            {/* Search Input & Action Row */}
            <div className="space-y-3 pt-3.5 border-t border-white/5">
              <div className="relative w-full">
                <GlassInput
                  placeholder="Type / to search..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9 text-xs py-2"
                />
                <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
              </div>

              <div className="flex gap-1.5 justify-center">
                <GlassButton
                  variant="ghost"
                  size="sm"
                  className="flex-1 text-[10px] px-1 py-1.5 font-bold"
                  onClick={() => handleMarkAll("Present")}
                >
                  All Present
                </GlassButton>
                <GlassButton
                  variant="ghost"
                  size="sm"
                  className="flex-1 text-[10px] px-1 py-1.5 font-bold"
                  onClick={() => handleMarkAll("Absent")}
                >
                  All Absent
                </GlassButton>
                <GlassButton
                  variant="ghost"
                  size="sm"
                  className="flex-1 text-[10px] px-1 py-1.5 font-bold"
                  onClick={handleReset}
                >
                  Reset
                </GlassButton>
              </div>
            </div>
          </GlassCard>

          <GlassCard className="p-4 space-y-2">
            <GlassButton
              variant="primary"
              className="w-full py-2.5 font-semibold text-xs shadow-lg shadow-emerald-500/10"
              loading={submitting}
              onClick={() => void handleSubmit()}
            >
              Commit Changes
            </GlassButton>
            <GlassButton
              variant="ghost"
              className="w-full py-2 text-xs"
              disabled={submitting}
              onClick={() => router.push(`/teacher/sessions/${id}/roster`)}
            >
              Cancel
            </GlassButton>
          </GlassCard>
        </div>

        {/* Right Roster Pane */}
        <div className="lg:col-span-2">
          <GlassCard padding="none" className="overflow-hidden border border-white/5">
            <div className="p-4 border-b border-white/5 bg-white/[0.01] flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Users size={16} className="text-indigo-400" />
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">
                  Students ({filteredStudents.length} shown)
                </span>
              </div>
              <span className="text-[10px] text-slate-500 hidden sm:inline-block">
                Use [↑ / ↓] keys, [Space / Enter] to toggle
              </span>
            </div>

            {filteredStudents.length === 0 ? (
              <div className="flex flex-col items-center py-20 gap-3 text-center">
                <AlertCircle size={44} className="text-slate-600" />
                <h4 className="text-slate-300 font-semibold">No students matched search</h4>
                <p className="text-xs text-slate-500 max-w-xs">
                  Adjust search criteria or press Escape to clear search query.
                </p>
              </div>
            ) : (
              <div className="max-h-[620px] overflow-y-auto divide-y divide-white/5 scrollbar-thin scrollbar-thumb-white/10 scrollbar-track-transparent">
                {filteredStudents.map((student, idx) => {
                  const currentStatus = statusMap.get(student.student_id) ?? "Absent";
                  const isPresent = currentStatus === "Present";
                  const isFocused = idx === focusedIndex;

                  return (
                    <div
                      key={student.student_id}
                      ref={(el) => {
                        if (el) {
                          itemRefs.current.set(student.student_id, el);
                        } else {
                          itemRefs.current.delete(student.student_id);
                        }
                      }}
                      onClick={() => {
                        setFocusedIndex(idx);
                        toggleStatus(student.student_id);
                      }}
                      className={`flex items-center justify-between p-3.5 cursor-pointer select-none transition-all duration-200 active:scale-[0.99] border-l-4 relative ${
                        isPresent
                          ? "bg-emerald-500/[0.02] border-l-emerald-500/70 hover:bg-emerald-500/[0.05]"
                          : "bg-rose-500/[0.02] border-l-rose-500/70 hover:bg-rose-500/[0.05]"
                      } ${isFocused ? "outline outline-2 outline-indigo-500/50 z-10 shadow-lg shadow-indigo-950/20" : ""}`}
                    >
                      {/* Name and Enrollment Number placement */}
                      <div className="flex items-center gap-3.5 min-w-0">
                        <span className="font-mono text-xs font-semibold text-indigo-300 bg-indigo-500/10 border border-indigo-500/20 px-2.5 py-1 rounded-lg">
                          {student.enrollment_number}
                        </span>
                        <span className="font-medium text-slate-200 group-hover:text-white transition-colors text-sm truncate">
                          {student.full_name}
                        </span>
                      </div>

                      {/* Override status badge */}
                      <div>
                        {isPresent ? (
                          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 shadow-sm w-24 justify-center">
                            <Check size={11} strokeWidth={3} />
                            Present
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/20 shadow-sm w-24 justify-center">
                            <X size={11} strokeWidth={3} />
                            Absent
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </GlassCard>
        </div>
      </div>
    </div>
  );
}
