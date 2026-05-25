"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import toast from "react-hot-toast";
import api from "@/lib/api";
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

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!name.trim() || !code.trim()) { toast.error("Name and code are required"); return; }
    setLoading(true);
    try {
      await api.post("/admin/departments", { name, code, head: head || undefined, description: description || undefined });
      toast.success("Department created");
      router.push("/admin/departments");
    } catch (err: unknown) {
      toast.error((err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || "Creation failed");
    } finally { setLoading(false); }
  }

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "Departments", href: "/admin/departments" }, { label: "Create" }]} />
      <GlassPageHeader title="Create Department" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassInput label="Department Name" placeholder="e.g. Computer Science" value={name} onChange={(e) => setName(e.target.value)} />
          <GlassInput label="Code" placeholder="e.g. CSE" value={code} onChange={(e) => setCode(e.target.value)} />
          <GlassInput label="Head (optional)" placeholder="e.g. Dr. Smith" value={head} onChange={(e) => setHead(e.target.value)} />
          <GlassTextarea label="Description (optional)" placeholder="Brief description..." value={description} onChange={(e) => setDescription(e.target.value)} />
          <div className="flex justify-end gap-3 pt-4">
            <GlassButton variant="ghost" type="button" onClick={() => router.back()}>Cancel</GlassButton>
            <GlassButton variant="primary" type="submit" loading={loading}>Create Department</GlassButton>
          </div>
        </form>
      </GlassCard>
    </div>
  );
}
