"use client";

import React, { useState } from "react";
import { CheckCircle2, XCircle, Smartphone, AlertCircle } from "lucide-react";
import GlassTable, { TableColumn } from "@/components/ui/GlassTable";
import api, { getApiErrorMessage } from "@/lib/api";
import { toast } from "react-hot-toast";

interface DeviceChangeRequest {
  id: string;
  student_id: string;
  student_name: string;
  enrollment_number: string;
  new_device_uuid: string;
  reason: string | null;
  status: string;
  created_at: string;
}

interface DeviceChangeTableProps {
  requests: DeviceChangeRequest[];
  onActionComplete: () => void;
}

export default function DeviceChangeTable({ requests, onActionComplete }: DeviceChangeTableProps): React.ReactElement {
  const [processing, setProcessing] = useState<string | null>(null);

  const formatDate = (dateStr: string): string => {
    try {
      const date = new Date(dateStr);
      return date.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
    } catch {
      return dateStr;
    }
  };

  const formatTime = (dateStr: string): string => {
    try {
      const date = new Date(dateStr);
      return date.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", hour12: true });
    } catch {
      return "";
    }
  };

  const handleAction = async (id: string, status: "APPROVED" | "REJECTED"): Promise<void> => {
    try {
      setProcessing(id);
      await api.put(`/teacher/device-changes/${id}/approve`, { status });
      toast.success(`Request ${status.toLowerCase()} successfully`);
      onActionComplete();
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Action failed"));
    } finally {
      setProcessing(null);
    }
  };

  const columns: TableColumn<DeviceChangeRequest & Record<string, unknown>>[] = [
    {
      key: "student",
      header: "Student Details",
      render: (req) => (
        <div>
          <p className="text-sm font-bold text-slate-200">{req.student_name}</p>
          <p className="text-xs text-slate-400 mt-0.5">{req.enrollment_number}</p>
        </div>
      ),
    },
    {
      key: "request",
      header: "Request Info",
      render: (req) => (
        <div>
          <div className="flex items-center gap-2">
            <Smartphone size={14} className="text-blue-400" />
            <span className="text-xs font-mono text-slate-300">
              {req.new_device_uuid.substring(0, 8)}...
            </span>
          </div>
          {req.reason && (
            <div className="flex items-center gap-1 mt-1 text-xs text-amber-200/80 bg-amber-500/10 w-fit px-2 py-0.5 rounded">
              <AlertCircle size={10} />
              <span className="truncate max-w-[200px]">{req.reason}</span>
            </div>
          )}
        </div>
      ),
    },
    {
      key: "date",
      header: "Date Submitted",
      render: (req) => (
        <div className="text-sm text-slate-300">
          {formatDate(req.created_at)}
          <div className="text-xs text-slate-500">{formatTime(req.created_at)}</div>
        </div>
      ),
    },
    {
      key: "actions",
      header: "Actions",
      render: (req) => (
        <div className="flex items-center justify-end gap-2">
          <button
            onClick={() => handleAction(req.id, "REJECTED")}
            disabled={processing !== null}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-red-500/10 text-red-400 hover:bg-red-500/20 disabled:opacity-50 transition-colors text-sm font-semibold"
          >
            <XCircle size={16} />
            Reject
          </button>
          <button
            onClick={() => handleAction(req.id, "APPROVED")}
            disabled={processing !== null}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20 disabled:opacity-50 transition-colors text-sm font-semibold shadow-[0_0_10px_rgba(16,185,129,0.1)]"
          >
            <CheckCircle2 size={16} />
            Approve
          </button>
        </div>
      ),
    },
  ];

  if (requests.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center p-12 text-center border rounded-2xl bg-white/5 border-white/10">
        <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4">
          <Smartphone className="text-slate-400" size={32} />
        </div>
        <h3 className="text-xl font-bold text-white mb-2 font-[Outfit]">No Pending Requests</h3>
        <p className="text-slate-400 max-w-sm">
          All device change requests have been processed. Students can request device changes from their mobile app.
        </p>
      </div>
    );
  }

  return <GlassTable columns={columns} data={requests as (DeviceChangeRequest & Record<string, unknown>)[]} />;
}
