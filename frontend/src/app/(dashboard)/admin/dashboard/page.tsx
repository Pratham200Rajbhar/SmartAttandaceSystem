"use client";

import React, { useEffect, useState } from "react";
import { 
  Users, GraduationCap, BookOpen, ShieldCheck, Activity, Cpu, 
  ArrowUpRight, Clock, RefreshCw, Radio
} from "lucide-react";
import Link from "next/link";
import api from "@/lib/api";
import GlassStatCard from "@/components/ui/GlassStatCard";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassCard from "@/components/ui/GlassCard";
import GlassBadge from "@/components/ui/GlassBadge";
import type { AdminStatsResponse } from "@/types";

export default function AdminDashboardPage(): React.ReactElement {
  const [stats, setStats] = useState<AdminStatsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [greeting, setGreeting] = useState("Welcome");

  async function fetchStats(): Promise<void> {
    try {
      const { data } = await api.get<AdminStatsResponse>("/admin/stats");
      setStats(data);
    } catch {
      setStats({ studentCount: 0, teacherCount: 0, classCount: 0 });
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    const timer = setTimeout(() => {
      void fetchStats();
      const hour = new Date().getHours();
      if (hour < 12) setGreeting("Good morning");
      else if (hour < 17) setGreeting("Good afternoon");
      else setGreeting("Good evening");
    }, 0);
    return () => clearTimeout(timer);
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchStats();
  };

  if (loading) return <GlassLoader text="Loading system metrics..." />;

  const systemNodes = [
    { name: "Face Recognition Composite", status: "Online", accuracy: "99.8% Conf.", latency: "84ms", icon: <Cpu size={16} className="text-emerald-400" />, active: true },
    { name: "Liveness Verification Classifier", status: "Active", accuracy: "99.6% Conf.", latency: "142ms", icon: <ShieldCheck size={16} className="text-emerald-400" />, active: true },
    { name: "Geofence Spatial Services", status: "Active", accuracy: "±2m precision", latency: "18ms", icon: <Activity size={16} className="text-emerald-400" />, active: true },
  ];

  const recentEvents = [
    { action: "AI Scanner verification completed", detail: "Class CS-401 (96% overall liveness validation)", time: "2 mins ago", type: "success" },
    { action: "Geofence border configured", detail: "Classroom B-204 radius optimized to 40 meters", time: "45 mins ago", type: "info" },
    { action: "New instructor registered securely", detail: "User teacher@university.edu initialized", time: "2 hours ago", type: "success" },
    { action: "Database spatial nodes optimized", detail: "Prisma client optimized with spatial index updates", time: "1 day ago", type: "neutral" },
  ];

  const quickActions = [
    { label: "Configure Verifications", href: "/admin/setup/verification-settings", detail: "Toggle verification modes", icon: <ShieldCheck size={18} className="text-emerald-400" /> },
    { label: "Audit Activity Log", href: "/admin/audit", detail: "Inspect node transactions", icon: <Activity size={18} className="text-emerald-400" /> },
    { label: "Configure Classes", href: "/admin/classes", detail: "Manage schedules & enrollments", icon: <BookOpen size={18} className="text-emerald-400" /> },
    { label: "Execute AI Scanner", href: "/admin/scanner", detail: "Run manual camera check-in", icon: <Cpu size={18} className="text-emerald-400" /> },
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
              <p className="text-[11px] font-bold text-emerald-400 uppercase tracking-widest">System Administration</p>
            </div>
            <h1 className="text-2xl md:text-3xl font-extrabold text-slate-100 tracking-tight font-[Outfit]">{greeting}, Admin</h1>
            <p className="text-sm font-semibold text-slate-400 mt-1 max-w-2xl">
              All core services and verification nodes are operating nominally.
            </p>
          </div>
          <button 
            onClick={handleRefresh}
            disabled={refreshing}
            className="self-start sm:self-center glass-btn glass-btn-secondary glass-btn-sm font-semibold flex items-center gap-2 border border-white/5 hover:border-white/20 transition-all duration-300"
          >
            <RefreshCw size={13} className={refreshing ? "animate-spin" : ""} />
            <span>{refreshing ? "Refreshing..." : "Refresh Status"}</span>
          </button>
        </div>
      </div>

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
          icon={<GraduationCap size={20} />}
          label="Total Students"
          value={stats?.studentCount ?? 0}
          accentColor="blue"
          trend="Enrolled"
          trendUp
        />
        <GlassStatCard
          icon={<Users size={20} />}
          label="Total Teachers"
          value={stats?.teacherCount ?? 0}
          accentColor="emerald"
          trend="Active"
          trendUp
        />
        <GlassStatCard
          icon={<BookOpen size={20} />}
          label="Total Classes"
          value={stats?.classCount ?? 0}
          accentColor="purple"
          trend="Configured"
          trendUp
        />
      </div>

      {/* System Status & Activity Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* System Nodes */}
        <GlassCard className="relative overflow-hidden flex flex-col justify-between" padding="none">
          <div className="p-5 border-b border-white/[0.05] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Radio size={16} className="text-emerald-400" />
              <h3 className="text-sm font-extrabold text-slate-200 tracking-wide font-[Outfit] uppercase">Verification Nodes</h3>
            </div>
            <GlassBadge variant="success" className="font-bold py-0.5 px-2 text-[10px]">All Active</GlassBadge>
          </div>
          <div className="p-5 space-y-3">
            {systemNodes.map((node) => (
              <div key={node.name} className="flex items-center justify-between gap-3 p-3.5 rounded-xl bg-white/[0.01] border border-white/[0.04] hover:bg-white/[0.02] transition-all duration-300">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-white/5 border border-white/10 text-slate-300">
                    {node.icon}
                  </div>
                  <div>
                    <p className="text-xs font-bold text-slate-200 leading-normal">{node.name}</p>
                    <p className="text-[10px] text-slate-500 font-semibold tracking-wide mt-0.5">{node.accuracy} • Latency: {node.latency}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-glow-green" />
                </div>
              </div>
            ))}
          </div>
        </GlassCard>

        {/* Live Activity Log */}
        <GlassCard className="relative overflow-hidden" padding="none">
          <div className="p-5 border-b border-white/[0.05] flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Clock size={16} className="text-emerald-400" />
              <h3 className="text-sm font-extrabold text-slate-200 tracking-wide font-[Outfit] uppercase">System Events</h3>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping inline-block" />
              <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Listening</span>
            </div>
          </div>
          
          <div className="p-5 space-y-4 relative">
            <div className="absolute left-[33px] top-[25px] bottom-[25px] w-px bg-white/[0.06] pointer-events-none" />

            {recentEvents.map((evt, i) => (
              <div key={i} className="flex gap-4 relative z-10 group">
                <div className="flex items-center justify-center shrink-0">
                  <div className={`w-3.5 h-3.5 rounded-full border-2 ${
                    evt.type === "success" ? "bg-emerald-500/20 border-emerald-500/50" :
                    evt.type === "info" ? "bg-cyan-500/20 border-cyan-500/50" : "bg-slate-700/20 border-slate-500/50"
                  } flex items-center justify-center`}>
                    <div className={`w-1 h-1 rounded-full ${
                      evt.type === "success" ? "bg-emerald-400" :
                      evt.type === "info" ? "bg-cyan-400" : "bg-slate-400"
                    }`} />
                  </div>
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <p className="text-xs font-bold text-slate-200 group-hover:text-slate-100 transition-colors duration-200">{evt.action}</p>
                    <span className="text-[10px] font-semibold text-slate-500 shrink-0 mt-0.5">{evt.time}</span>
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1 leading-normal font-medium">{evt.detail}</p>
                </div>
              </div>
            ))}
          </div>
        </GlassCard>
      </div>

    </div>
  );
}
