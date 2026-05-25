"use client";

import React from "react";

interface GlassInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  icon?: React.ReactNode;
}

export default function GlassInput({
  label,
  error,
  icon,
  id,
  className = "",
  ...props
}: GlassInputProps): React.ReactElement {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={inputId} className="text-[15px] font-semibold text-slate-200 tracking-wide">
          {label}
        </label>
      )}
      <div className="relative">
        {icon && (
          <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 z-10 flex items-center justify-center pointer-events-none">
            {icon}
          </span>
        )}
        <input
          id={inputId}
          className={`glass-input ${icon ? "glass-input-with-icon" : ""} ${error ? "glass-input-error" : ""} ${className}`}
          {...props}
        />
      </div>
      {error && <p className="text-xs text-slate-300 mt-0.5">{error}</p>}
    </div>
  );
}
