"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { User, Briefcase, PlusCircle, X } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassButton from "@/components/ui/GlassButton";
import type { TeacherCreate, DepartmentResponse, DesignationResponse } from "@/types";

type FormErrors = Partial<Record<keyof TeacherCreate, string>>;

export default function AddTeacherPage(): React.ReactElement {
  const router = useRouter();
  const [departments, setDepartments] = useState<DepartmentResponse[]>([]);
  const [designations, setDesignations] = useState<DesignationResponse[]>([]);
  const [form, setForm] = useState<TeacherCreate>({
    email: "",
    password: "",
    employee_id: "",
    first_name: "",
    last_name: "",
    department_id: "",
    designation_id: "",
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function fetchMasterData(): Promise<void> {
      try {
        const [deptsRes, desigRes] = await Promise.all([
          api.get<DepartmentResponse[]>("/admin/departments"),
          api.get<DesignationResponse[]>("/admin/designations"),
        ]);
        setDepartments(deptsRes.data);
        setDesignations(desigRes.data);
      } catch {
        toast.error("Could not load departments/designations.");
      }
    }
    void fetchMasterData();
  }, []);

  function set(field: keyof TeacherCreate, value: string | number | undefined): void {
    setForm((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) setErrors((prev) => ({ ...prev, [field]: undefined }));
  }

  function validate(): boolean {
    const errs: FormErrors = {};
    if (!form.email.trim()) errs.email = "Email is required";
    if (!form.password || form.password.length < 8) errs.password = "Minimum 8 characters";
    if (!form.employee_id.trim()) errs.employee_id = "Employee ID is required";
    if (!form.first_name.trim()) errs.first_name = "First name is required";
    if (!form.last_name.trim()) errs.last_name = "Last name is required";
    if (!form.department_id) errs.department_id = "Department is required";
    if (!form.designation_id) errs.designation_id = "Designation is required";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      await api.post("/admin/users/teacher", form);
      toast.success("Teacher created successfully");
      router.push("/admin/users/teachers");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to create teacher"));
    } finally {
      setLoading(false);
    }
  }

  const deptOptions = [
    { value: "", label: "— Select Department —" },
    ...departments.map((d) => ({ value: d.id, label: `${d.name} (${d.code})` })),
  ];

  const desigOptions = [
    { value: "", label: "— Select Designation —" },
    ...designations.map((d) => ({ value: d.id, label: `${d.name} (${d.code})` })),
  ];

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Teachers", href: "/admin/users/teachers" },
          { label: "Add New" },
        ]}
      />
      <GlassPageHeader
        title="Add Teacher"
        description="Create a new teacher account with FK-linked department and designation"
      />

      <form onSubmit={handleSubmit} className="max-w-4xl space-y-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 space-y-8">
            <GlassCard className="!p-0 overflow-hidden relative">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-500 to-indigo-500"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <User size={20} className="text-slate-300" />
                  Account Info
                </h3>
                <p className="text-sm text-slate-400 mt-1">Core system credentials.</p>
              </div>
              <div className="p-6 space-y-5">
                <GlassInput
                  label="Email Address"
                  type="email"
                  placeholder="teacher@university.edu"
                  value={form.email}
                  onChange={(e) => set("email", e.target.value)}
                  error={errors.email}
                />
                <GlassInput
                  label="Password"
                  type="password"
                  placeholder="Minimum 8 characters"
                  value={form.password}
                  onChange={(e) => set("password", e.target.value)}
                  error={errors.password}
                />
                <GlassInput
                  label="Employee ID"
                  placeholder="e.g. EMP2024001"
                  value={form.employee_id}
                  onChange={(e) => set("employee_id", e.target.value)}
                  error={errors.employee_id}
                />
              </div>
            </GlassCard>
          </div>

          <div className="lg:col-span-2 space-y-8">
            <GlassCard className="!p-0 overflow-hidden relative">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-emerald-400 to-teal-500"></div>
              <div className="p-6 border-b border-white/5 bg-white/[0.01]">
                <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                  <Briefcase size={20} className="text-slate-300" />
                  Professional Profile
                </h3>
                <p className="text-sm text-slate-400 mt-1">Personal and academic details.</p>
              </div>
              <div className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
            <GlassInput
              label="First Name"
              placeholder="e.g. Ravi"
              value={form.first_name}
              onChange={(e) => set("first_name", e.target.value)}
              error={errors.first_name}
            />
            <GlassInput
              label="Last Name"
              placeholder="e.g. Shankar"
              value={form.last_name}
              onChange={(e) => set("last_name", e.target.value)}
              error={errors.last_name}
            />
            <GlassInput
              label="Phone (optional)"
              type="tel"
              placeholder="+91 98765 43210"
              value={form.phone ?? ""}
              onChange={(e) => set("phone", e.target.value || undefined)}
            />
            <GlassInput
              label="Joining Date (optional)"
              type="date"
              value={form.joining_date ?? ""}
              onChange={(e) => set("joining_date", e.target.value || undefined)}
            />
              </div>
            </GlassCard>
            
            <GlassCard className="!p-0 overflow-hidden relative">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-purple-500 to-pink-500"></div>
              <div className="p-6 grid grid-cols-1 sm:grid-cols-2 gap-6">
            <GlassSelect
              label="Department"
              options={deptOptions}
              value={form.department_id}
              onChange={(v) => set("department_id", v)}
              error={errors.department_id}
            />
            <GlassSelect
              label="Designation"
              options={desigOptions}
              value={form.designation_id}
              onChange={(v) => set("designation_id", v)}
              error={errors.designation_id}
            />
            <GlassInput
              label="Qualification (optional)"
              placeholder="e.g. Ph.D, M.Tech"
              value={form.qualification ?? ""}
              onChange={(e) => set("qualification", e.target.value || undefined)}
            />
            <GlassInput
              label="Specialization (optional)"
              placeholder="e.g. Machine Learning"
              value={form.specialization ?? ""}
              onChange={(e) => set("specialization", e.target.value || undefined)}
            />
            <div className="sm:col-span-2">
              <GlassInput
                label="Experience (years, optional)"
                type="number"
                placeholder="e.g. 5"
                value={form.experience_years !== undefined ? String(form.experience_years) : ""}
                onChange={(e) =>
                  set("experience_years", e.target.value ? Number(e.target.value) : undefined)
                }
              />
            </div>
            </div>
          </GlassCard>
        </div>
      </div>

        <div className="flex justify-end gap-4 pt-4 pb-12">
          <GlassButton variant="ghost" type="button" onClick={() => router.back()} icon={<X size={16} />}>
            Cancel
          </GlassButton>
          <GlassButton variant="primary" type="submit" loading={loading} icon={<PlusCircle size={16} />}>
            Create Teacher
          </GlassButton>
        </div>
      </form>
    </div>
  );
}
