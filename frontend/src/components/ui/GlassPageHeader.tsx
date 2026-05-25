"use client";

import React from "react";

interface GlassPageHeaderProps {
  title: string;
  description?: string;
  actions?: React.ReactNode;
}

export default function GlassPageHeader({ title, description, actions }: GlassPageHeaderProps): React.ReactElement {
  return (
    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
      <div>
        <h1 className="text-3xl font-extrabold text-slate-100 tracking-tight font-[Outfit] bg-clip-text bg-gradient-to-r from-slate-100 to-slate-300">{title}</h1>
        {description && <p className="text-base font-medium text-slate-400 mt-1.5">{description}</p>}
      </div>
      {actions && <div className="flex items-center gap-3 shrink-0">{actions}</div>}
    </div>
  );
}
