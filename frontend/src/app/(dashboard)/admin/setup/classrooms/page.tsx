"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Plus, Pencil, Trash2 } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassSearch from "@/components/ui/GlassSearch";
import GlassButton from "@/components/ui/GlassButton";
import GlassConfirmDialog from "@/components/ui/GlassConfirmDialog";
import GlassLoader from "@/components/ui/GlassLoader";
import type { ClassroomResponse } from "@/types";

export default function ClassroomsPage(): React.ReactElement {
  const router = useRouter();
  const [classrooms, setClassrooms] = useState<ClassroomResponse[]>([]);
  const [filtered, setFiltered] = useState<ClassroomResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchClassrooms = useCallback(async (): Promise<void> => {
    try {
      const { data } = await api.get<ClassroomResponse[]>("/admin/classrooms");
      setClassrooms(data);
      setFiltered(data);
    } catch {
      setClassrooms([]);
      setFiltered([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      await fetchClassrooms();
    })();
  }, [fetchClassrooms]);

  const handleSearch = useCallback((q: string) => {
    if (!q.trim()) {
      setFiltered(classrooms);
      return;
    }
    const lq = q.toLowerCase();
    setFiltered(
      classrooms.filter(
        (c) =>
          c.name.toLowerCase().includes(lq) ||
          (c.building && c.building.toLowerCase().includes(lq))
      )
    );
  }, [classrooms]);

  async function handleDelete(): Promise<void> {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/classrooms/${deleteTarget}`);
      toast.success("Classroom deleted successfully");
      setDeleteTarget(null);
      await fetchClassrooms();
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Delete failed"));
    } finally {
      setDeleting(false);
    }
  }

  const columns: TableColumn<ClassroomResponse & Record<string, unknown>>[] = [
    { key: "name", header: "Classroom Name", sortable: true },
    { key: "building", header: "Building", render: (r) => <span>{String(r.building || "—")}</span> },
    { key: "capacity", header: "Capacity", render: (r) => <span>{r.capacity ? `${String(r.capacity)} students` : "—"}</span> },
    {
      key: "actions",
      header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={() => router.push(`/admin/setup/classrooms/${row.id}/edit`)}
            className="glass-btn glass-btn-ghost glass-btn-sm"
          >
            <Pencil size={14} /> Edit
          </button>
          <button
            onClick={() => setDeleteTarget(String(row.id))}
            className="glass-btn glass-btn-ghost glass-btn-sm text-slate-300"
          >
            <Trash2 size={14} />
          </button>
        </div>
      ),
    },
  ];

  if (loading) return <GlassLoader text="Loading classrooms..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Classrooms" },
        ]}
      />
      <GlassPageHeader
        title="Classrooms"
        description={`${classrooms.length} classrooms registered`}
        actions={
          <GlassButton
            variant="primary"
            icon={<Plus size={16} />}
            onClick={() => router.push("/admin/setup/classrooms/create")}
          >
            Add Classroom
          </GlassButton>
        }
      />
      <div className="mb-6">
        <GlassSearch placeholder="Search classrooms..." onSearch={handleSearch} />
      </div>
      <GlassTable
        columns={columns}
        data={filtered as (ClassroomResponse & Record<string, unknown>)[]}
        emptyMessage="No classrooms found"
      />
      <GlassConfirmDialog
        isOpen={!!deleteTarget}
        title="Delete Classroom"
        message="Are you sure you want to delete this classroom? This action cannot be undone."
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  );
}
