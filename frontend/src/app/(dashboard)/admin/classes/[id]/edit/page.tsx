"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { BookOpen, Users, Save, X, Settings2 } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { ClassResponse, SubjectResponse, ClassroomResponse } from "@/types";

export default function EditClassPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [cls, setCls] = useState<ClassResponse | null>(null);
  const [subjects, setSubjects] = useState<SubjectResponse[]>([]);
  const [classrooms, setClassrooms] = useState<ClassroomResponse[]>([]);
  const [name, setName] = useState("");
  const [subjectId, setSubjectId] = useState("");
  const [classroomId, setClassroomId] = useState("");
  const [semester, setSemester] = useState<string>("");
  const [batch, setBatch] = useState("");
  const [maxStudents, setMaxStudents] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const fetchData = useCallback(async (): Promise<void> => {
    try {
      const [classRes, subjectsRes, classroomsRes] = await Promise.all([
        api.get<ClassResponse>(`/admin/classes/${id}`),
        api.get<SubjectResponse[]>("/admin/subjects"),
        api.get<ClassroomResponse[]>("/admin/classrooms"),
      ]);
      const found = classRes.data;
      if (found) {
        setCls(found);
        setName(found.name);
        
        const matchedSubject = subjectsRes.data.find(
          (s) => s.name === found.subject_name && s.code === found.subject_code
        );
        if (matchedSubject) setSubjectId(matchedSubject.id);
        
        const matchedClassroom = classroomsRes.data.find(
          (c) => c.name === found.classroom_name
        );
        if (matchedClassroom) setClassroomId(matchedClassroom.id);
        
        setSemester(found.semester ? String(found.semester) : "");
        setBatch(found.batch || "");
        setMaxStudents(found.max_students ? String(found.max_students) : "");
      }
      setSubjects(subjectsRes.data);
      setClassrooms(classroomsRes.data);
    } catch {
      toast.error("Could not load class data.");
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    void (async () => {
      await fetchData();
    })();
  }, [fetchData]);

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!name.trim()) { toast.error("Class name is required"); return; }
    setSaving(true);
    try {
      const payload: Record<string, unknown> = { name };
      if (subjectId) payload.subject_id = subjectId;
      if (classroomId) payload.classroom_id = classroomId;
      if (semester) payload.semester = Number(semester);
      if (batch) payload.batch = batch;
      if (maxStudents) payload.max_students = Number(maxStudents);
      await api.put(`/admin/classes/${id}`, payload);
      toast.success("Class updated");
      router.push(`/admin/classes/${id}`);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Update failed"));
    } finally {
      setSaving(false); }
  }

  if (loading) return <GlassLoader />;
  if (!cls) return <div className="text-center py-20 text-slate-500">Class not found</div>;

  const subjectOptions = [
    { value: "", label: "— Keep current —" },
    ...subjects.map((s) => ({ value: s.id, label: `${s.name} (${s.code})` })),
  ];

  const SEMESTER_OPTIONS = [
    { value: "", label: "— Keep current —" },
    ...Array.from({ length: 8 }, (_, i) => ({
      value: String(i + 1),
      label: `Semester ${i + 1}`,
    })),
  ];

  const classroomOptions = [
    { value: "", label: "— Keep current —" },
    ...classrooms.map((c) => ({
      value: c.id,
      label: c.building ? `${c.name} — ${c.building}` : c.name,
    })),
  ];

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Classes", href: "/admin/classes" },
          { label: cls.name, href: `/admin/classes/${id}` },
          { label: "Edit" },
        ]}
      />
      <GlassPageHeader title="Edit Class" description={`Editing ${cls.name}`} />
      <form onSubmit={handleSubmit} className="max-w-4xl space-y-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 space-y-8">
            <GlassCard className="!p-0 overflow-hidden relative">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <BookOpen size={20} className="text-slate-300" />
                  Core Info
                </h3>
                <p className="text-sm text-slate-400 mt-1">Primary identifiers.</p>
              </div>
              <div className="p-6 space-y-5">
                <GlassInput
                  label="Class Name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
              </div>
            </GlassCard>
            
            <GlassCard className="!p-0 overflow-hidden relative border border-white/10">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <Users size={20} className="text-slate-300" />
                  Capacity
                </h3>
                <p className="text-sm text-slate-400 mt-1">Enrollment limits.</p>
              </div>
              <div className="p-6">
                <GlassInput
                  label="Max Students (optional)"
                  type="number"
                  min="1"
                  value={maxStudents}
                  onChange={(e) => setMaxStudents(e.target.value)}
                />
              </div>
            </GlassCard>
          </div>

          <div className="lg:col-span-2">
            <GlassCard className="!p-0 overflow-hidden relative h-full">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-cyan-500"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <Settings2 size={20} className="text-slate-300" />
                  Class Configuration
                </h3>
                <p className="text-sm text-slate-400 mt-1">Spatial and academic assignments.</p>
              </div>
              <div className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
                <GlassSelect
                  label="Subject (optional)"
                  options={subjectOptions}
                  value={subjectId}
                  onChange={setSubjectId}
                />
                <GlassSelect
                  label="Classroom (optional)"
                  options={classroomOptions}
                  value={classroomId}
                  onChange={setClassroomId}
                />
                <GlassSelect
                  label="Semester (optional)"
                  options={SEMESTER_OPTIONS}
                  value={semester}
                  onChange={setSemester}
                />
                <GlassInput
                  label="Batch (optional)"
                  placeholder="e.g. 2022-2026"
                  value={batch}
                  onChange={(e) => setBatch(e.target.value)}
                />
              </div>
            </GlassCard>
          </div>
        </div>

        <div className="flex justify-end gap-4 pt-4 pb-12">
          <GlassButton variant="ghost" type="button" onClick={() => router.back()} icon={<X size={16} />}>
            Cancel
          </GlassButton>
          <GlassButton variant="primary" type="submit" loading={saving} icon={<Save size={16} />}>
            Save Changes
          </GlassButton>
        </div>
      </form>
    </div>
  );
}
