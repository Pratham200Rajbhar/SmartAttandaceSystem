"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { ClassroomResponse } from "@/types";

export default function EditClassroomPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [classroom, setClassroom] = useState<ClassroomResponse | null>(null);
  const [name, setName] = useState("");
  const [building, setBuilding] = useState("");
  const [capacity, setCapacity] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    async function fetch(): Promise<void> {
      try {
        const { data } = await api.get<ClassroomResponse>(`/admin/classrooms/${id}`);
        setClassroom(data);
        setName(data.name);
        setBuilding(data.building || "");
        setCapacity(data.capacity ? String(data.capacity) : "");
      } catch {
        toast.error("Failed to load classroom");
      } finally {
        setLoading(false);
      }
    }
    fetch();
  }, [id]);

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "Classroom name is required";
    if (capacity.trim() && (isNaN(Number(capacity)) || Number(capacity) < 1)) {
      errs.capacity = "Capacity must be a positive integer";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;
    setSaving(true);
    try {
      await api.put(`/admin/classrooms/${id}`, {
        name,
        building: building || undefined,
        capacity: capacity ? Number(capacity) : null,
      });
      toast.success("Classroom updated successfully");
      router.push("/admin/setup/classrooms");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Update failed"));
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <GlassLoader text="Loading classroom info..." />;
  if (!classroom) return <div className="text-center py-20 text-slate-500">Classroom not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Classrooms", href: "/admin/setup/classrooms" },
          { label: classroom.name },
          { label: "Edit" },
        ]}
      />
      <GlassPageHeader title="Edit Classroom" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassInput
            label="Classroom Name / Room Number"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
          />
          <GlassInput
            label="Building / Block"
            value={building}
            onChange={(e) => setBuilding(e.target.value)}
          />
          <GlassInput
            label="Student Capacity"
            value={capacity}
            onChange={(e) => setCapacity(e.target.value)}
            error={errors.capacity}
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
