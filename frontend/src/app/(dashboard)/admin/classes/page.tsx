"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Plus, Eye, Pencil } from "lucide-react";
import Link from "next/link";
import api from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassSearch from "@/components/ui/GlassSearch";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { ClassResponse } from "@/types";

export default function ClassesPage(): React.ReactElement {
  const router = useRouter();
  const [classes, setClasses] = useState<ClassResponse[]>([]);
  const [filtered, setFiltered] = useState<ClassResponse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try { const { data } = await api.get<ClassResponse[]>("/admin/classes"); setClasses(data); setFiltered(data); }
      catch { setClasses([]); setFiltered([]); }
      finally { setLoading(false); }
    }
    fetch();
  }, []);

  const handleSearch = useCallback((q: string) => {
    if (!q.trim()) { setFiltered(classes); return; }
    const lq = q.toLowerCase();
    setFiltered(classes.filter((c) =>
      c.name.toLowerCase().includes(lq) ||
      c.subject_name.toLowerCase().includes(lq) ||
      c.subject_code.toLowerCase().includes(lq)
    ));
  }, [classes]);

  const columns: TableColumn<ClassResponse & Record<string, unknown>>[] = [
    { key: "name", header: "Class Name", sortable: true },
    { key: "subject_name", header: "Subject", sortable: true, render: (r) => <span>{String(r.subject_name)}<span className="ml-1 text-xs text-slate-500">({String(r.subject_code)})</span></span> },
    { key: "enrolled_count", header: "Enrolled", render: (r) => <span className="font-mono text-sm">{String(r.enrolled_count)}{r.max_students ? ` / ${String(r.max_students)}` : ""}</span> },
    { key: "classroom_name", header: "Classroom", render: (r) => <span className="text-slate-400 text-sm">{String(r.classroom_name || "—")}</span> },
    {
      key: "actions", header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <Link href={`/admin/classes/${row.id}`} className="glass-btn glass-btn-ghost glass-btn-sm"><Eye size={14} /> View</Link>
          <Link href={`/admin/classes/${row.id}/edit`} className="glass-btn glass-btn-ghost glass-btn-sm"><Pencil size={14} /> Edit</Link>
        </div>
      ),
    },
  ];

  if (loading) return <GlassLoader text="Loading classes..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "Classes" }]} />
      <GlassPageHeader title="Class Directory" description={`${classes.length} classes registered`}
        actions={<GlassButton variant="primary" icon={<Plus size={16} />} onClick={() => router.push("/admin/classes/create")}>Create Class</GlassButton>} />
      <div className="mb-6"><GlassSearch placeholder="Search classes..." onSearch={handleSearch} /></div>
      <GlassTable columns={columns} data={filtered as (ClassResponse & Record<string, unknown>)[]} emptyMessage="No classes found" />
    </div>
  );
}
