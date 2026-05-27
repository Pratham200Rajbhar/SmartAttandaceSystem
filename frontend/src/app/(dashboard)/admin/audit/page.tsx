"use client";

import React, { useEffect, useState, useCallback } from "react";
import api from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassTable, { type TableColumn } from "@/components/ui/GlassTable";
import GlassSearch from "@/components/ui/GlassSearch";
import GlassBadge from "@/components/ui/GlassBadge";
import GlassLoader from "@/components/ui/GlassLoader";
import type { AuditLogResponse } from "@/types";
import type { BadgeVariant } from "@/components/ui/GlassBadge";

const SEVERITY_VARIANT: Record<string, BadgeVariant> = {
  HIGH: "danger",
  CRITICAL: "danger",
  MEDIUM: "warning",
  LOW: "info",
};

export default function AuditPage(): React.ReactElement {
  const [logs, setLogs] = useState<AuditLogResponse[]>([]);
  const [filtered, setFiltered] = useState<AuditLogResponse[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try { const { data } = await api.get<AuditLogResponse[]>("/admin/audit"); setLogs(data); setFiltered(data); }
      catch { setLogs([]); setFiltered([]); }
      finally { setLoading(false); }
    }
    fetch();
  }, []);

  const handleSearch = useCallback((q: string) => {
    if (!q.trim()) { setFiltered(logs); return; }
    const lq = q.toLowerCase();
    setFiltered(logs.filter((l) => l.eventType.toLowerCase().includes(lq) || l.actor.toLowerCase().includes(lq) || l.description.toLowerCase().includes(lq)));
  }, [logs]);

  const columns: TableColumn<AuditLogResponse & Record<string, unknown>>[] = [
    { key: "timestamp", header: "Time", sortable: true, render: (r) => <span className="text-xs text-slate-400">{new Date(String(r.timestamp)).toLocaleString()}</span> },
    { key: "eventType", header: "Event", sortable: true },
    { key: "severity", header: "Severity", render: (r) => <GlassBadge variant={SEVERITY_VARIANT[String(r.severity)] ?? "info"}>{String(r.severity)}</GlassBadge> },
    { key: "actor", header: "Actor" },
    { key: "target", header: "Target" },
    { key: "description", header: "Description", render: (r) => <span className="text-sm text-slate-400 max-w-xs truncate block">{String(r.description)}</span> },
  ];

  if (loading) return <GlassLoader text="Loading audit log..." />;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb items={[{ label: "Admin", href: "/admin/dashboard" }, { label: "Audit Log" }]} />
      <GlassPageHeader title="System Audit Trail" description={`${logs.length} events recorded`} />
      <div className="mb-6"><GlassSearch placeholder="Search events..." onSearch={handleSearch} /></div>
      <GlassTable columns={columns} data={filtered as (AuditLogResponse & Record<string, unknown>)[]} emptyMessage="No audit events" pageSize={15} />
    </div>
  );
}
