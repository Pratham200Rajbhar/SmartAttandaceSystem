"use client";
import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Menu, LogOut, Calendar } from "lucide-react";
import { useAuthStore } from "@/store/authStore";
import api from "@/lib/api";
import toast from "react-hot-toast";
import GlassBadge from "./GlassBadge";

const ROLE_BADGE_VARIANT: Record<string, "info" | "success"> = {
  ADMIN: "info",
  TEACHER: "success",
};

interface HeaderProps {
  onMenuToggle: () => void;
}

export default function Header({ onMenuToggle }: HeaderProps): React.ReactElement {
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const [timeStr, setTimeStr] = useState("");

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTimeStr(
        now.toLocaleDateString("en-US", {
          weekday: "short",
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 60_000);
    return () => clearInterval(interval);
  }, []);

  async function handleLogout(): Promise<void> {
    try {
      await api.post("/auth/logout");
    } catch {
      
    }
    logout();
    toast.success("Logged out successfully");
    router.push("/login");
  }

  const roleBadge = ROLE_BADGE_VARIANT[user?.role ?? ""] ?? "success";

  return (
    <header
      className="sticky top-0 z-20 flex items-center justify-between px-5 m-4 md:my-4 md:mr-4 md:ml-0 rounded-2xl border border-white/[0.06] shadow-xl animate-fade-in-up"
      style={{
        height: "calc(var(--header-height) - 8px)",
        background: "rgba(3, 4, 12, 0.45)",
        backdropFilter: "blur(28px)",
        WebkitBackdropFilter: "blur(28px)",
      }}
    >
      <button
        onClick={onMenuToggle}
        className="glass-btn glass-btn-ghost p-2 md:hidden hover:bg-white/5 rounded-xl transition-all duration-300"
        aria-label="Toggle menu"
      >
        <Menu size={18} className="text-slate-300" />
      </button>

      {}
      <div className="hidden md:flex items-center gap-2.5 text-xs font-semibold text-slate-400">
        <Calendar size={13} className="text-emerald-400" />
        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping inline-block" />
        <span className="tracking-wide text-slate-300">{timeStr || "Loading..."}</span>
      </div>

      {}
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-3">
          <GlassBadge variant={roleBadge} className="shadow-[0_4px_12px_rgba(0,0,0,0.5)] py-0.5 px-2.5 font-bold tracking-wider text-[10px]">
            {user?.role || "—"}
          </GlassBadge>
          <span className="text-xs font-bold text-slate-300 hidden sm:inline tracking-wide">
            {user?.email || "—"}
          </span>
        </div>
        
        <div className="w-px h-5 bg-white/10" />

        <button
          onClick={handleLogout}
          className="glass-btn glass-btn-ghost glass-btn-sm text-slate-400 hover:text-slate-200 hover:bg-white/5 hover:border-white/10 rounded-xl px-3 py-1.5 transition-all duration-300 flex items-center gap-1.5"
          title="Logout"
        >
          <LogOut size={13} className="transition-transform duration-300 group-hover:translate-x-1" />
          <span className="hidden sm:inline text-xs font-bold tracking-wide">Logout</span>
        </button>
      </div>
    </header>
  );
}
