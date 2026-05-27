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
import type { DepartmentResponse } from "@/types";

export default function DepartmentsPage(): React.ReactElement {
  const router = useRouter();
  const [departments, setDepartments] = useState<DepartmentResponse[]>([]);
  const [filtered, setFiltered] = useState<DepartmentResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchDepartments = useCallback(async (): Promise<void> => {
    try {
      const { data } = await api.get<DepartmentResponse[]>("/admin/departments");
      setDepartments(data);
      setFiltered(data);
    } catch {
      setDepartments([]);
      setFiltered([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      await fetchDepartments();
    })();
  }, [fetchDepartments]);

  const handleSearch = useCallback((q: string) => {
    if (!q.trim()) {
      setFiltered(departments);
      return;
    }
    const lq = q.toLowerCase();
    setFiltered(
      departments.filter(
        (d) =>
          d.name.toLowerCase().includes(lq) ||
          d.code.toLowerCase().includes(lq)
      )
    );
  }, [departments]);

  async function handleDelete(): Promise<void> {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/departments/${deleteTarget}`);
      toast.success("Department deleted successfully");
      setDeleteTarget(null);
      await fetchDepartments();
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Delete failed"));
    } finally {
      setDeleting(false);
    }
  }

  const columns: TableColumn<DepartmentResponse & Record<string, unknown>>[] = [
    { key: "name", header: "Name", sortable: true },
    { key: "code", header: "Code", sortable: true },
    { key: "head", header: "Head", render: (r) => <span>{String(r.head || "—")}</span> },
    { key: "description", header: "Description", render: (r) => <span>{String(r.description || "—")}</span> },
    {
      key: "actions",
      header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={() => router.push(`/admin/setup/departments/${row.id}/edit`)}
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

  if (loading) return <GlassLoader text="Loading departments..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Departments" },
        ]}
      />
      <GlassPageHeader
        title="Departments"
        description={`${departments.length} departments registered`}
        actions={
          <GlassButton
            variant="primary"
            icon={<Plus size={16} />}
            onClick={() => router.push("/admin/setup/departments/create")}
          >
            Add Department
          </GlassButton>
        }
      />
      <div className="mb-6">
        <GlassSearch placeholder="Search departments..." onSearch={handleSearch} />
      </div>
      <GlassTable
        columns={columns}
        data={filtered as (DepartmentResponse & Record<string, unknown>)[]}
        emptyMessage="No departments found"
      />
      <GlassConfirmDialog
        isOpen={!!deleteTarget}
        title="Delete Department"
        message="Are you sure you want to delete this department? This action cannot be undone."
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  );
}
