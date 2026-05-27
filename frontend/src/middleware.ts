import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const AUTH_COOKIE = "sas-auth-storage";

function getTokenFromCookie(request: NextRequest): string | null {
  const cookie = request.cookies.get(AUTH_COOKIE);
  if (!cookie?.value) return null;
  try {
    const parsed = JSON.parse(decodeURIComponent(cookie.value));
    return parsed?.state?.token || null;
  } catch {
    return null;
  }
}

function parseRoleFromCookie(request: NextRequest): string | null {
  const cookie = request.cookies.get(AUTH_COOKIE);
  if (!cookie?.value) return null;
  try {
    const parsed = JSON.parse(decodeURIComponent(cookie.value));
    return parsed?.state?.user?.role || null;
  } catch {
    return null;
  }
}

export function middleware(request: NextRequest): NextResponse {
  const { pathname } = request.nextUrl;

  const publicPaths = ["/login", "/api", "/_next", "/favicon.ico"];
  if (publicPaths.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  const token = getTokenFromCookie(request);

  if (pathname === "/") {
    if (token) {
      const role = parseRoleFromCookie(request);
      if (role === "ADMIN") {
        return NextResponse.redirect(new URL("/admin/dashboard", request.url));
      }
      if (role === "TEACHER") {
        return NextResponse.redirect(new URL("/teacher/classes", request.url));
      }
    }
    return NextResponse.redirect(new URL("/login", request.url));
  }

  if (!token && !pathname.startsWith("/login")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  const role = parseRoleFromCookie(request);
  if (token && role) {
    if (role === "STUDENT") {
      if (pathname.startsWith("/admin") || pathname.startsWith("/teacher")) {
        return NextResponse.redirect(new URL("/login", request.url));
      }
    }
    if (role !== "ADMIN" && pathname.startsWith("/admin")) {
      return NextResponse.redirect(new URL("/teacher/classes", request.url));
    }
    if (role !== "TEACHER" && pathname.startsWith("/teacher")) {
      return NextResponse.redirect(new URL("/admin/dashboard", request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
