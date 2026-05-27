"use client";

import React, { useEffect, useState } from "react";
import { BookOpen, Radio, ClipboardCheck, ArrowUpRight, CheckCircle2, AlertCircle } from "lucide-react";
import Link from "next/link";
import api from "@/lib/api";
import GlassStatCard from "@/components/ui/GlassStatCard";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassCard from "@/components/ui/GlassCard";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassBadge from "@/components/ui/GlassBadge";
import toast from "react-hot-toast";
import { getApiErrorMessage } from "@/lib/api";
import type { 
  AcademicClassWithGeofence, 
  SessionWithClassResponse, 
  FlaggedAttendanceResponse 
} from "@/types";

export default function TeacherDashboardPage(): React.ReactElement {
  const [loading, setLoading] = useState(true);
  const [classes, setClasses] = useState<AcademicClassWithGeofence[]>([]);
  const [sessions, setSessions] = useState<SessionWithClassResponse[]>([]);
  const [flagged, setFlagged] = useState<FlaggedAttendanceResponse[]>([]);

  useEffect(() => {
    async function fetchData(): Promise<void> {
      try {
        const [clsRes, sessRes, flagRes] = await Promise.all([
          api.get<AcademicClassWithGeofence[]>("/teacher/my-classes"),
          api.get<SessionWithClassResponse[]>("/teacher/sessions/all"),
          api.get<FlaggedAttendanceResponse[]>("/teacher/attendance/flagged")
        ]);
        setClasses(clsRes.data);
        setSessions(sessRes.data);
        setFlagged(flagRes.data);
      } catch (err: unknown) {
        toast.error(getApiErrorMessage(err, "Failed to load dashboard"));
      } finally {
        setLoading(false);
      }
    }
    void fetchData();
  }, []);

  if (loading) return <GlassLoader text="Loading dashboard..." />;

  const activeSessions = sessions.filter(s => s.isActive);
  const completedSessions = sessions.filter(s => !s.isActive);

  const quickActions = [
    { label: "View My Classes", href: "/teacher/classes", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
    { label: "Start New Session", href: "/teacher/sessions", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
    { label: "Review Flagged Attendance", href: "/teacher/review", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
    { label: "View Analytics", href: "/teacher/analytics", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
  ];

  return (
    <div className="animate-fade-in-up space-y-8">
      <GlassPageHeader title="Teacher Overview" description="Your classes, active sessions, and review queue at a glance" />

      {}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <GlassStatCard
          icon={<BookOpen size={22} />}
          label="My Classes"
          value={classes.length}
          accentColor="blue"
          trend="Enrolled"
          trendUp
        />
        <GlassStatCard
          icon={<Radio size={22} />}
          label="Active Sessions"
          value={activeSessions.length}
          accentColor="emerald"
          trend={completedSessions.length > 0 ? `${completedSessions.length} Completed` : "Ready"}
          trendUp
        />
        <GlassStatCard
          icon={<ClipboardCheck size={22} />}
          label="Pending Reviews"
          value={flagged.length}
          accentColor={flagged.length > 0 ? "rose" : "purple"}
          trend={flagged.length > 0 ? "Action Required" : "All Clear"}
          trendUp={flagged.length === 0}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {}
        <GlassCard className="!p-0 overflow-hidden relative lg:col-span-2">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 via-indigo-500 to-purple-500"></div>
          <div className="p-6 border-b border-white/5 bg-white/[0.01] flex items-center justify-between">
            <h3 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">Quick Operations</h3>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-widest">Shortcuts</span>
          </div>
          <div className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-4">
            {quickActions.map((action) => (
              <Link
                key={action.href}
                href={action.href}
                className={`flex items-center justify-between p-4 rounded-xl bg-gradient-to-tr border shadow-lg group transition-all duration-300 ${action.color}`}
              >
                <span className="font-bold text-sm tracking-wide">{action.label}</span>
                <ArrowUpRight size={16} className="opacity-60 group-hover:opacity-100 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
              </Link>
            ))}
          </div>
        </GlassCard>

        {}
        <GlassCard className="!p-0 overflow-hidden relative">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-emerald-400 to-cyan-500"></div>
          <div className="p-6 border-b border-white/5 bg-white/[0.01] flex items-center justify-between">
            <h3 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">System Status</h3>
            <GlassBadge variant="success" className="animate-pulse">Live</GlassBadge>
          </div>
          <div className="p-6 space-y-4">
            <div className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.01] border border-white/5">
              <div className="p-2 rounded-lg bg-white/5 border border-white/10">
                <CheckCircle2 size={16} className="text-slate-300" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-bold text-slate-200 truncate leading-normal">Classes Configured</p>
                <p className="text-[10px] text-slate-500 font-semibold tracking-wide mt-0.5">Ready for sessions</p>
              </div>
              <GlassBadge variant="success" className="py-0.5 px-2 text-[10px]">{classes.length}</GlassBadge>
            </div>
            
            <div className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.01] border border-white/5">
              <div className={`p-2 rounded-lg border ${flagged.length > 0 ? "bg-white/5 border-white/10" : "bg-white/5 border-white/10"}`}>
                <AlertCircle size={16} className={flagged.length > 0 ? "text-slate-300" : "text-slate-300"} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-bold text-slate-200 truncate leading-normal">Review Queue</p>
                <p className="text-[10px] text-slate-500 font-semibold tracking-wide mt-0.5">Requires attention</p>
              </div>
              <GlassBadge variant={flagged.length > 0 ? "danger" : "neutral"} className="py-0.5 px-2 text-[10px]">{flagged.length}</GlassBadge>
            </div>
          </div>
        </GlassCard>
      </div>

      {}
      <GlassCard className="!p-0 overflow-hidden relative">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-fuchsia-500 to-pink-500"></div>
        <div className="p-6 border-b border-white/5 bg-white/[0.01] flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">Recent Sessions</h3>
            <p className="text-xs text-slate-500 mt-0.5">Your recently active attendance sessions</p>
          </div>
        </div>
        
        <div className="p-6 divide-y divide-white/5">
          {sessions.slice(0, 5).map((session, i) => (
            <div key={i} className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 py-4 first:pt-0 last:pb-0">
              <div className="flex items-start gap-3">
                <div className={`w-1.5 h-1.5 rounded-full mt-2 shrink-0 ${
                  session.isActive ? "bg-white/5" : "bg-slate-500"
                }`} />
                <div>
                  <p className="text-sm font-bold text-slate-200">{session.class_name}</p>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {session.isActive ? "Session is currently active" : "Session completed"}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <GlassBadge variant={session.isActive ? "success" : "neutral"} className="text-[10px]">
                  {session.isActive ? "ACTIVE" : "COMPLETED"}
                </GlassBadge>
                <p className="text-[10px] font-semibold text-slate-600 mt-2 tracking-wide">
                  {new Date(session.startTime).toLocaleString()}
                </p>
              </div>
            </div>
          ))}
          {sessions.length === 0 && (
            <div className="py-8 text-center text-slate-500 text-sm">No sessions recorded yet.</div>
          )}
        </div>
      </GlassCard>
    </div>
  );
}
