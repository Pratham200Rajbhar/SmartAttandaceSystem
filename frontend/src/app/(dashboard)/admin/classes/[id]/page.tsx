"use client";

import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { 
  Pencil, UserPlus, Users, BookOpen, GraduationCap, MapPin, 
  Hash, LayoutDashboard, ChevronRight
} from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassCard from "@/components/ui/GlassCard";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassBadge from "@/components/ui/GlassBadge";
import type { ClassResponse } from "@/types";

const colorVariants: Record<string, string> = {
  emerald: "bg-emerald-500/10 text-emerald-400 group-hover:shadow-emerald-500/20",
  rose: "bg-rose-500/10 text-rose-400 group-hover:shadow-rose-500/20",
  blue: "bg-blue-500/10 text-blue-400 group-hover:shadow-blue-500/20",
  slate: "bg-slate-500/10 text-slate-400 group-hover:shadow-slate-500/20",
};

const InfoItem = ({ icon: Icon, label, value, color }: { icon: React.ElementType, label: string, value: string | React.ReactNode, color: string }) => (
  <div className="group flex items-center justify-between p-4 rounded-xl border border-transparent hover:border-white/5 hover:bg-white/[0.02] transition-all duration-300">
    <div className="flex items-center gap-4">
      <div className={`p-3 rounded-2xl ${colorVariants[color] || colorVariants.slate} group-hover:scale-110 transition-transform duration-300 shadow-[0_4px_12px_rgba(0,0,0,0.5)]`}>
        <Icon size={20} />
      </div>
      <div>
        <p className="text-xs font-medium text-slate-500 uppercase tracking-wider mb-1">{label}</p>
        <div className="text-sm font-semibold text-slate-200">{value}</div>
      </div>
    </div>
    <ChevronRight size={16} className="text-slate-700 group-hover:text-slate-400 transition-colors opacity-0 group-hover:opacity-100 transform translate-x-2 group-hover:translate-x-0 duration-300" />
  </div>
);

export default function ClassDetailPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const [cls, setCls] = useState<ClassResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try {
        const { data } = await api.get<ClassResponse>(`/admin/classes/${id}`);
        setCls(data);
      } catch (err: unknown) {
        toast.error(getApiErrorMessage(err, "Failed to load class"));
        setCls(null);
      } finally {
        setLoading(false);
      }
    }
    void fetch();
  }, [id]);

  if (loading) return <GlassLoader text="Loading class details..." />;
  if (!cls) return <div className="text-center py-20 text-slate-500">Class not found</div>;

  return (
    <div className="animate-fade-in-up space-y-8">
      <GlassBreadcrumb items={[
        { label: "Admin", href: "/admin/dashboard" },
        { label: "Classes", href: "/admin/classes" },
        { label: cls.name }
      ]} />
      
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white tracking-tight mb-2 flex items-center gap-3">
            {cls.name}
            {cls.semester && <GlassBadge variant="info">Semester {cls.semester}</GlassBadge>}
          </h1>
          <p className="text-slate-400">
            {cls.subject_name} ({cls.subject_code})
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link href={`/admin/classes/${id}/edit`}>
            <GlassButton variant="secondary" icon={<Pencil size={16} />}>
              Edit Details
            </GlassButton>
          </Link>
          <Link href={`/admin/classes/${id}/enroll`}>
            <GlassButton variant="primary" icon={<UserPlus size={16} />}>
              Enroll Students
            </GlassButton>
          </Link>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-8">
          <GlassCard className="!p-0 overflow-hidden relative border border-white/10">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-cyan-500"></div>
            <div className="p-6 border-b border-white/5 bg-white/[0.01]">
              <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                <BookOpen size={20} className="text-slate-300" />
                Class Overview
              </h3>
            </div>
            <div className="p-2 space-y-1">
              <InfoItem icon={Hash} label="Subject" value={<span>{cls.subject_name} <span className="text-slate-500 font-normal ml-1">({cls.subject_code})</span></span>} color="emerald" />
              <InfoItem icon={MapPin} label="Location" value={cls.classroom_name || "Unassigned"} color="rose" />
              <InfoItem 
                icon={GraduationCap} 
                label="Semester & Batch" 
                value={`${cls.semester ? `Semester ${cls.semester}` : "Semester unassigned"} ${cls.batch ? `• Batch ${cls.batch}` : ""}`} 
                color="blue" 
              />
              <InfoItem icon={LayoutDashboard} label="System Identifier" value={cls.id} color="slate" />
            </div>
          </GlassCard>
        </div>

        <div className="space-y-6">
          <GlassCard className="!p-0 overflow-hidden relative border border-white/10">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
            <div className="p-6 border-b border-white/5 bg-white/[0.01]">
              <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                <Users size={20} className="text-slate-300" />
                Capacity
              </h3>
            </div>
            <div className="p-6">
              <div className="flex items-end justify-between mb-2">
                <div>
                  <p className="text-3xl font-bold text-white">{cls.enrolled_count}</p>
                  <p className="text-xs font-medium text-slate-400 uppercase tracking-wider mt-1">Enrolled</p>
                </div>
                <div className="text-right">
                  <p className="text-xl font-medium text-slate-500">{cls.max_students || "∞"}</p>
                  <p className="text-xs font-medium text-slate-500 uppercase tracking-wider mt-1">Capacity</p>
                </div>
              </div>
              <div className="w-full bg-slate-800 rounded-full h-2 mt-4 overflow-hidden">
                <div 
                  className="bg-gradient-to-r from-white/10 to-transparent h-2 rounded-full" 
                  style={{ width: cls.max_students ? `${Math.min((cls.enrolled_count / cls.max_students) * 100, 100)}%` : "100%" }}
                ></div>
              </div>
            </div>
          </GlassCard>

          <GlassCard className="!p-0 overflow-hidden relative border border-white/10">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
            <div className="p-4 bg-white/[0.01] space-y-3">
              <Link href={`/admin/classes/${id}/assign-teacher`} className="group flex items-center gap-3 w-full p-3 rounded-xl bg-slate-800/50 border border-white/5 hover:bg-white/5 hover:border-white/10 transition-all duration-300">
                <div className="p-2 rounded-lg bg-white/5 text-slate-300 group-hover:scale-110 transition-transform">
                  <Users size={18} />
                </div>
                <div className="flex-1 text-left">
                  <p className="text-sm font-medium text-slate-200 group-hover:text-emerald-300 transition-colors">Change Teacher</p>
                  <p className="text-xs text-slate-500">Reassign faculty member</p>
                </div>
              </Link>
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}
