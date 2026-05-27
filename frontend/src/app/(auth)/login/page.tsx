"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { Mail, Lock, Shield } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import GlassInput from "@/components/ui/GlassInput";
import GlassButton from "@/components/ui/GlassButton";
import type { TokenResponse, UserProfile } from "@/types";

export default function LoginPage(): React.ReactElement {
  const router = useRouter();
  const { login } = useAuthStore();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});

  function validate(): boolean {
    const errs: { email?: string; password?: string } = {};
    if (!email.trim()) errs.email = "Email is required";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errs.email = "Invalid email format";
    if (!password) errs.password = "Password is required";
    else if (password.length < 8) errs.password = "Minimum 8 characters";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  async function handleSubmit(e: React.FormEvent): Promise<void> {
    e.preventDefault();
    if (!validate()) return;

    setLoading(true);
    try {
      const { data: tokenData } = await api.post<TokenResponse>("/auth/login", { email, password });
      const { data: profile } = await api.get<UserProfile>("/auth/me", {
        headers: { Authorization: `Bearer ${tokenData.access_token}` },
      });

      login(tokenData.access_token, profile);
      toast.success("Welcome back!");

      const destination = tokenData.role === "ADMIN" ? "/admin/dashboard" : "/teacher/classes";
      router.push(destination);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Login failed. Please check your credentials."));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden">
      {}
      <div className="absolute w-[350px] h-[350px] rounded-full bg-white/5 filter blur-[80px] -z-10 pointer-events-none" />

      <div className="w-full max-w-md animate-fade-in-up relative z-10">
        {}
        <div className="text-center mb-8">
          <div className="inline-flex p-4 rounded-2xl bg-gradient-to-tr from-white/10 to-purple-500/10 border border-white/10 shadow-[0_4px_12px_rgba(0,0,0,0.5)] mb-5">
            <Shield size={36} className="text-slate-300 animate-pulse" />
          </div>
          <h1 className="text-3xl font-extrabold text-slate-100 tracking-tight font-[Outfit] bg-clip-text bg-gradient-to-r from-slate-100 to-indigo-200">
            Smart Attendance
          </h1>
          <p className="text-xs text-slate-500 mt-2 font-medium tracking-wide">
            AI-Powered Multi-Layered Verification System
          </p>
        </div>

        {}
        <form onSubmit={handleSubmit} className="glass-panel-static p-8 space-y-6 shadow-2xl">
          <div className="space-y-1">
            <h2 className="text-lg font-bold text-slate-200 tracking-wide font-[Outfit]">Welcome Back</h2>
            <p className="text-xs text-slate-500">Sign in to your administration or teacher account</p>
          </div>

          <div className="space-y-4">
            <GlassInput
              label="Email Address"
              type="email"
              placeholder="you@university.edu"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              error={errors.email}
              icon={<Mail size={16} className="text-slate-400" />}
              autoComplete="email"
            />

            <GlassInput
              label="Password"
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              error={errors.password}
              icon={<Lock size={16} className="text-slate-400" />}
              autoComplete="current-password"
            />
          </div>

          <div className="pt-2">
            <GlassButton
              type="submit"
              variant="primary"
              size="lg"
              loading={loading}
              className="w-full mt-2 animate-pulse-glow font-bold text-sm tracking-wider uppercase"
            >
              Sign In
            </GlassButton>
          </div>
        </form>

        {}
        <p className="text-center text-[10px] font-bold text-slate-600 uppercase tracking-widest mt-8">
          Enterprise Security Verification Suite
        </p>
      </div>
    </div>
  );
}

