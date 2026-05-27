"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Radio, Play, Square, ClipboardList, BookOpen } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassCard from "@/components/ui/GlassCard";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassInput from "@/components/ui/GlassInput";
import GlassButton from "@/components/ui/GlassButton";
import GlassBadge from "@/components/ui/GlassBadge";
import GlassLoader from "@/components/ui/GlassLoader";
import type { AcademicClassWithGeofence, SessionResponse, SessionWithClassResponse } from "@/types";

export default function SessionsPage(): React.ReactElement {
  const router = useRouter();
  const [classes, setClasses] = useState<AcademicClassWithGeofence[]>([]);
  const [selectedClass, setSelectedClass] = useState("");
  const [duration, setDuration] = useState("10");
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [activeSessions, setActiveSessions] = useState<SessionResponse[]>([]);
  const [pastSessions, setPastSessions] = useState<SessionWithClassResponse[]>([]);
  const [classFilter, setClassFilter] = useState("");

  const fetchData = useCallback(async (): Promise<void> => {
    try {
      const [classesRes, allSessionsRes] = await Promise.all([
        api.get<AcademicClassWithGeofence[]>("/teacher/my-classes"),
        api.get<SessionWithClassResponse[]>("/teacher/sessions/all"),
      ]);
      setClasses(classesRes.data);
      
      const now = new Date();
      setActiveSessions(
        allSessionsRes.data
          .filter((s) => s.isActive && new Date(s.endTime) > now)
          .map(({ id, academicClassId, startTime, endTime, isActive }) => ({
            id, academicClassId, startTime, endTime, isActive,
          }))
      );
      setPastSessions(
        allSessionsRes.data.filter((s) => !s.isActive || new Date(s.endTime) <= now)
      );
    } catch {
      setClasses([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      await fetchData();
      if (typeof window !== "undefined") {
        const params = new URLSearchParams(window.location.search);
        const classId = params.get("classId");
        if (classId) {
          setClassFilter(classId);
          setSelectedClass(classId);
        }
      }
    })();
  }, [fetchData]);

  useEffect(() => {
    const timer = setInterval(() => {
      const now = new Date();
      const hasExpired = activeSessions.some((s) => new Date(s.endTime) <= now);
      if (hasExpired) {
        void fetchData();
      }
    }, 5000);
    return () => clearInterval(timer);
  }, [activeSessions, fetchData]);

  const handleClearFilter = useCallback((): void => {
    setClassFilter("");
    router.replace("/teacher/sessions");
  }, [router]);

  async function handleStart(): Promise<void> {
    if (!selectedClass) { toast.error("Select a class first"); return; }
    const mins = parseInt(duration, 10);
    if (isNaN(mins) || mins < 1 || mins > 180) { toast.error("Duration must be 1–180 minutes"); return; }
    setStarting(true);
    try {
      const { data } = await api.post<SessionResponse>("/teacher/sessions/start", {
        academic_class_id: selectedClass,
        duration_minutes: mins,
      });
      setActiveSessions((prev) => [...prev, data]);
      toast.success("Session started!");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to start session"));
    } finally {
      setStarting(false);
    }
  }

  async function handleStop(sessionId: string): Promise<void> {
    try {
      await api.post(`/teacher/sessions/${sessionId}/stop`);
      setActiveSessions((prev) => prev.filter((s) => s.id !== sessionId));
      toast.success("Session stopped");
      
      await fetchData();
    } catch {
      toast.error("Failed to stop session");
    }
  }

  if (loading) return <GlassLoader text="Loading sessions..." />;

  const filteredActiveSessions = classFilter
    ? activeSessions.filter((s) => s.academicClassId === classFilter)
    : activeSessions;

  const filteredPastSessions = classFilter
    ? pastSessions.filter((s) => s.academicClassId === classFilter)
    : pastSessions;

  const filteredClass = classes.find((c) => c.id === classFilter);
  const filterLabel = filteredClass ? `${filteredClass.name} — ${filteredClass.subject}` : "Selected Class";

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Teacher", href: "/teacher/classes" }, { label: "Sessions" }]} />
      <GlassPageHeader title="Session Control" description="Start, manage, and review attendance sessions" />

      {classFilter && (
        <div className="glass-panel-static p-4 mb-6 flex items-center justify-between animate-fade-in text-sm border-indigo-500/20 bg-indigo-500/[0.02] rounded-xl">
          <div className="flex items-center gap-2 text-indigo-300">
            <span className="w-2 h-2 rounded-full bg-indigo-400 animate-pulse" />
            Showing sessions for class: <span className="font-semibold text-slate-200">{filterLabel}</span>
          </div>
          <button 
            onClick={handleClearFilter}
            className="text-xs text-slate-400 hover:text-white hover:underline transition-colors font-medium"
          >
            Clear Filter
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {}
        <GlassCard>
          <div className="flex items-center gap-3 mb-6">
            <div className="p-2.5 rounded-xl bg-white/5">
              <Radio size={20} className="text-slate-300" />
            </div>
            <h3 className="text-lg font-semibold text-slate-200">Start New Session</h3>
          </div>
          <div className="space-y-4">
            <GlassSelect
              label="Class"
              options={classes.map((c) => ({ value: c.id, label: `${c.name} — ${c.subject}` }))}
              value={selectedClass}
              onChange={setSelectedClass}
              placeholder="Select class..."
            />
            <GlassInput
              label="Duration (minutes)"
              type="number"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
            />
            <GlassButton
              variant="primary"
              size="lg"
              className="w-full"
              onClick={() => void handleStart()}
              loading={starting}
              icon={<Play size={18} />}
            >
              Start Session
            </GlassButton>
          </div>
        </GlassCard>

        {}
        <GlassCard>
          <h3 className="text-lg font-semibold text-slate-200 mb-4">Active Sessions</h3>
          {filteredActiveSessions.length === 0 ? (
            <p className="text-sm text-slate-500 text-center py-8">No active sessions</p>
          ) : (
            <div className="space-y-3">
              {filteredActiveSessions.map((session) => (
                <div
                  key={session.id}
                  className="glass-panel-static p-4 flex items-center justify-between"
                >
                  <div>
                    <GlassBadge variant="success">Live</GlassBadge>
                    <p className="text-xs font-mono text-slate-400 mt-1">{session.id.slice(0, 8)}...</p>
                    <p className="text-xs text-slate-500">
                      Ends: {new Date(session.endTime).toLocaleTimeString()}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <GlassButton
                      variant="ghost"
                      size="sm"
                      icon={<ClipboardList size={14} />}
                      onClick={() => router.push(`/teacher/sessions/${session.id}/roster`)}
                    >
                      Roster
                    </GlassButton>
                    <GlassButton
                      variant="ghost"
                      size="sm"
                      icon={<BookOpen size={14} />}
                      onClick={() => router.push(`/teacher/sessions/${session.id}/manual`)}
                    >
                      Manual
                    </GlassButton>
                    <GlassButton
                      variant="danger"
                      size="sm"
                      onClick={() => void handleStop(session.id)}
                      icon={<Square size={14} />}
                    >
                      Stop
                    </GlassButton>
                  </div>
                </div>
              ))}
            </div>
          )}
        </GlassCard>
      </div>

      {}
      <GlassCard>
        <h3 className="text-lg font-semibold text-slate-200 mb-4">Past Sessions</h3>
        {filteredPastSessions.length === 0 ? (
          <p className="text-sm text-slate-500 text-center py-8">No past sessions yet</p>
        ) : (
          <div className="overflow-x-auto overflow-y-auto max-h-[420px]">
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-[#080916]/95 backdrop-blur-md z-10">
                <tr className="border-b border-white/10">
                  {["Class", "Subject", "Date", "Start", "End", "Actions"].map((h) => (
                    <th
                      key={h}
                      className="text-left py-3 px-4 text-slate-400 font-medium text-xs uppercase tracking-wider sticky top-0 bg-[#080916]/95 z-10"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filteredPastSessions.map((s, idx) => (
                  <tr
                    key={s.id}
                    className={`border-b border-white/5 transition-colors ${idx % 2 === 0 ? "" : "bg-white/[0.02]"}`}
                  >
                    <td className="py-3 px-4 font-medium text-slate-200">{s.class_name}</td>
                    <td className="py-3 px-4 text-slate-400">{s.subject}</td>
                    <td className="py-3 px-4 text-slate-500 text-xs">
                      {new Date(s.startTime).toLocaleDateString()}
                    </td>
                    <td className="py-3 px-4 text-slate-500 text-xs">
                      {new Date(s.startTime).toLocaleTimeString()}
                    </td>
                    <td className="py-3 px-4 text-slate-500 text-xs">
                      {new Date(s.endTime).toLocaleTimeString()}
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex gap-2">
                        <GlassButton
                          variant="ghost"
                          size="sm"
                          icon={<Radio size={13} className="text-emerald-400 animate-pulse" />}
                          onClick={() => router.push(`/teacher/sessions/${s.id}/roster`)}
                        >
                          Live View
                        </GlassButton>
                        <GlassButton
                          variant="ghost"
                          size="sm"
                          icon={<ClipboardList size={13} />}
                          onClick={() => router.push(`/teacher/sessions/${s.id}/roster`)}
                        >
                          Roster
                        </GlassButton>
                        <GlassButton
                          variant="ghost"
                          size="sm"
                          icon={<BookOpen size={13} />}
                          onClick={() => router.push(`/teacher/sessions/${s.id}/manual`)}
                        >
                          Manual
                        </GlassButton>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </GlassCard>
    </div>
  );
}
