"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { User, Briefcase, Save, X } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { TeacherResponse, DepartmentResponse, DesignationResponse } from "@/types";

export default function EditTeacherPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [teacher, setTeacher] = useState<TeacherResponse | null>(null);
  const [departments, setDepartments] = useState<DepartmentResponse[]>([]);
  const [designations, setDesignations] = useState<DesignationResponse[]>([]);
  
  const [form, setForm] = useState<Partial<TeacherResponse>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function fetchData(): Promise<void> {
      try {
        const [teachersRes, depsRes, desigsRes] = await Promise.all([
          api.get<TeacherResponse[]>("/admin/users/teachers"),
          api.get<DepartmentResponse[]>("/admin/departments").catch(() => ({ data: [] })),
          api.get<DesignationResponse[]>("/admin/designations").catch(() => ({ data: [] })),
        ]);
        setDepartments(depsRes.data);
        setDesignations(desigsRes.data);
        
        const found = teachersRes.data.find((t) => t.id === id);
        if (found) {
          setTeacher(found);
          setForm({
            employee_id: found.employee_id,
            first_name: found.first_name,
            last_name: found.last_name,
            phone: found.phone,
            qualification: found.qualification,
            specialization: found.specialization,
            experience_years: found.experience_years,
            joining_date: found.joining_date ? new Date(found.joining_date).toISOString().split("T")[0] : undefined,
            department_id: found.department_id,
            designation_id: found.designation_id,
          });
        }
      } catch {
        toast.error("Failed to load teacher data");
      } finally {
        setLoading(false);
      }
    }

    void fetchData();
  }, [id]);

  function set(field: keyof TeacherResponse, value: string | number | undefined): void {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!form.employee_id?.trim() || !form.first_name?.trim() || !form.last_name?.trim() || !form.department_id || !form.designation_id) {
      toast.error("Please fill all required fields");
      return;
    }
    setSaving(true);
    try {
      await api.put(`/admin/users/teachers/${id}`, {
        employee_id: form.employee_id,
        first_name: form.first_name,
        last_name: form.last_name,
        phone: form.phone || undefined,
        qualification: form.qualification || undefined,
        specialization: form.specialization || undefined,
        experience_years: form.experience_years !== undefined && form.experience_years !== null ? Number(form.experience_years) : undefined,
        joining_date: form.joining_date ? new Date(form.joining_date).toISOString() : undefined,
        department_id: form.department_id,
        designation_id: form.designation_id,
      });
      toast.success("Teacher updated successfully");
      router.push(`/admin/users/teachers/${id}`);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Update failed"));
    } finally {
      setSaving(false);
    }
  }

  const deptOptions = departments.map((d) => ({ value: d.id, label: `${d.name} (${d.code})` }));
  const desigOptions = designations.map((d) => ({ value: d.id, label: `${d.name} (${d.code})` }));

  if (loading) return <GlassLoader text="Loading teacher..." />;
  if (!teacher) return <div className="text-center py-20 text-slate-500">Teacher not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Teachers", href: "/admin/users/teachers" },
          { label: teacher.email, href: `/admin/users/teachers/${id}` },
          { label: "Edit" },
        ]}
      />
      <GlassPageHeader title="Edit Teacher Profile" description="Update teacher personal and academic details." />

      <form onSubmit={handleSubmit} className="max-w-4xl space-y-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 space-y-8">
            <GlassCard className="!p-0 overflow-hidden relative">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <User size={20} className="text-slate-300" />
                  Account Info
                </h3>
                <p className="text-sm text-slate-400 mt-1">Core system identifiers.</p>
              </div>
              <div className="p-6 space-y-5">
                <GlassInput label="Email Address" value={teacher.email} disabled />
                <GlassInput
                  label="Employee ID *"
                  value={form.employee_id ?? ""}
                  onChange={(e) => set("employee_id", e.target.value)}
                />
              </div>
            </GlassCard>
          </div>

          <div className="lg:col-span-2">
            <GlassCard className="!p-0 overflow-hidden relative h-full">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <Briefcase size={20} className="text-slate-300" />
                  Professional Profile
                </h3>
                <p className="text-sm text-slate-400 mt-1">Personal and academic details.</p>
              </div>
              <div className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
            <GlassInput
              label="First Name *"
              value={form.first_name ?? ""}
              onChange={(e) => set("first_name", e.target.value)}
            />
            <GlassInput
              label="Last Name *"
              value={form.last_name ?? ""}
              onChange={(e) => set("last_name", e.target.value)}
            />
            <GlassSelect
              label="Department *"
              options={[{ value: "", label: "— Select Department —" }, ...deptOptions]}
              value={form.department_id ?? ""}
              onChange={(v) => set("department_id", v)}
            />
            <GlassSelect
              label="Designation *"
              options={[{ value: "", label: "— Select Designation —" }, ...desigOptions]}
              value={form.designation_id ?? ""}
              onChange={(v) => set("designation_id", v)}
            />
            <GlassInput
              label="Phone (optional)"
              type="tel"
              value={form.phone ?? ""}
              onChange={(e) => set("phone", e.target.value)}
            />
            <GlassInput
              label="Qualification (optional)"
              value={form.qualification ?? ""}
              onChange={(e) => set("qualification", e.target.value)}
            />
            <GlassInput
              label="Specialization (optional)"
              value={form.specialization ?? ""}
              onChange={(e) => set("specialization", e.target.value)}
            />
            <GlassInput
              label="Experience (Years)"
              type="number"
              min="0"
              value={form.experience_years ?? ""}
              onChange={(e) => set("experience_years", e.target.value)}
            />
            <GlassInput
              label="Joining Date (optional)"
              type="date"
              value={form.joining_date ?? ""}
              onChange={(e) => set("joining_date", e.target.value)}
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
