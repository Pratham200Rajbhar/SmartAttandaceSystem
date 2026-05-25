"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { CheckCircle2 } from "lucide-react";
import toast from "react-hot-toast";
import api from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { AbsentStudentItem, BulkMarkRequest } from "@/types";

type AttendanceStatus = "Present" | "Absent";

export default function ManualAttendancePage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [absentStudents, setAbsentStudents] = useState<AbsentStudentItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  // Map<student_id, status> — default all to Absent
  const [statusMap, setStatusMap] = useState<Map<string, AttendanceStatus>>(new Map());

  const fetchAbsentStudents = useCallback(async (): Promise<void> => {
    try {
      const { data } = await api.get<AbsentStudentItem[]>(
        `/teacher/sessions/${id}/absent-students`
      );
      setAbsentStudents(data);
      // Initialise all students as Absent
      const initMap = new Map<string, AttendanceStatus>();
      data.forEach((s) => initMap.set(s.student_id, "Absent"));
      setStatusMap(initMap);
    } catch {
      toast.error("Could not load absent students");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    void (async () => {
      await fetchAbsentStudents();
    })();
  }, [fetchAbsentStudents]);

  function toggleStatus(studentId: string): void {
    setStatusMap((prev) => {
      const next = new Map(prev);
      next.set(studentId, prev.get(studentId) === "Present" ? "Absent" : "Present");
      return next;
    });
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
      toast.success("Attendance submitted successfully");
      router.push(`/teacher/sessions/${id}/roster`);
    } catch {
      toast.error("Failed to submit attendance");
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) return <GlassLoader text="Loading absent students..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Sessions", href: "/teacher/sessions" },
          { label: "Session", href: `/teacher/sessions/${id}/roster` },
          { label: "Manual Entry" },
        ]}
      />
      <GlassPageHeader
        title="Manual Attendance Entry"
        description="Mark attendance for students not yet recorded in this session"
      />

      {absentStudents.length === 0 ? (
        /* ── Empty state ── */
        <GlassCard className="flex flex-col items-center py-16 gap-4 text-center">
          <CheckCircle2 size={52} className="text-slate-300" />
          <h2 className="text-xl font-semibold text-slate-200">All students marked</h2>
          <p className="text-slate-400 text-sm max-w-xs">
            Every student enrolled in this session has already been marked.
          </p>
          <GlassButton
            variant="ghost"
            onClick={() => router.push(`/teacher/sessions/${id}/roster`)}
          >
            Back to Roster
          </GlassButton>
        </GlassCard>
      ) : (
        <>
          {/* ── Checklist table ── */}
          <GlassCard padding="sm" className="mb-6 overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left py-3 px-4 text-slate-400 font-medium text-xs uppercase tracking-wider">
                    Enrollment #
                  </th>
                  <th className="text-left py-3 px-4 text-slate-400 font-medium text-xs uppercase tracking-wider">
                    Full Name
                  </th>
                  <th className="text-left py-3 px-4 text-slate-400 font-medium text-xs uppercase tracking-wider">
                    Email
                  </th>
                  <th className="text-center py-3 px-4 text-slate-400 font-medium text-xs uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody>
                {absentStudents.map((student, idx) => {
                  const currentStatus = statusMap.get(student.student_id) ?? "Absent";
                  const isPresent = currentStatus === "Present";
                  return (
                    <tr
                      key={student.student_id}
                      className={`border-b border-white/5 transition-colors ${idx % 2 === 0 ? "" : "bg-white/[0.02]"}`}
                    >
                      <td className="py-3 px-4 font-mono text-xs text-slate-300">
                        {student.enrollment_number}
                      </td>
                      <td className="py-3 px-4 text-slate-200 font-medium">{student.full_name}</td>
                      <td className="py-3 px-4 text-slate-400 text-xs">{student.email}</td>
                      <td className="py-3 px-4">
                        <div className="flex justify-center gap-1">
                          <button
                            onClick={() => toggleStatus(student.student_id)}
                            className={`glass-btn glass-btn-sm transition-all ${isPresent
                                ? "glass-btn-primary text-emerald-300"
                                : "glass-btn-ghost text-slate-400"
                              }`}
                          >
                            Present
                          </button>
                          <button
                            onClick={() => toggleStatus(student.student_id)}
                            className={`glass-btn glass-btn-sm transition-all ${!isPresent
                                ? "text-slate-300"
                                : "glass-btn-ghost text-slate-400"
                              }`}
                          >
                            Absent
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </GlassCard>

          {/* ── Summary + submit ── */}
          <div className="flex items-center justify-between">
            <p className="text-sm text-slate-400">
              {Array.from(statusMap.values()).filter((s) => s === "Present").length} of{" "}
              {absentStudents.length} students marked Present
            </p>
            <div className="flex gap-3">
              <GlassButton
                variant="ghost"
                onClick={() => router.push(`/teacher/sessions/${id}/roster`)}
              >
                Cancel
              </GlassButton>
              <GlassButton
                variant="primary"
                loading={submitting}
                onClick={() => void handleSubmit()}
              >
                Submit Attendance
              </GlassButton>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
