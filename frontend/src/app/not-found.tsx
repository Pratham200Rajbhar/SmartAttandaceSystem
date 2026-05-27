import Link from "next/link";
import React from "react";

export default function NotFoundPage(): React.ReactElement {
  return (
    <div className="min-h-screen flex items-center justify-center p-8" style={{ background: "radial-gradient(ellipse at 50% 0%, rgba(99, 102, 241, 0.08) 0%, transparent 60%), #0f172a" }}>
      <div className="text-center max-w-md">
        <h1 className="text-8xl font-bold text-white/10 mb-4">404</h1>
        <h2 className="text-2xl font-bold text-white mb-3">Page Not Found</h2>
        <p className="text-slate-400 mb-8">The page you&apos;re looking for doesn&apos;t exist or has been moved.</p>
        <Link href="/login" className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-white/10 text-white font-semibold hover:bg-white/20 transition-all duration-200">
          Go Home
        </Link>
      </div>
    </div>
  );
}
