"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassTextarea from "@/components/ui/GlassTextarea";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { DepartmentResponse } from "@/types";

export default function EditDepartmentPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [dept, setDept] = useState<DepartmentResponse | null>(null);
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const [head, setHead] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    async function fetch(): Promise<void> {
      try {
        const { data } = await api.get<DepartmentResponse>(`/admin/departments/${id}`);
        setDept(data);
        setName(data.name);
        setCode(data.code);
        setHead(data.head || "");
        setDescription(data.description || "");
      } catch {
        toast.error("Failed to load department");
      } finally {
        setLoading(false);
      }
    }
    fetch();
  }, [id]);

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
    setSaving(true);
    try {
      await api.put(`/admin/departments/${id}`, {
        name,
        code,
        head: head || undefined,
        description: description || undefined,
      });
      toast.success("Department updated successfully");
      router.push("/admin/setup/departments");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Update failed"));
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <GlassLoader text="Loading department info..." />;
  if (!dept) return <div className="text-center py-20 text-slate-500">Department not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Departments", href: "/admin/setup/departments" },
          { label: dept.name },
          { label: "Edit" },
        ]}
      />
      <GlassPageHeader title="Edit Department" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassInput
            label="Department Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
          />
          <GlassInput
            label="Code"
            value={code}
            onChange={(e) => setCode(e.target.value)}
            error={errors.code}
          />
          <GlassInput
            label="Head"
            value={head}
            onChange={(e) => setHead(e.target.value)}
          />
          <GlassTextarea
            label="Description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
          <div className="flex justify-end gap-3 pt-4">
            <GlassButton variant="ghost" type="button" onClick={() => router.back()}>
              Cancel
            </GlassButton>
            <GlassButton variant="primary" type="submit" loading={saving}>
              Save Changes
            </GlassButton>
          </div>
        </form>
      </GlassCard>
    </div>
  );
}
