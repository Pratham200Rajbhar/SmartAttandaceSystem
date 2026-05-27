"use client";

import React from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";
import GlassButton from "@/components/ui/GlassButton";

export default function DashboardError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }): React.ReactElement {
  return (
    <div className="min-h-[60vh] flex items-center justify-center p-8">
      <div className="text-center max-w-md">
        <div className="p-4 rounded-2xl bg-red-500/10 text-red-400 inline-flex mb-6">
          <AlertTriangle size={48} />
        </div>
        <h2 className="text-2xl font-bold text-white mb-3">Something went wrong</h2>
        <p className="text-slate-400 mb-2">{error.message || "An unexpected error occurred while loading this page."}</p>
        {error.digest && <p className="text-xs text-slate-600 mb-6 font-mono">Error ID: {error.digest}</p>}
        <GlassButton variant="primary" icon={<RefreshCw size={16} />} onClick={reset}>
          Try Again
        </GlassButton>
      </div>
    </div>
  );
}
