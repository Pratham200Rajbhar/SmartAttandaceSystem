"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard, Users, GraduationCap, BookOpen, Building2, ScanSearch,
  ScrollText, Radio, ClipboardCheck, BarChart3, Shield, Sliders, ChevronDown, ChevronRight,
  FileText, Smartphone
} from "lucide-react";
import { useAuthStore } from "@/store/authStore";
import api from "@/lib/api";

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
}

const adminLinks: NavItem[] = [
  { label: "Overview", href: "/admin/dashboard", icon: <LayoutDashboard size={18} /> },
  { label: "Students", href: "/admin/users/students", icon: <GraduationCap size={18} /> },
  { label: "Teachers", href: "/admin/users/teachers", icon: <Users size={18} /> },
  { label: "Classes", href: "/admin/classes", icon: <BookOpen size={18} /> },
  { label: "AI Scanner", href: "/admin/scanner", icon: <ScanSearch size={18} /> },
  { label: "Audit Log", href: "/admin/audit", icon: <ScrollText size={18} /> },
];

const setupLinks: NavItem[] = [
  { label: "Departments", href: "/admin/setup/departments", icon: <Building2 size={16} /> },
  { label: "Subjects", href: "/admin/setup/subjects", icon: <BookOpen size={16} /> },
  { label: "Classrooms", href: "/admin/setup/classrooms", icon: <Sliders size={16} /> },
  { label: "Designations", href: "/admin/setup/designations", icon: <Users size={16} /> },
  { label: "Verification Settings", href: "/admin/setup/verification-settings", icon: <Shield size={16} /> },
];

const teacherLinks: NavItem[] = [
  { label: "Overview", href: "/teacher/dashboard", icon: <LayoutDashboard size={18} /> },
  { label: "My Classes", href: "/teacher/classes", icon: <BookOpen size={18} /> },
  { label: "Sessions", href: "/teacher/sessions", icon: <Radio size={18} /> },
  { label: "Review Queue", href: "/teacher/review", icon: <ClipboardCheck size={18} /> },
  { label: "Leave Requests", href: "/teacher/leaves", icon: <FileText size={18} /> },
  { label: "Device Changes", href: "/teacher/device-changes", icon: <Smartphone size={18} /> },
];

