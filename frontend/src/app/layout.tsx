import type { Metadata } from "next";
import { Toaster } from "react-hot-toast";
import "./globals.css";

export const metadata: Metadata = {
  title: "Smart Attendance System",
  description: "AI-powered multi-layered smart attendance verification dashboard",
};

export default function RootLayout({ children }: { children: React.ReactNode }): React.ReactElement {
  return (
    <html lang="en">
      <body>
        <div className="animated-bg" aria-hidden="true" />
        <div style={{ position: "relative", zIndex: 1, minHeight: "100vh" }}>
          {children}
        </div>
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: "rgba(15, 23, 42, 0.95)",
              backdropFilter: "blur(16px)",
              color: "#f1f5f9",
              border: "1px solid rgba(255,255,255,0.08)",
              borderRadius: "12px",
              fontSize: "14px",
              padding: "12px 16px",
              boxShadow: "0 8px 32px rgba(0,0,0,0.4)",
            },
          }}
        />
      </body>
    </html>
  );
}
