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
import type { DesignationResponse } from "@/types";

export default function DesignationsPage(): React.ReactElement {
  const router = useRouter();
  const [designations, setDesignations] = useState<DesignationResponse[]>([]);
  const [filtered, setFiltered] = useState<DesignationResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchDesignations = useCallback(async (): Promise<void> => {
    try {
      const { data } = await api.get<DesignationResponse[]>("/admin/designations");
      setDesignations(data);
      setFiltered(data);
    } catch {
      setDesignations([]);
      setFiltered([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      await fetchDesignations();
    })();
  }, [fetchDesignations]);

  const handleSearch = useCallback((q: string) => {
    if (!q.trim()) {
      setFiltered(designations);
      return;
    }
    const lq = q.toLowerCase();
    setFiltered(
      designations.filter(
        (d) =>
          d.name.toLowerCase().includes(lq) ||
          d.code.toLowerCase().includes(lq)
      )
    );
  }, [designations]);

  async function handleDelete(): Promise<void> {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/designations/${deleteTarget}`);
      toast.success("Designation deleted successfully");
      setDeleteTarget(null);
      await fetchDesignations();
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Delete failed"));
    } finally {
      setDeleting(false);
    }
  }

  const columns: TableColumn<DesignationResponse & Record<string, unknown>>[] = [
    { key: "name", header: "Designation Name", sortable: true },
    { key: "code", header: "Designation Code", sortable: true },
    { key: "description", header: "Description", render: (r) => <span>{String(r.description || "—")}</span> },
    {
      key: "actions",
      header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={() => router.push(`/admin/setup/designations/${row.id}/edit`)}
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

  if (loading) return <GlassLoader text="Loading designations..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Designations" },
        ]}
      />
      <GlassPageHeader
        title="Designations"
        description={`${designations.length} designations registered`}
        actions={
          <GlassButton
            variant="primary"
            icon={<Plus size={16} />}
            onClick={() => router.push("/admin/setup/designations/create")}
          >
            Add Designation
          </GlassButton>
        }
      />
      <div className="mb-6">
        <GlassSearch placeholder="Search designations..." onSearch={handleSearch} />
      </div>
      <GlassTable
        columns={columns}
        data={filtered as (DesignationResponse & Record<string, unknown>)[]}
        emptyMessage="No designations found"
      />
      <GlassConfirmDialog
        isOpen={!!deleteTarget}
        title="Delete Designation"
        message="Are you sure you want to delete this designation? This action cannot be undone."
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  );
}
