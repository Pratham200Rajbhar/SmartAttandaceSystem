"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { 
  Pencil, Mail, Hash, User, Phone, GraduationCap, Building2, CalendarDays, 
  MapPin, Clock, Award, ShieldCheck, ChevronRight, KeyRound
} from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassCard from "@/components/ui/GlassCard";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassBadge from "@/components/ui/GlassBadge";
import GlassResetPasswordDialog from "@/components/ui/GlassResetPasswordDialog";
import type { StudentResponse } from "@/types";

const colorVariants: Record<string, string> = {
  blue: "bg-blue-500/10 text-blue-400 group-hover:shadow-blue-500/20",
  purple: "bg-purple-500/10 text-purple-400 group-hover:shadow-purple-500/20",
  pink: "bg-pink-500/10 text-pink-400 group-hover:shadow-pink-500/20",
  amber: "bg-amber-500/10 text-amber-400 group-hover:shadow-amber-500/20",
  emerald: "bg-emerald-500/10 text-emerald-400 group-hover:shadow-emerald-500/20",
  rose: "bg-rose-500/10 text-rose-400 group-hover:shadow-rose-500/20",
  cyan: "bg-cyan-500/10 text-cyan-400 group-hover:shadow-cyan-500/20",
  slate: "bg-slate-500/10 text-slate-400 group-hover:shadow-slate-500/20",
};

const InfoItem = ({ icon: Icon, label, value, color }: { icon: React.ElementType, label: string, value: string, color: string }) => (
  <div className="group flex items-center justify-between p-4 rounded-xl border border-transparent hover:border-white/5 hover:bg-white/[0.02] transition-all duration-300">
    <div className="flex items-center gap-4">
      <div className={`p-3 rounded-2xl ${colorVariants[color] || colorVariants.slate} group-hover:scale-110 transition-transform duration-300 shadow-[0_4px_12px_rgba(0,0,0,0.5)]`}>
        <Icon size={20} />
      </div>
      <div>
        <p className="text-xs font-medium text-slate-500 uppercase tracking-wider mb-1">{label}</p>
        <p className="text-sm font-semibold text-slate-200">{value}</p>
      </div>
    </div>
    <ChevronRight size={16} className="text-slate-700 group-hover:text-slate-400 transition-colors opacity-0 group-hover:opacity-100 transform translate-x-2 group-hover:translate-x-0 duration-300" />
  </div>
);

