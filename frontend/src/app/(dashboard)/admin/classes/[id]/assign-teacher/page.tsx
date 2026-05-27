"use client";

import React, { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { TeacherResponse } from "@/types";

export default function AssignTeacherPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [teachers, setTeachers] = useState<TeacherResponse[]>([]);
  const [teacherId, setTeacherId] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try { const { data } = await api.get<TeacherResponse[]>("/admin/users/teachers"); setTeachers(data); }
      catch (err: unknown) { toast.error(getApiErrorMessage(err, "Failed to load teachers")); }
      finally { setLoading(false); }
    }
    fetch();
  }, []);

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!teacherId) { toast.error("Select a teacher"); return; }
    setSaving(true);
    try {
      await api.put(`/admin/classes/${id}/assign-teacher`, { teacher_id: teacherId });
      toast.success("Teacher assigned");
      router.push(`/admin/classes/${id}`);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Assignment failed"));
    } finally { setSaving(false); }
  }

  if (loading) return <GlassLoader />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "Classes", href: "/admin/classes" }, { label: "Class", href: `/admin/classes/${id}` }, { label: "Assign Teacher" }]} />
      <GlassPageHeader title="Assign Teacher" description="Select a teacher to manage this class" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassSelect label="Teacher" options={teachers.map((t) => ({ value: t.id, label: `${t.email} — ${t.department}` }))}
            value={teacherId} onChange={setTeacherId} placeholder="Select teacher..." />
          <div className="flex justify-end gap-3 pt-4">
            <GlassButton variant="ghost" type="button" onClick={() => router.back()}>Cancel</GlassButton>
            <GlassButton variant="primary" type="submit" loading={saving}>Assign Teacher</GlassButton>
          </div>
        </form>
      </GlassCard>
    </div>
  );
}
