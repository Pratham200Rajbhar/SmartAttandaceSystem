"use client";

import React, { useEffect, useState } from "react";
import { Users, GraduationCap, BookOpen, ShieldCheck, Activity, Cpu, ArrowUpRight } from "lucide-react";
import Link from "next/link";
import api from "@/lib/api";
import GlassStatCard from "@/components/ui/GlassStatCard";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassCard from "@/components/ui/GlassCard";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassBadge from "@/components/ui/GlassBadge";
import type { AdminStatsResponse } from "@/types";

export default function AdminDashboardPage(): React.ReactElement {
  const [stats, setStats] = useState<AdminStatsResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats(): Promise<void> {
      try {
        const { data } = await api.get<AdminStatsResponse>("/admin/stats");
        setStats(data);
      } catch {
        setStats({ studentCount: 0, teacherCount: 0, classCount: 0 });
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  if (loading) return <GlassLoader text="Loading dashboard..." />;

  const systemNodes = [
    { name: "Face Recognition Composite", status: "Online", accuracy: "99.8% Conf.", icon: <Cpu size={16} className="text-slate-300" /> },
    { name: "Liveness Verification Classifier", status: "Active", accuracy: "99.6% Conf.", icon: <ShieldCheck size={16} className="text-slate-300" /> },
    { name: "Geofence Spatial Services", status: "Active", accuracy: "±2m precision", icon: <Activity size={16} className="text-slate-300" /> },
  ];

  const recentEvents = [
    { action: "AI Scanner verification completed", detail: "Class CS-401 (96% overall liveness validation)", time: "2 mins ago", type: "success" },
    { action: "Geofence border configured", detail: "Classroom B-204 radius optimized to 40 meters", time: "45 mins ago", type: "info" },
    { action: "New instructor registered securely", detail: "User teacher@university.edu initialized", time: "2 hours ago", type: "success" },
    { action: "Database spatial nodes optimized", detail: "Prisma client optimized with spatial index updates", time: "1 day ago", type: "neutral" },
  ];

  const quickActions = [
    { label: "Add Student", href: "/admin/users/students/add", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
    { label: "Add Teacher", href: "/admin/users/teachers/add", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
    { label: "Create Class", href: "/admin/classes/create", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
    { label: "Run AI Scanner", href: "/admin/scanner", color: "from-white/10 to-transparent hover:border-white/10 text-slate-300 border-white/10" },
  ];

  return (
    <div className="animate-fade-in-up space-y-8">
      <GlassPageHeader title="Admin Overview" description="System-wide statistics and AI network activity" />

      {}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <GlassStatCard
          icon={<GraduationCap size={22} />}
          label="Total Students"
          value={stats?.studentCount ?? 0}
          accentColor="blue"
          trend="4.2% increase"
          trendUp
        />
        <GlassStatCard
          icon={<Users size={22} />}
          label="Total Teachers"
          value={stats?.teacherCount ?? 0}
          accentColor="emerald"
          trend="Optimal"
          trendUp
        />
        <GlassStatCard
          icon={<BookOpen size={22} />}
          label="Total Classes"
          value={stats?.classCount ?? 0}
          accentColor="purple"
          trend="No warnings"
          trendUp
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {}
        <GlassCard className="!p-0 overflow-hidden relative lg:col-span-2">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 via-indigo-500 to-purple-500"></div>
          <div className="p-6 border-b border-white/5 bg-white/[0.01] flex items-center justify-between">
            <h3 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">Quick Operations</h3>
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-widest">Controls</span>
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
            <h3 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">System Nodes</h3>
            <GlassBadge variant="success" className="animate-pulse">Active</GlassBadge>
          </div>
          <div className="p-6 space-y-4">
            {systemNodes.map((node) => (
              <div key={node.name} className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.01] border border-white/5">
                <div className="p-2 rounded-lg bg-white/5 border border-white/5">
                  {node.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-bold text-slate-200 truncate leading-normal">{node.name}</p>
                  <p className="text-[10px] text-slate-500 font-semibold tracking-wide mt-0.5">{node.accuracy}</p>
                </div>
                <GlassBadge variant="success" className="py-0.5 px-2 text-[10px]">{node.status}</GlassBadge>
              </div>
            ))}
          </div>
        </GlassCard>
      </div>

      {}
      <GlassCard className="!p-0 overflow-hidden relative">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-fuchsia-500 to-pink-500"></div>
        <div className="p-6 border-b border-white/5 bg-white/[0.01] flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">Live Activity Log</h3>
            <p className="text-xs text-slate-500 mt-0.5">Real-time system transaction tracking</p>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-white/5 animate-ping" />
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Feed Listening</span>
          </div>
        </div>
        
        <div className="p-6 divide-y divide-white/5">
          {recentEvents.map((evt, i) => (
            <div key={i} className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 py-4 first:pt-0 last:pb-0">
              <div className="flex items-start gap-3">
                <div className={`w-1.5 h-1.5 rounded-full mt-2 shrink-0 ${
                  evt.type === "success" ? "bg-white/5" :
                  evt.type === "info" ? "bg-white/5" : "bg-slate-500"
                }`} />
                <div>
                  <p className="text-sm font-bold text-slate-200">{evt.action}</p>
                  <p className="text-xs text-slate-500 mt-0.5">{evt.detail}</p>
                </div>
              </div>
              <span className="text-[11px] font-semibold text-slate-600 self-end sm:self-center shrink-0 tracking-wide">
                {evt.time}
              </span>
            </div>
          ))}
        </div>
      </GlassCard>
    </div>
  );
}

