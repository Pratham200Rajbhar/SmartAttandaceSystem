"use client";

import React, { useState, useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuthStore } from "@/store/authStore";
import Sidebar from "@/components/ui/Sidebar";
import Header from "@/components/ui/Header";
import GlassLoader from "@/components/ui/GlassLoader";

export default function DashboardLayout({ children }: { children: React.ReactNode }): React.ReactElement {
  const router = useRouter();
  const pathname = usePathname();
  const { isAuthenticated, isHydrated, user } = useAuthStore();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!isHydrated) return;

    if (!isAuthenticated) {
      router.replace("/login");
      return;
    }

    if (user?.role === "TEACHER" && pathname.startsWith("/admin")) {
      router.replace("/teacher/classes");
      return;
    }
    if (user?.role === "ADMIN" && pathname.startsWith("/teacher")) {
      router.replace("/admin/dashboard");
      return;
    }
  }, [isHydrated, isAuthenticated, user, pathname, router]);

  if (!isHydrated || !isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <GlassLoader text="Authenticating..." />
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col md:flex-row">
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      <div className="flex-1 md:ml-[302px] min-w-0 transition-all duration-300">
        <Header onMenuToggle={() => setSidebarOpen(!sidebarOpen)} />
        <main className="px-4 md:px-6 pb-6 lg:pb-8 animate-fade-in-up">
          {children}
        </main>
      </div>
    </div>
  );
}

