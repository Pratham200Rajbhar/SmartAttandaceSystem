"use client";

import React, { useState, useEffect } from "react";
import { Search } from "lucide-react";

interface GlassSearchProps {
  placeholder?: string;
  value?: string;
  onSearch: (query: string) => void;
  debounceMs?: number;
}

export default function GlassSearch({
  placeholder = "Search...",
  value: externalValue,
  onSearch,
  debounceMs = 300,
}: GlassSearchProps): React.ReactElement {
  const [query, setQuery] = useState(externalValue || "");

  useEffect(() => {
    const timer = setTimeout(() => onSearch(query), debounceMs);
    return () => clearTimeout(timer);
  }, [query, debounceMs, onSearch]);

  return (
    <div className="relative w-full">
      <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
        className="glass-input glass-input-with-icon"
      />
    </div>
  );
}
