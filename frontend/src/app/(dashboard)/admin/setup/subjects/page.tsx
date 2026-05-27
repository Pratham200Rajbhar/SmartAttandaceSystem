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
import type { SubjectResponse } from "@/types";

export default function SubjectsPage(): React.ReactElement {
  const router = useRouter();
  const [subjects, setSubjects] = useState<SubjectResponse[]>([]);
  const [filtered, setFiltered] = useState<SubjectResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchSubjects = useCallback(async (): Promise<void> => {
    try {
      const { data } = await api.get<SubjectResponse[]>("/admin/subjects");
      setSubjects(data);
      setFiltered(data);
    } catch {
      setSubjects([]);
      setFiltered([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      await fetchSubjects();
    })();
  }, [fetchSubjects]);

  const handleSearch = useCallback((q: string) => {
    if (!q.trim()) {
      setFiltered(subjects);
      return;
    }
    const lq = q.toLowerCase();
    setFiltered(
      subjects.filter(
        (s) =>
          s.name.toLowerCase().includes(lq) ||
          s.code.toLowerCase().includes(lq)
      )
    );
  }, [subjects]);

  async function handleDelete(): Promise<void> {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await api.delete(`/admin/subjects/${deleteTarget}`);
      toast.success("Subject deleted successfully");
      setDeleteTarget(null);
      await fetchSubjects();
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Delete failed"));
    } finally {
      setDeleting(false);
    }
  }

  const columns: TableColumn<SubjectResponse & Record<string, unknown>>[] = [
    { key: "name", header: "Subject Name", sortable: true },
    { key: "code", header: "Subject Code", sortable: true },
    { key: "description", header: "Description", render: (r) => <span>{String(r.description || "—")}</span> },
    {
      key: "actions",
      header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={() => router.push(`/admin/setup/subjects/${row.id}/edit`)}
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

  if (loading) return <GlassLoader text="Loading subjects..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[
          { label: "Admin", href: "/admin/dashboard" },
          { label: "Setup" },
          { label: "Subjects" },
        ]}
      />
      <GlassPageHeader
        title="Subjects"
        description={`${subjects.length} subjects registered`}
        actions={
          <GlassButton
            variant="primary"
            icon={<Plus size={16} />}
            onClick={() => router.push("/admin/setup/subjects/create")}
          >
            Add Subject
          </GlassButton>
        }
      />
      <div className="mb-6">
        <GlassSearch placeholder="Search subjects..." onSearch={handleSearch} />
      </div>
      <GlassTable
        columns={columns}
        data={filtered as (SubjectResponse & Record<string, unknown>)[]}
        emptyMessage="No subjects found"
      />
      <GlassConfirmDialog
        isOpen={!!deleteTarget}
        title="Delete Subject"
        message="Are you sure you want to delete this subject? This action cannot be undone."
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  );
}
