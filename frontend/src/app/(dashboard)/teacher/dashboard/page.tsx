"use client";

import React, { useEffect, useState } from "react";
import { 
  BookOpen, Radio, ClipboardCheck, ArrowUpRight, 
  RefreshCw, PlayCircle, Eye, Clock
} from "lucide-react";
import Link from "next/link";
import api from "@/lib/api";
import GlassStatCard from "@/components/ui/GlassStatCard";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassCard from "@/components/ui/GlassCard";
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
  const [refreshing, setRefreshing] = useState(false);
  const [classes, setClasses] = useState<AcademicClassWithGeofence[]>([]);
  const [sessions, setSessions] = useState<SessionWithClassResponse[]>([]);
  const [flagged, setFlagged] = useState<FlaggedAttendanceResponse[]>([]);
  const [greeting, setGreeting] = useState("Welcome");

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
      toast.error(getApiErrorMessage(err, "Failed to load dashboard data"));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      void fetchData();
      const hour = new Date().getHours();
      if (hour < 12) setGreeting("Good morning");
      else if (hour < 17) setGreeting("Good afternoon");
      else setGreeting("Good evening");
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchData();
  };

  if (loading) return <GlassLoader text="Loading instructor portal..." />;

  const activeSessions = sessions.filter(s => s.isActive);
  const completedSessions = sessions.filter(s => !s.isActive);

  const quickActions = [
    { label: "View My Classes", href: "/teacher/classes", detail: "Manage rosters and geofences", icon: <BookOpen size={18} className="text-emerald-400" /> },
    { label: "Start New Session", href: "/teacher/sessions", detail: "Broadcast attendance beacon", icon: <PlayCircle size={18} className="text-emerald-400" /> },
    { label: "Review Flagged", href: "/teacher/review", detail: "Resolve AI validation anomalies", icon: <ClipboardCheck size={18} className="text-emerald-400" /> },
    { label: "Attendance History", href: "/teacher/history", detail: "View past class records", icon: <Clock size={18} className="text-emerald-400" /> },
  ];

  return (
    <div className="animate-fade-in-up space-y-6 md:space-y-8">
      
      {/* Banner */}
      <div className="relative overflow-hidden rounded-2xl border border-white/[0.06] bg-gradient-to-br from-white/[0.02] to-transparent p-6 shadow-xl">
        <div className="absolute top-0 right-0 w-80 h-80 rounded-full bg-emerald-500/5 blur-3xl -z-10 pointer-events-none" />
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              <p className="text-[11px] font-bold text-emerald-400 uppercase tracking-widest">Faculty Lecture Portal</p>
            </div>
            <h1 className="text-2xl md:text-3xl font-extrabold text-slate-100 tracking-tight font-[Outfit]">{greeting}, Professor</h1>
            <p className="text-sm font-semibold text-slate-400 mt-1 max-w-2xl">
              Manage your subjects, broadcast sessions, and review attendance records.
            </p>
          </div>
          <button 
            onClick={handleRefresh}
            disabled={refreshing}
            className="self-start sm:self-center glass-btn glass-btn-secondary glass-btn-sm font-semibold flex items-center gap-2 border border-white/5 hover:border-white/20 transition-all duration-300"
          >
            <RefreshCw size={13} className={refreshing ? "animate-spin" : ""} />
            <span>{refreshing ? "Refreshing..." : "Refresh Console"}</span>
          </button>
        </div>
      </div>

      {/* Active Session Monitor (Only show if active) */}
      {activeSessions.length > 0 && (
        <div className="relative overflow-hidden rounded-2xl border border-emerald-500/25 bg-gradient-to-r from-emerald-950/20 to-transparent p-6 shadow-2xl flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-emerald-500/50 to-transparent" />
          <div className="flex items-start gap-4">
            <div className="relative p-4 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
              <span className="absolute inset-0 rounded-full border border-emerald-500/50 animate-radar-pulse" />
              <Radio size={24} className="animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[11px] font-bold text-emerald-400 uppercase tracking-widest bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded">Broadcast Active</span>
                <span className="text-xs text-slate-500 font-semibold">{new Date(activeSessions[0].startTime).toLocaleTimeString()}</span>
              </div>
              <h3 className="text-lg font-bold text-slate-100 font-[Outfit] mt-1.5">{activeSessions[0].class_name}</h3>
              <p className="text-xs font-semibold text-slate-400 mt-0.5">{activeSessions[0].subject || "Attendance Beacon Broadcast in Progress..."}</p>
            </div>
          </div>
          <Link 
            href={`/teacher/sessions/${activeSessions[0].id}`}
            className="glass-btn glass-btn-primary glass-btn-md font-extrabold flex items-center gap-2 self-start md:self-center bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 hover:bg-emerald-500/20 shadow-lg shadow-emerald-950/20 transition-all duration-300"
          >
            <Eye size={15} />
            <span>Monitor Live Roster</span>
          </Link>
        </div>
      )}

      {/* Quick Actions (Moved to Top for Accessibility) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {quickActions.map((action) => (
          <Link
            key={action.href}
            href={action.href}
            className="flex flex-col gap-3 p-4 rounded-xl border border-white/[0.04] bg-white/[0.01] hover:bg-white/[0.03] hover:border-white/15 transition-all duration-300 group shadow-md"
          >
            <div className="flex items-center justify-between">
              <div className="p-2.5 rounded-xl bg-emerald-500/5 border border-emerald-500/10 text-emerald-400 group-hover:bg-emerald-500/10 group-hover:border-emerald-500/20 transition-all duration-300">
                {action.icon}
              </div>
              <ArrowUpRight size={16} className="text-slate-500 opacity-60 group-hover:text-emerald-400 group-hover:opacity-100 transition-all group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
            </div>
            <div>
              <span className="font-bold text-sm text-slate-200 tracking-wide">{action.label}</span>
              <p className="text-xs text-slate-500 mt-0.5 leading-normal font-medium">{action.detail}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 md:gap-6">
        <GlassStatCard
          icon={<BookOpen size={20} />}
          label="My Classes"
          value={classes.length}
          accentColor="blue"
          trend="Enrolled Classes"
          trendUp
        />
        <GlassStatCard
          icon={<Radio size={20} />}
          label="Active Sessions"
          value={activeSessions.length}
          accentColor="emerald"
          trend={completedSessions.length > 0 ? `${completedSessions.length} Completed` : "Ready"}
          trendUp
        />
        <GlassStatCard
          icon={<ClipboardCheck size={20} />}
          label="Pending Reviews"
          value={flagged.length}
          accentColor={flagged.length > 0 ? "rose" : "purple"}
          trend={flagged.length > 0 ? "Action Required" : "All Clear"}
          trendUp={flagged.length === 0}
        />
      </div>

      {/* Recent Sessions */}
      <GlassCard className="relative overflow-hidden" padding="none">
        <div className="p-5 border-b border-white/[0.05] flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Clock size={16} className="text-emerald-400" />
            <h3 className="text-sm font-extrabold text-slate-200 tracking-wide font-[Outfit] uppercase">Recent Sessions</h3>
          </div>
        </div>
        
        <div className="p-5 space-y-3">
          {sessions.slice(0, 5).map((session, i) => (
            <div key={i} className="flex items-center justify-between gap-3 p-3.5 rounded-xl bg-white/[0.01] border border-white/[0.03] hover:bg-white/[0.02] transition-all duration-300">
              <div className="min-w-0">
                <p className="text-xs font-bold text-slate-200 truncate leading-normal">{session.class_name}</p>
                <p className="text-[10px] text-slate-500 font-semibold mt-1 tracking-wide">
                  {new Date(session.startTime).toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                </p>
              </div>
              <GlassBadge variant={session.isActive ? "success" : "neutral"} className="text-[9px] font-bold tracking-wider py-0.5 px-2 shrink-0">
                {session.isActive ? "ACTIVE" : "COMPLETED"}
              </GlassBadge>
            </div>
          ))}
          {sessions.length === 0 && (
            <div className="py-8 text-center text-slate-500 text-xs font-medium">No sessions recorded yet.</div>
          )}
        </div>
      </GlassCard>

    </div>
  );
}
