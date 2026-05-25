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
import type { StudentResponse } from "@/types";

export default function StudentsPage(): React.ReactElement {
  const router = useRouter();
  const [students, setStudents] = useState<StudentResponse[]>([]);
  const [filtered, setFiltered] = useState<StudentResponse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStudents(): Promise<void> {
      try {
        const { data } = await api.get<StudentResponse[]>("/admin/users/students");
        setStudents(data);
        setFiltered(data);
      } catch {
        setStudents([]);
        setFiltered([]);
      } finally {
        setLoading(false);
      }
    }
    fetchStudents();
  }, []);

  const handleSearch = useCallback(
    (query: string) => {
      if (!query.trim()) {
        setFiltered(students);
        return;
      }
      const q = query.toLowerCase();
      setFiltered(
        students.filter(
          (s) =>
            s.email.toLowerCase().includes(q) ||
            s.enrollment_number.toLowerCase().includes(q)
        )
      );
    },
    [students]
  );

  const columns: TableColumn<StudentResponse & Record<string, unknown>>[] = [
    { key: "email", header: "Email", sortable: true },
    { key: "enrollment_number", header: "Enrollment #", sortable: true },
    {
      key: "actions",
      header: "Actions",
      render: (row) => (
        <div className="flex items-center gap-2">
          <Link href={`/admin/users/students/${row.id}`} className="glass-btn glass-btn-ghost glass-btn-sm">
            <Eye size={14} /> View
          </Link>
          <Link href={`/admin/users/students/${row.id}/edit`} className="glass-btn glass-btn-ghost glass-btn-sm">
            <Pencil size={14} /> Edit
          </Link>
        </div>
      ),
    },
  ];

  if (loading) return <GlassLoader text="Loading students..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "Students" }]} />
      <GlassPageHeader
        title="Student Directory"
        description={`${students.length} students registered`}
        actions={
          <GlassButton variant="primary" icon={<Plus size={16} />} onClick={() => router.push("/admin/users/students/add")}>
            Add Student
          </GlassButton>
        }
      />
      <div className="mb-6">
        <GlassSearch placeholder="Search by email or enrollment..." onSearch={handleSearch} />
      </div>
      <GlassTable
        columns={columns}
        data={filtered as (StudentResponse & Record<string, unknown>)[]}
        emptyMessage="No students found"
      />
    </div>
  );
}
