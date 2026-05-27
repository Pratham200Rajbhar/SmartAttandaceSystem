"use client";

import React, { useEffect, useState, useCallback } from "react";
import { Smartphone, RefreshCw } from "lucide-react";
import api from "@/lib/api";
import DeviceChangeTable from "@/components/teacher/DeviceChangeTable";
import { toast } from "react-hot-toast";

export default function DeviceChangesPage() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchRequests = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get("/teacher/device-changes/pending");
      setRequests(data);
    } catch (err) {
      toast.error("Failed to load device change requests");
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  return (
    <div className="p-6 md:p-8 max-w-[1400px] mx-auto space-y-8 animate-fade-in-up">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight flex items-center gap-3 font-[Outfit]">
            <div className="p-2.5 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
              <Smartphone size={28} />
            </div>
            Device Change Requests
          </h1>
          <p className="text-slate-400 mt-2 text-sm max-w-2xl leading-relaxed">
            Review and approve requests from students who need to change their registered device.
            This prevents proxy attendance by ensuring each student uses only one authorized phone.
          </p>
        </div>
        <button
          onClick={fetchRequests}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg transition-colors border border-white/10"
        >
          <RefreshCw size={18} className={loading ? "animate-spin text-indigo-400" : "text-indigo-400"} />
          <span className="text-sm font-semibold">Refresh</span>
        </button>
      </div>

      <div className="relative z-10">
        {loading ? (
          <div className="flex items-center justify-center h-64 border rounded-2xl bg-white/5 border-white/10">
            <RefreshCw size={32} className="animate-spin text-indigo-500/50" />
          </div>
        ) : (
          <DeviceChangeTable requests={requests} onActionComplete={fetchRequests} />
        )}
      </div>
    </div>
  );
}
