"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassButton from "@/components/ui/GlassButton";

export default function CreateClassroomPage(): React.ReactElement {
  const router = useRouter();
  const [name, setName] = useState("");
  const [building, setBuilding] = useState("");
  const [capacity, setCapacity] = useState("");
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = "Classroom name or number is required";
    if (capacity.trim() && (isNaN(Number(capacity)) || Number(capacity) < 1)) {
      errs.capacity = "Capacity must be a positive integer";
    }
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    try {
      await api.post("/admin/classrooms", {
        name,
        building: building || undefined,
        capacity: capacity ? Number(capacity) : undefined,
      });
      toast.success("Classroom created successfully");
      router.push("/admin/setup/classrooms");
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
          { label: "Classrooms", href: "/admin/setup/classrooms" },
          { label: "Create" },
        ]}
      />
      <GlassPageHeader title="Create Classroom" description="Register a new classroom venue" />
      <GlassCard className="max-w-xl">
        <form onSubmit={handleSubmit} className="space-y-5">
          <GlassInput
            label="Classroom Name / Room Number"
            placeholder="e.g. Room 301, Lab B"
            value={name}
            onChange={(e) => setName(e.target.value)}
            error={errors.name}
          />
          <GlassInput
            label="Building / Block (optional)"
            placeholder="e.g. Science Block"
            value={building}
            onChange={(e) => setBuilding(e.target.value)}
          />
          <GlassInput
            label="Student Capacity (optional)"
            placeholder="e.g. 60"
            value={capacity}
            onChange={(e) => setCapacity(e.target.value)}
            error={errors.capacity}
          />
          <div className="flex justify-end gap-3 pt-4">
            <GlassButton variant="ghost" type="button" onClick={() => router.back()}>
              Cancel
            </GlassButton>
            <GlassButton variant="primary" type="submit" loading={loading}>
              Create Classroom
            </GlassButton>
          </div>
        </form>
      </GlassCard>
    </div>
  );
}
