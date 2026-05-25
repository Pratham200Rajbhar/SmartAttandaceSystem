"use client";

import React from "react";
import { ChevronDown } from "lucide-react";

interface SelectOption {
  value: string;
  label: string;
}

interface GlassSelectProps {
  label?: string;
  options: SelectOption[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  error?: string;
  id?: string;
  disabled?: boolean;
}

export default function GlassSelect({
  label,
  options,
  value,
  onChange,
  placeholder = "Select...",
  error,
  id,
  disabled = false,
}: GlassSelectProps): React.ReactElement {
  const selectId = id || label?.toLowerCase().replace(/\s+/g, "-");

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={selectId} className="text-[15px] font-semibold text-slate-200 tracking-wide">
          {label}
        </label>
      )}
      <div className="relative">
        <select
          id={selectId}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          disabled={disabled}
          className={`glass-input appearance-none pr-10 cursor-pointer ${error ? "glass-input-error" : ""}`}
        >
          <option value="" disabled className="bg-slate-900 text-slate-400">
            {placeholder}
          </option>
          {options.map((opt) => (
            <option key={opt.value} value={opt.value} className="bg-slate-900 text-slate-100">
              {opt.label}
            </option>
          ))}
        </select>
        <ChevronDown
          size={16}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none"
        />
      </div>
      {error && <p className="text-xs text-slate-300 mt-0.5">{error}</p>}
    </div>
  );
}
