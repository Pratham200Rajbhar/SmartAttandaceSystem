"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassTextarea from "@/components/ui/GlassTextarea";
import GlassButton from "@/components/ui/GlassButton";

export default function CreateDepartmentPage(): React.ReactElement {
  const router = useRouter();
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const [head, setHead] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "Department name is required";
    if (!code.trim()) errs.code = "Department code is required";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      await api.post("/admin/departments", {
        name,
        code,
        head: head || undefined,
        description: description || undefined,
      });
      toast.success("Department created successfully");
      router.push("/admin/setup/departments");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Creation failed"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Departments", href: "/admin/setup/departments" },
          { label: "Create" },
        ]}
      />
      <GlassPageHeader title="Create Department" description="Register a new college department" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassInput
            label="Department Name"
            placeholder="e.g. Computer Science"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
          />
          <GlassInput
            label="Code"
            placeholder="e.g. CSE"
            value={code}
            onChange={(e) => setCode(e.target.value)}
            error={errors.code}
          />
          <GlassInput
            label="Head (optional)"
            placeholder="e.g. Dr. Jane Smith"
            value={head}
            onChange={(e) => setHead(e.target.value)}
          />
          <GlassTextarea
            label="Description (optional)"
            placeholder="Brief details about the department..."
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
          <div className="flex justify-end gap-3 pt-4">
            <GlassButton variant="ghost" type="button" onClick={() => router.back()}>
              Cancel
            </GlassButton>
            <GlassButton variant="primary" type="submit" loading={loading}>
              Create Department
            </GlassButton>
          </div>
        </form>
      </GlassCard>
    </div>
  );
}