const teacherReportLinks: NavItem[] = [
  { label: "Class Analytics", href: "/teacher/analytics", icon: <BarChart3 size={18} /> },
  { label: "Attendance History", href: "/teacher/history", icon: <ScrollText size={18} /> },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function Sidebar({ isOpen, onClose }: SidebarProps): React.ReactElement {
  const pathname = usePathname();
  const user = useAuthStore((s) => s.user);
  const role = user?.role;

  const isSetupActive = pathname.startsWith("/admin/setup");
  const [setupOpen, setSetupOpen] = useState(isSetupActive);
  const [prevIsSetupActive, setPrevIsSetupActive] = useState(isSetupActive);
  const [flaggedCount, setFlaggedCount] = useState(0);

  if (isSetupActive !== prevIsSetupActive) {
    setPrevIsSetupActive(isSetupActive);
    if (isSetupActive) {
      setSetupOpen(true);
    }
  }

  useEffect(() => {
    if (role !== "TEACHER") return;

    let isMounted = true;
    async function fetchFlagged(): Promise<void> {
      try {
        const { data } = await api.get<unknown[]>("/teacher/attendance/flagged");
        if (isMounted) {
          setFlaggedCount(Array.isArray(data) ? data.length : 0);
        }
      } catch {
        // Ignore errors in background polling
      }
    }

    void fetchFlagged();
    const interval = setInterval(() => {
      void fetchFlagged();
    }, 60_000);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [role]);

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-30 md:hidden animate-fade-in-up" onClick={onClose} />
      )}

      <aside className={`sidebar ${isOpen ? "open" : ""}`}>
        {}
        <div className="p-5 border-b border-white/5">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-gradient-to-tr from-emerald-500/10 to-teal-500/10 border border-white/10 shadow-[0_4px_12px_rgba(0,0,0,0.5)]">
              <Shield size={20} className="text-emerald-400" />
            </div>
            <div>
              <h2 className="text-base font-extrabold text-slate-100 leading-tight tracking-wide font-[Outfit]">Smart Attendance</h2>
              <p className="text-[12px] text-slate-500 font-semibold tracking-wide">System Dashboard</p>
            </div>
          </div>
        </div>

        {}
        <nav className="flex-1 py-4 overflow-y-auto space-y-1">
          {role === "ADMIN" ? (
            <>
              <p className="px-6 mb-2 text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                Administration
              </p>

              <div className="space-y-1">
                {adminLinks.map((link) => {
                  const isActive = pathname.startsWith(link.href);
                  return (
                    <Link
                      key={link.href}
                      href={link.href}
                      onClick={onClose}
                      className={`sidebar-link relative group ${isActive ? "sidebar-link-active" : ""}`}
                    >
                      <span className={`transition-colors duration-200 ${isActive ? "text-slate-200" : "text-slate-400 group-hover:text-slate-200"}`}>
                        {link.icon}
                      </span>
                      <span className="font-semibold text-sm tracking-wide">{link.label}</span>
                      {isActive && (
                        <span className="absolute left-0 top-[20%] bottom-[20%] w-[3px] rounded-r bg-emerald-400 shadow-[0_0_8px_rgba(16,185,129,0.8)]" />
                      )}
                    </Link>
                  );
                })}
              </div>

              <div className="mt-4 border-t border-white/5 pt-4">
                <button
                  onClick={() => setSetupOpen(!setupOpen)}
                  className={`w-full sidebar-link justify-between group ${isSetupActive ? "text-slate-300 font-semibold" : "text-slate-400 hover:text-slate-200"}`}
                >
                  <div className="flex items-center gap-3">
                    <Sliders size={18} className={isSetupActive ? "text-slate-300" : "text-slate-400 group-hover:text-slate-200"} />
                    <span className="font-semibold text-sm tracking-wide">System Setup</span>
                  </div>
                  {setupOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                </button>

                {setupOpen && (
                  <div className="pl-6 mt-1 space-y-0.5 transition-all duration-300">
                    {setupLinks.map((link) => {
                      const isActive = pathname === link.href || pathname.startsWith(link.href + "/");
                      return (
                        <Link
                          key={link.href}
                          href={link.href}
                          onClick={onClose}
                          className={`sidebar-link py-2 relative group ${isActive
                              ? "sidebar-link-active text-slate-200 bg-white/5 font-semibold"
                              : "text-slate-400 hover:text-slate-200"
                            }`}
                        >
                          <span className={`transition-colors duration-200 ${isActive ? "text-slate-200" : "text-slate-500 group-hover:text-slate-300"}`}>
                            {link.icon}
                          </span>
                          <span className="text-[13px] font-medium tracking-wide">{link.label}</span>
                          {isActive && (
                            <span className="absolute left-0 top-[20%] bottom-[20%] w-[3px] rounded-r bg-emerald-400 shadow-[0_0_8px_rgba(16,185,129,0.8)]" />
                          )}
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            </>
          ) : (
            <>
              {}
              <p className="px-6 mb-2 text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                Teaching Operations
              </p>

              <div className="space-y-1">
                {teacherLinks.map((link) => {
                  const isActive = pathname.startsWith(link.href);
                  const isReviewLink = link.href === "/teacher/review";
                  return (
                    <Link
                      key={link.href}
                      href={link.href}
                      onClick={onClose}
                      className={`sidebar-link relative group ${isActive ? "sidebar-link-active" : ""}`}
                    >
                      <span className={`transition-colors duration-200 ${isActive ? "text-slate-200" : "text-slate-400 group-hover:text-slate-200"}`}>
                        {link.icon}
                      </span>
                      <span className="font-semibold text-sm tracking-wide">{link.label}</span>
                      {isReviewLink && flaggedCount > 0 && (
                        <span className="ml-auto flex items-center justify-center min-w-[18px] h-[18px] px-1 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-[10px] font-bold shadow-[0_4px_12px_rgba(0,0,0,0.5)]">
                          {flaggedCount > 99 ? "99+" : flaggedCount}
                        </span>
                      )}
                      {isActive && !isReviewLink && (
                        <span className="absolute left-0 top-[20%] bottom-[20%] w-[3px] rounded-r bg-emerald-400 shadow-[0_0_8px_rgba(16,185,129,0.8)]" />
                      )}
                    </Link>
                  );
                })}
              </div>

              {}
              <div className="mt-4 border-t border-white/5 pt-4">
                <p className="px-6 mb-2 text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                  Reports & Archives
                </p>

                <div className="space-y-1">
                  {teacherReportLinks.map((link) => {
                    const isActive = pathname.startsWith(link.href);
                    return (
                      <Link
                        key={link.href}
                        href={link.href}
                        onClick={onClose}
                        className={`sidebar-link relative group ${isActive ? "sidebar-link-active" : ""}`}
                      >
                        <span className={`transition-colors duration-200 ${isActive ? "text-slate-200" : "text-slate-400 group-hover:text-slate-200"}`}>
                          {link.icon}
                        </span>
                        <span className="font-semibold text-sm tracking-wide">{link.label}</span>
                        {isActive && (
                          <span className="absolute left-0 top-[20%] bottom-[20%] w-[3px] rounded-r bg-emerald-400 shadow-[0_0_8px_rgba(16,185,129,0.8)]" />
                        )}
                      </Link>
                    );
                  })}
                </div>
              </div>
            </>
          )}
        </nav>

        {}
        {user && (
          <div className="mx-4 mb-2 p-3 rounded-xl bg-white/[0.01] border border-white/5 flex items-center gap-3 shadow-inner hover:bg-white/[0.03] transition-all duration-300">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-emerald-500/10 to-teal-500/10 border border-emerald-500/20 flex items-center justify-center font-bold text-emerald-400 text-xs shadow-sm">
              {user.email ? user.email[0].toUpperCase() : "U"}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[13px] font-bold text-slate-200 truncate leading-normal">{user.email || "User"}</p>
              <p className="text-[10px] text-slate-500 truncate uppercase font-bold tracking-wider leading-none mt-0.5">{user.role || "Guest"}</p>
            </div>
          </div>
        )}

        <div className="p-3 border-t border-white/5">
          <p className="text-[10px] font-semibold text-slate-600 text-center tracking-wider">SAS v1.0.0</p>
        </div>
      </aside>
    </>
  );
}

