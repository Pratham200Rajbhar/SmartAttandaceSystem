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
import type { TeacherResponse } from "@/types";

export default function TeachersPage(): React.ReactElement {
  const router = useRouter();
  const [teachers, setTeachers] = useState<TeacherResponse[]>([]);
  const [filtered, setFiltered] = useState<TeacherResponse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchTeachers(): Promise<void> {
      try {
        const { data } = await api.get<TeacherResponse[]>("/admin/users/teachers");
        setTeachers(data);
        setFiltered(data);
      } catch { setTeachers([]); setFiltered([]); }
      finally { setLoading(false); }
    }
    fetchTeachers();
  }, []);

  const handleSearch = useCallback((query: string) => {
    if (!query.trim()) { setFiltered(teachers); return; }
    const q = query.toLowerCase();
    setFiltered(teachers.filter((t) => t.email.toLowerCase().includes(q) || t.department.toLowerCase().includes(q)));
  }, [teachers]);

  const columns: TableColumn<TeacherResponse & Record<string, unknown>>[] = [
    { key: "email", header: "Email", sortable: true },
    { key: "department", header: "Department", sortable: true },
    { key: "designation", header: "Designation", sortable: true },
    {
      key: "actions", header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <Link href={`/admin/users/teachers/${row.id}`} className="glass-btn glass-btn-ghost glass-btn-sm"><Eye size={14} /> View</Link>
          <Link href={`/admin/users/teachers/${row.id}/edit`} className="glass-btn glass-btn-ghost glass-btn-sm"><Pencil size={14} /> Edit</Link>
        </div>
      ),
    },
  ];

  if (loading) return <GlassLoader text="Loading teachers..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "Teachers" }]} />
      <GlassPageHeader title="Teacher Directory" description={`${teachers.length} teachers registered`}
        actions={<GlassButton variant="primary" icon={<Plus size={16} />} onClick={() => router.push("/admin/users/teachers/add")}>Add Teacher</GlassButton>} />
      <div className="mb-6"><GlassSearch placeholder="Search by email or department..." onSearch={handleSearch} /></div>
      <GlassTable columns={columns} data={filtered as (TeacherResponse & Record<string, unknown>)[]} emptyMessage="No teachers found" />
    </div>
  );
}
