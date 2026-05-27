"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { User, GraduationCap, PlusCircle, X } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassButton from "@/components/ui/GlassButton";
import type { StudentCreate, DepartmentResponse } from "@/types";

type FormErrors = Partial<Record<keyof StudentCreate, string>>;

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

export default function AddStudentPage(): React.ReactElement {
  const router = useRouter();
  const [departments, setDepartments] = useState<DepartmentResponse[]>([]);
  const [form, setForm] = useState<StudentCreate>({
    email: "",
    password: "",
    enrollment_number: "",
    first_name: "",
    last_name: "",
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function fetchDepartments(): Promise<void> {
      try {
        const { data } = await api.get<DepartmentResponse[]>("/admin/departments");
        setDepartments(data);
      } catch {
        
      }
    }
    void fetchDepartments();
  }, []);

  function set(field: keyof StudentCreate, value: string | number | undefined): void {
    setForm((prev) => ({ ...prev, [field]: value }));
    if (errors[field]) setErrors((prev) => ({ ...prev, [field]: undefined }));
  }

  function validate(): boolean {
    const errs: FormErrors = {};
    if (!form.email.trim()) errs.email = "Email is required";
    if (!form.password || form.password.length < 8) errs.password = "Minimum 8 characters";
    if (!form.enrollment_number.trim()) errs.enrollment_number = "Enrollment number is required";
    if (!form.first_name.trim()) errs.first_name = "First name is required";
    if (!form.last_name.trim()) errs.last_name = "Last name is required";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      await api.post("/admin/users/student", form);
      toast.success("Student created successfully");
      router.push("/admin/users/students");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to create student"));
    } finally {
      setLoading(false);
    }
  }

  const deptOptions = [
    { value: "", label: "None — assign later" },
    ...departments.map((d) => ({ value: d.id, label: `${d.name} (${d.code})` })),
  ];

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Students", href: "/admin/users/students" },
          { label: "Add New" },
        ]}
      />
      <GlassPageHeader title="Add Student" description="Create a new student account and profile" />

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
                  placeholder="student@university.edu"
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
                  label="Enrollment Number"
                  placeholder="e.g. EN2024001"
                  value={form.enrollment_number}
                  onChange={(e) => set("enrollment_number", e.target.value)}
                  error={errors.enrollment_number}
                />
              </div>
            </GlassCard>
          </div>

          <div className="lg:col-span-2">
            <GlassCard className="!p-0 overflow-hidden relative h-full">
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-emerald-400 to-teal-500"></div>
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
              placeholder="e.g. Aanya"
              value={form.first_name}
              onChange={(e) => set("first_name", e.target.value)}
              error={errors.first_name}
            />
            <GlassInput
              label="Last Name"
              placeholder="e.g. Sharma"
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
            <GlassSelect
              label="Gender (optional)"
              options={[{ value: "", label: "— Select —" }, ...GENDER_OPTIONS]}
              value={form.gender ?? ""}
              onChange={(v) => set("gender", v || undefined)}
            />
            <GlassInput
              label="Date of Birth (optional)"
              type="date"
              value={form.date_of_birth ?? ""}
              onChange={(e) => set("date_of_birth", e.target.value || undefined)}
            />
            <GlassSelect
              label="Semester (optional)"
              options={[{ value: "", label: "— Select —" }, ...SEMESTER_OPTIONS]}
              value={form.semester ? String(form.semester) : ""}
              onChange={(v) => set("semester", v ? Number(v) : undefined)}
            />
            <GlassInput
              label="Batch (optional)"
              placeholder="e.g. 2022-2026"
              value={form.batch ?? ""}
              onChange={(e) => set("batch", e.target.value || undefined)}
            />
            <GlassSelect
              label="Department (optional)"
              options={deptOptions}
              value={form.department_id ?? ""}
              onChange={(v) => set("department_id", v || undefined)}
            />
              </div>
            </GlassCard>
          </div>
        </div>

        <div className="flex justify-end gap-4 pt-4 pb-12">
          <GlassButton variant="ghost" type="button" onClick={() => router.back()} icon={<X size={16} />}>
            Cancel
          </GlassButton>
          <GlassButton variant="primary" type="submit" loading={loading} icon={<PlusCircle size={16} />}>
            Create Student
          </GlassButton>
        </div>
      </form>
    </div>
  );
}
