"use client";

import React, { useEffect, useState } from "react";
import { BarChart3, Users, BookOpen, TrendingUp } from "lucide-react";
import api from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassStatCard from "@/components/ui/GlassStatCard";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import type { AcademicClassWithGeofence, ClassStatsResponse } from "@/types";

import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from "recharts";

export default function AnalyticsPage(): React.ReactElement {
  const [classes, setClasses] = useState<AcademicClassWithGeofence[]>([]);
  const [selectedClass, setSelectedClass] = useState("");
  const [stats, setStats] = useState<ClassStatsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(false);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try {
        const { data } = await api.get<AcademicClassWithGeofence[]>("/teacher/my-classes");
        setClasses(data);
        if (data.length > 0) setSelectedClass(data[0].id);
      } catch { setClasses([]); }
      finally { setLoading(false); }
    }
    fetch();
  }, []);

  useEffect(() => {
    if (!selectedClass) return;
    async function fetchStats(): Promise<void> {
      setStatsLoading(true);
      try {
        const { data } = await api.get<ClassStatsResponse>(`/teacher/classes/${selectedClass}/stats`);
        setStats(data);
      } catch { setStats(null); }
      finally { setStatsLoading(false); }
    }
    fetchStats();
  }, [selectedClass]);

  if (loading) return <GlassLoader text="Loading analytics..." />;
  if (classes.length === 0) return <><GlassPageHeader title="Analytics" /><GlassEmptyState title="No Classes" message="No classes assigned yet." /></>;

  const trendData = stats?.history && stats.history.length > 0
    ? stats.history.map((h) => ({
        session: h.session_name,
        attendance: h.attendance_percentage,
      }))
    : Array.from({ length: 5 }, (_, i) => ({
        session: `S${i + 1}`,
        attendance: 0,
      }));

  return (
    <div className="animate-fade-in-up">
      <GlassPageHeader title="Analytics Dashboard" description="Attendance trends and statistics" />

      <div className="mb-6 max-w-xs">
        <GlassSelect label="Select Class"
          options={classes.map((c) => ({ value: c.id, label: `${c.name} — ${c.subject}` }))}
          value={selectedClass} onChange={setSelectedClass} />
      </div>

      {statsLoading ? <GlassLoader text="Loading stats..." /> : stats ? (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 mb-8">
            <GlassStatCard icon={<BookOpen size={22} />} label="Total Sessions" value={stats.total_sessions} accentColor="emerald" />
            <GlassStatCard icon={<Users size={22} />} label="Enrolled Students" value={stats.total_students} accentColor="emerald" />
            <GlassStatCard icon={<TrendingUp size={22} />} label="Attendance Rate" value={`${stats.overall_attendance_percentage.toFixed(1)}%`} accentColor="emerald" />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <GlassCard>
              <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
                <BarChart3 size={16} /> Attendance Trend
              </h3>
              <ResponsiveContainer width="100%" height={280}>
                <AreaChart data={trendData}>
                  <defs>
                    <linearGradient id="attendanceGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis dataKey="session" stroke="#64748b" fontSize={12} />
                  <YAxis stroke="#64748b" fontSize={12} domain={[0, 100]} />
                  <Tooltip contentStyle={{ background: "rgba(15,23,42,0.95)", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 12 }} />
                  <Area type="monotone" dataKey="attendance" stroke="#10b981" fill="url(#attendanceGrad)" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            </GlassCard>

            <GlassCard>
              <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Session Breakdown</h3>
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={trendData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis dataKey="session" stroke="#64748b" fontSize={12} />
                  <YAxis stroke="#64748b" fontSize={12} domain={[0, 100]} />
                  <Tooltip contentStyle={{ background: "rgba(15,23,42,0.95)", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 12 }} />
                  <Bar dataKey="attendance" fill="#10b981" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </GlassCard>
          </div>
        </>
      ) : (
        <GlassEmptyState title="No Stats" message="No statistics available for this class yet." />
      )}
    </div>
  );
}