export default function StudentDetailPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [student, setStudent] = useState<StudentResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [isResetDialogOpen, setIsResetDialogOpen] = useState(false);

  useEffect(() => {
    async function fetchStudent(): Promise<void> {
      try {
        const { data } = await api.get<StudentResponse>(`/admin/users/students/${id}`);
        setStudent(data);
      } catch (err: unknown) {
        toast.error(getApiErrorMessage(err, "Failed to load student"));
        setStudent(null);
      } finally {
        setLoading(false);
      }
    }
    void fetchStudent();
  }, [id]);

  const handleResetPassword = async (newPassword: string) => {
    if (!student) return;
    try {
      await api.put(`/admin/users/${student.user_id}/reset-password`, { new_password: newPassword });
      toast.success(`Password reset for ${student.email}`);
      setIsResetDialogOpen(false);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to reset password"));
    }
  };

  if (loading) return <GlassLoader text="Loading student details..." />;
  if (!student) return <div className="text-center py-20 text-slate-500">Student not found</div>;

  const fullName = student.first_name && student.last_name 
    ? `${student.first_name} ${student.last_name}` 
    : student.first_name || student.last_name || "Not provided";

  const initials = (student.first_name?.[0] || "") + (student.last_name?.[0] || "");

  return (
    <div className="animate-fade-in-up space-y-8">
      <GlassBreadcrumb items={[
        { label: "Admin", href: "/admin/dashboard" },
        { label: "Students", href: "/admin/users/students" },
        { label: fullName !== "Not provided" ? fullName : student.email },
      ]} />
      
      {}
      <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-slate-900/50 backdrop-blur-md shadow-2xl">
        <div className="absolute inset-0 bg-gradient-to-r from-blue-600/20 via-purple-600/10 to-transparent opacity-50"></div>
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3"></div>
        
        <div className="relative p-8 sm:p-10 flex flex-col sm:flex-row items-center sm:items-start gap-8">
          <div className="flex-shrink-0 relative">
            <div className="w-32 h-32 rounded-full bg-gradient-to-br from-white/10 to-purple-600 p-1 shadow-[0_4px_12px_rgba(0,0,0,0.5)]">
              <div className="w-full h-full rounded-full bg-slate-900 flex items-center justify-center border-4 border-slate-900">
                <span className="text-4xl font-bold bg-clip-text text-transparent bg-gradient-to-br from-white/5 to-purple-400">
                  {initials || <User size={40} className="text-slate-300" />}
                </span>
              </div>
            </div>
            <div className="absolute -bottom-2 -right-2 bg-white/5 border border-white/10 text-slate-300 p-2 rounded-full shadow-[0_4px_12px_rgba(0,0,0,0.5)]">
              <ShieldCheck size={18} />
            </div>
          </div>
          
          <div className="flex-1 text-center sm:text-left space-y-4">
            <div>
              <h1 className="text-3xl sm:text-4xl font-bold text-white tracking-tight mb-2">
                {fullName}
              </h1>
              <div className="flex flex-wrap items-center justify-center sm:justify-start gap-3">
                <GlassBadge variant="info">{student.enrollment_number}</GlassBadge>
                {student.department_name && <GlassBadge variant="success">{student.department_name}</GlassBadge>}
                <span className="text-sm text-slate-400 flex items-center gap-1.5 bg-white/5 px-3 py-1 rounded-full border border-white/5">
                  <Clock size={14} /> Enrolled
                </span>
              </div>
            </div>
            
            <p className="text-slate-400 max-w-2xl text-sm leading-relaxed">
              Student profile containing full academic records, personal information, and system access details. Ensure all modifications align with institutional data policies.
            </p>
            
            <div className="pt-2 flex flex-wrap gap-3 justify-center sm:justify-start">
              <GlassButton variant="primary" icon={<Pencil size={16} />} onClick={() => router.push(`/admin/users/students/${id}/edit`)}>
                Edit Profile
              </GlassButton>
              <GlassButton variant="ghost" className="text-warning hover:text-warning hover:bg-warning/10" icon={<KeyRound size={16} />} onClick={() => setIsResetDialogOpen(true)}>
                Reset Password
              </GlassButton>
            </div>
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <GlassCard className="!p-0 overflow-hidden relative">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-cyan-500"></div>
          <div className="p-6 border-b border-white/5 bg-white/[0.01]">
            <h3 className="text-lg font-semibold text-white flex items-center gap-2">
              <User size={20} className="text-slate-300" />
              Personal Information
            </h3>
            <p className="text-sm text-slate-400 mt-1">Contact details and identity information.</p>
          </div>
          <div className="p-2 space-y-1">
            <InfoItem icon={Mail} label="Email Address" value={student.email} color="blue" />
            <InfoItem icon={Phone} label="Phone Number" value={student.phone || "Not provided"} color="purple" />
            <InfoItem icon={User} label="Gender" value={student.gender || "Unspecified"} color="pink" />
            <InfoItem 
              icon={CalendarDays} 
              label="Date of Birth" 
              value={student.date_of_birth ? new Date(student.date_of_birth).toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' }) : "Not provided"} 
              color="amber" 
            />
          </div>
        </GlassCard>

        <GlassCard className="!p-0 overflow-hidden relative">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
          <div className="p-6 border-b border-white/5 bg-white/[0.01]">
            <h3 className="text-lg font-semibold text-white flex items-center gap-2">
              <GraduationCap size={20} className="text-slate-300" />
              Academic Profile
            </h3>
            <p className="text-sm text-slate-400 mt-1">Institutional enrollment and course tracking.</p>
          </div>
          <div className="p-2 space-y-1">
            <InfoItem icon={Hash} label="Enrollment Number" value={student.enrollment_number} color="emerald" />
            <InfoItem icon={Building2} label="Department" value={student.department_name || "Not assigned"} color="rose" />
            <InfoItem 
              icon={Award} 
              label="Semester & Batch" 
              value={`${student.semester ? `Semester ${student.semester}` : "Semester unassigned"} ${student.batch ? `• Batch ${student.batch}` : ""}`} 
              color="cyan" 
            />
            <InfoItem icon={MapPin} label="System Identifier" value={student.id} color="slate" />
          </div>
        </GlassCard>
      </div>

      <GlassResetPasswordDialog
        isOpen={isResetDialogOpen}
        onClose={() => setIsResetDialogOpen(false)}
        onConfirm={handleResetPassword}
        title="Force Password Reset"
        description={student ? `Enter a new password for ${student.email}. They will be able to log in immediately with this new password.` : ""}
      />
    </div>
  );
}
