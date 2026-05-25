"use client";

import React from "react";

interface GlassTextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
}

export default function GlassTextarea({
  label,
  error,
  id,
  className = "",
  ...props
}: GlassTextareaProps): React.ReactElement {
  const textareaId = id || label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={textareaId} className="text-sm font-medium text-slate-300">
          {label}
        </label>
      )}
      <textarea
        id={textareaId}
        className={`glass-input min-h-[100px] resize-y ${error ? "glass-input-error" : ""} ${className}`}
        {...props}
      />
      {error && <p className="text-xs text-slate-300 mt-0.5">{error}</p>}
    </div>
  );
}
