"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { User, GraduationCap, Save, X } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { StudentResponse, DepartmentResponse } from "@/types";

const GENDER_OPTIONS = [
  { value: "Male", label: "Male" },
  { value: "Female", label: "Female" },
  { value: "Other", label: "Other" },
  { value: "Prefer not to say", label: "Prefer not to say" },
];

const SEMESTER_OPTIONS = Array.from({ length: 8 }, (_, i) => ({
  value: String(i + 1),
  label: `Semester ${i + 1}`,
}));

export default function EditStudentPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [student, setStudent] = useState<StudentResponse | null>(null);
  const [departments, setDepartments] = useState<DepartmentResponse[]>([]);
  const [form, setForm] = useState<Partial<StudentResponse>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function fetchStudentAndDeps(): Promise<void> {
      try {
        const [studentsRes, depsRes] = await Promise.all([
          api.get<StudentResponse[]>("/admin/users/students"),
          api.get<DepartmentResponse[]>("/admin/departments").catch(() => ({ data: [] })),
        ]);
        setDepartments(depsRes.data);
        const found = studentsRes.data.find((s) => s.id === id);
        if (found) {
          setStudent(found);
          setForm({
            enrollment_number: found.enrollment_number,
            first_name: found.first_name,
            last_name: found.last_name,
            phone: found.phone,
            gender: found.gender,
            date_of_birth: found.date_of_birth ? new Date(found.date_of_birth).toISOString().split("T")[0] : undefined,
            semester: found.semester,
            batch: found.batch,
            department_id: found.department_id,
          });
        }
      } catch {
        toast.error("Failed to load student data");
      } finally {
        setLoading(false);
      }
    }
    
    void fetchStudentAndDeps();
  }, [id]);

  function set(field: keyof StudentResponse, value: string | number | undefined): void {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!form.enrollment_number?.trim()) {
      toast.error("Enrollment number is required");
      return;
    }
    setSaving(true);
    try {
      await api.put(`/admin/users/students/${id}`, {
        enrollment_number: form.enrollment_number,
        first_name: form.first_name,
        last_name: form.last_name,
        phone: form.phone || undefined,
        gender: form.gender || undefined,
        date_of_birth: form.date_of_birth ? new Date(form.date_of_birth).toISOString() : undefined,
        semester: form.semester ? Number(form.semester) : undefined,
        batch: form.batch || undefined,
        department_id: form.department_id || undefined,
      });
      toast.success("Student updated successfully");
      router.push(`/admin/users/students/${id}`);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Update failed"));
    } finally {
      setSaving(false);
    }
  }

  const deptOptions = [
    { value: "", label: "None — assign later" },
    ...departments.map((d) => ({ value: d.id, label: `${d.name} (${d.code})` })),
  ];

  if (loading) return <GlassLoader text="Loading student..." />;
  if (!student) return <div className="text-center py-20 text-slate-500">Student not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Students", href: "/admin/users/students" },
          { label: student.email, href: `/admin/users/students/${id}` },
          { label: "Edit" },
        ]}
      />
      <GlassPageHeader title="Edit Student Profile" description="Update student personal and academic details." />
      
      <form onSubmit={handleSubmit} className="max-w-4xl space-y-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 space-y-8">
            <GlassCard className="!p-0 overflow-hidden relative">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-cyan-500"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <User size={20} className="text-slate-300" />
                  Account Info
                </h3>
                <p className="text-sm text-slate-400 mt-1">Core system identifiers.</p>
              </div>
              <div className="p-6 space-y-5">
                <GlassInput label="Email Address" value={student.email} disabled />
                <GlassInput
                  label="Enrollment Number"
                  value={form.enrollment_number ?? ""}
                  onChange={(e) => set("enrollment_number", e.target.value)}
                />
              </div>
            </GlassCard>
          </div>

          <div className="lg:col-span-2">
            <GlassCard className="!p-0 overflow-hidden relative h-full">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <GraduationCap size={20} className="text-slate-300" />
                  Student Profile
                </h3>
                <p className="text-sm text-slate-400 mt-1">Personal and academic details.</p>
              </div>
              <div className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
            <GlassInput
              label="First Name"
              value={form.first_name ?? ""}
              onChange={(e) => set("first_name", e.target.value)}
            />
            <GlassInput
              label="Last Name"
              value={form.last_name ?? ""}
              onChange={(e) => set("last_name", e.target.value)}
            />
            <GlassInput
              label="Phone (optional)"
              type="tel"
              value={form.phone ?? ""}
              onChange={(e) => set("phone", e.target.value)}
            />
            <GlassSelect
              label="Gender (optional)"
              options={[{ value: "", label: "— Select —" }, ...GENDER_OPTIONS]}
              value={form.gender ?? ""}
              onChange={(v) => set("gender", v)}
            />
            <GlassInput
              label="Date of Birth (optional)"
              type="date"
              value={form.date_of_birth ?? ""}
              onChange={(e) => set("date_of_birth", e.target.value)}
            />
            <GlassSelect
              label="Semester (optional)"
              options={[{ value: "", label: "— Select —" }, ...SEMESTER_OPTIONS]}
              value={form.semester ? String(form.semester) : ""}
              onChange={(v) => set("semester", v ? Number(v) : undefined)}
            />
            <GlassInput
              label="Batch (optional)"
              value={form.batch ?? ""}
              onChange={(e) => set("batch", e.target.value)}
            />
            <GlassSelect
              label="Department (optional)"
              options={deptOptions}
              value={form.department_id ?? ""}
              onChange={(v) => set("department_id", v)}
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
