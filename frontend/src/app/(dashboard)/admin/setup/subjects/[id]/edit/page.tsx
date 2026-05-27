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
import type { SubjectResponse } from "@/types";

export default function EditSubjectPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [subject, setSubject] = useState<SubjectResponse | null>(null);
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const [description, setDescription] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    async function fetch(): Promise<void> {
      try {
        const { data } = await api.get<SubjectResponse>(`/admin/subjects/${id}`);
        setSubject(data);
        setName(data.name);
        setCode(data.code);
        setDescription(data.description || "");
      } catch {
        toast.error("Failed to load subject");
      } finally {
        setLoading(false);
      }
    }
    fetch();
  }, [id]);

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "Subject name is required";
    if (!code.trim()) errs.code = "Subject code is required";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;
    setSaving(true);
    try {
      await api.put(`/admin/subjects/${id}`, {
        name,
        code,
        description: description || undefined,
      });
      toast.success("Subject updated successfully");
      router.push("/admin/setup/subjects");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Update failed"));
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <GlassLoader text="Loading subject info..." />;
  if (!subject) return <div className="text-center py-20 text-slate-500">Subject not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Subjects", href: "/admin/setup/subjects" },
          { label: subject.name },
          { label: "Edit" },
        ]}
      />
      <GlassPageHeader title="Edit Subject" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassInput
            label="Subject Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
          />
          <GlassInput
            label="Subject Code"
            value={code}
            onChange={(e) => setCode(e.target.value)}
            error={errors.code}
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
