import React from "react";

export default function DashboardLoading(): React.ReactElement {
  return (
    <div className="animate-fade-in-up p-8 space-y-6">
      <div className="h-8 w-64 rounded-xl bg-white/[0.03] animate-pulse" />
      <div className="h-4 w-96 rounded-xl bg-white/[0.02] animate-pulse" />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-32 rounded-2xl bg-white/[0.03] animate-pulse" />
        ))}
      </div>
      <div className="h-64 rounded-2xl bg-white/[0.03] animate-pulse" />
    </div>
  );
}
