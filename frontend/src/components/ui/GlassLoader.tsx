"use client";

import React from "react";
import { Loader2 } from "lucide-react";

interface GlassLoaderProps {
  text?: string;
}


export default function GlassLoader({ text = "Loading..." }: GlassLoaderProps): React.ReactElement {
  return (
    <div className="flex flex-col items-center justify-center py-24 gap-4 animate-fade-in-up">
      <Loader2 size={32} className="text-slate-300 animate-spin" />
      <p className="text-sm text-slate-400">{text}</p>
    </div>
  );
}


export function GlassSkeleton({ className = "" }: { className?: string }): React.ReactElement {
  return <div className={`animate-shimmer rounded-xl ${className}`} />;
}
