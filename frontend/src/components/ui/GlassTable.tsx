"use client";

import React, { useState, useMemo } from "react";
import { ChevronLeft, ChevronRight, ArrowUpDown } from "lucide-react";

export interface TableColumn<T> {
  key: string;
  header: string;
  render?: (row: T) => React.ReactNode;
  sortable?: boolean;
}

interface GlassTableProps<T> {
  columns: TableColumn<T>[];
  data: T[];
  pageSize?: number;
  emptyMessage?: string;
  onRowClick?: (row: T) => void;
}

function sortByColumn<T extends Record<string, unknown>>(a: T, b: T, key: string, asc: boolean): number {
  const aVal = a[key];
  const bVal = b[key];
  if (aVal === bVal) return 0;
  if (aVal == null) return 1;
  if (bVal == null) return -1;
  const cmp = String(aVal).localeCompare(String(bVal), undefined, { numeric: true });
  return asc ? cmp : -cmp;
}

export default function GlassTable<T extends Record<string, unknown>>({
  columns,
  data,
  pageSize = 10,
  emptyMessage = "No data found",
  onRowClick,
}: GlassTableProps<T>): React.ReactElement {
  const [page, setPage] = useState(0);
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortAsc, setSortAsc] = useState(true);

  const sorted = useMemo(() => {
    if (!sortKey) return data;
    return [...data].sort((a, b) => sortByColumn(a, b, sortKey, sortAsc));
  }, [data, sortKey, sortAsc]);

  const totalPages = Math.max(1, Math.ceil(sorted.length / pageSize));
  const paginated = sorted.slice(page * pageSize, (page + 1) * pageSize);

  function handleSort(key: string): void {
    if (sortKey === key) {
      setSortAsc(!sortAsc);
    } else {
      setSortKey(key);
      setSortAsc(true);
    }
    setPage(0);
  }

  if (data.length === 0) {
    return (
      <div className="glass-panel-static p-12 text-center">
        <p className="text-slate-500 text-sm">{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className="glass-panel-static overflow-hidden">
      <div className="overflow-x-auto overflow-y-auto max-h-[420px]">
        <table className="glass-table">
          <thead>
            <tr>
              {columns.map((col) => (
                <th
                  key={col.key}
                  onClick={col.sortable ? () => handleSort(col.key) : undefined}
                  className={`${col.sortable ? "cursor-pointer select-none hover:text-slate-300" : ""} sticky top-0 bg-[#080916]/95 backdrop-blur-md z-10`}
                >
                  <span className="flex items-center gap-1">
                    {col.header}
                    {col.sortable && <ArrowUpDown size={12} className="opacity-40" />}
                  </span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {paginated.map((row, i) => (
              <tr
                key={i}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={onRowClick ? "cursor-pointer" : ""}
              >
                {columns.map((col) => (
                  <td key={col.key}>
                    {col.render ? col.render(row) : (row[col.key] as React.ReactNode) ?? "—"}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between px-4 py-3 border-t border-white/5">
          <span className="text-xs text-slate-500">
            {page * pageSize + 1}–{Math.min((page + 1) * pageSize, sorted.length)} of {sorted.length}
          </span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPage(Math.max(0, page - 1))}
              disabled={page === 0}
              className="glass-btn glass-btn-ghost glass-btn-sm"
            >
              <ChevronLeft size={14} />
            </button>
            <span className="text-xs text-slate-400 px-2">
              {page + 1} / {totalPages}
            </span>
            <button
              onClick={() => setPage(Math.min(totalPages - 1, page + 1))}
              disabled={page >= totalPages - 1}
              className="glass-btn glass-btn-ghost glass-btn-sm"
            >
              <ChevronRight size={14} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
