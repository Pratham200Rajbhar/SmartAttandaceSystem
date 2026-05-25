"use client";

import React from "react";
import { useRouter } from "next/navigation";
import { Menu, LogOut } from "lucide-react";
import { useAuthStore } from "@/store/authStore";
import api from "@/lib/api";
import toast from "react-hot-toast";
import GlassBadge from "./GlassBadge";

interface HeaderProps {
  onMenuToggle: () => void;
}

export default function Header({ onMenuToggle }: HeaderProps): React.ReactElement {
  const router = useRouter();
  const { user, logout } = useAuthStore();

  async function handleLogout(): Promise<void> {
    try {
      await api.post("/auth/logout");
    } catch {
      
    }
    logout();
    toast.success("Logged out successfully");
    router.push("/login");
  }

  const roleBadge = user?.role === "ADMIN" ? "info" : "success";

  return (
    <header
      className="sticky top-0 z-20 flex items-center justify-between px-5 m-4 md:my-4 md:mr-4 md:ml-0 rounded-2xl border border-white/5 shadow-lg animate-fade-in-up"
      style={{
        height: "calc(var(--header-height) - 8px)",
        background: "rgba(10, 11, 28, 0.4)",
        backdropFilter: "blur(24px)",
        WebkitBackdropFilter: "blur(24px)",
      }}
    >
      <button
        onClick={onMenuToggle}
        className="glass-btn glass-btn-ghost p-2 md:hidden hover:bg-white/5 rounded-xl transition-all duration-300"
        aria-label="Toggle menu"
      >
        <Menu size={18} className="text-slate-300" />
      </button>

      <div className="hidden md:block" />

      {}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3">
          <GlassBadge variant={roleBadge} className="shadow-[0_4px_12px_rgba(0,0,0,0.5)] py-0.5 px-2.5 font-bold tracking-wider text-[10px]">
            {user?.role || "—"}
          </GlassBadge>
          <span className="text-xs font-semibold text-slate-300 hidden sm:inline tracking-wide">
            {user?.email || "—"}
          </span>
        </div>
        
        <div className="w-px h-5 bg-white/10" />

        <button
          onClick={handleLogout}
          className="glass-btn glass-btn-ghost glass-btn-sm text-slate-400 hover:text-slate-300 hover:bg-white/5/5 hover:border-white/10 rounded-xl px-3 py-1.5 transition-all duration-300"
          title="Logout"
        >
          <LogOut size={14} className="transition-transform duration-300 group-hover:translate-x-1" />
          <span className="hidden sm:inline text-xs font-semibold tracking-wide">Logout</span>
        </button>
      </div>
    </header>
  );
}

