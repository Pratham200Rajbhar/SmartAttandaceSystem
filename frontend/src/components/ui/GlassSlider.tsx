"use client";

import React from "react";

interface GlassSliderProps {
  label?: string;
  min: number;
  max: number;
  step?: number;
  value: number;
  onChange: (value: number) => void;
  unit?: string;
}

export default function GlassSlider({
  label,
  min,
  max,
  step = 1,
  value,
  onChange,
  unit = "",
}: GlassSliderProps): React.ReactElement {
  const percent = ((value - min) / (max - min)) * 100;

  return (
    <div className="flex flex-col gap-2">
      {label && (
        <div className="flex items-center justify-between">
          <label className="text-sm font-medium text-slate-300">{label}</label>
          <span className="text-sm font-semibold text-slate-300">
            {value}
            {unit}
          </span>
        </div>
      )}
      <div className="relative">
        <input
          type="range"
          min={min}
          max={max}
          step={step}
          value={value}
          onChange={(e) => onChange(Number(e.target.value))}
          className="w-full h-2 rounded-full appearance-none cursor-pointer"
          style={{
            background: `linear-gradient(to right, #3b82f6 0%, #3b82f6 ${percent}%, rgba(255,255,255,0.08) ${percent}%, rgba(255,255,255,0.08) 100%)`,
          }}
        />
      </div>
      <div className="flex justify-between text-xs text-slate-600">
        <span>{min}{unit}</span>
        <span>{max}{unit}</span>
      </div>
    </div>
  );
}
