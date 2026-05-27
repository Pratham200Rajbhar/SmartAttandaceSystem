import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { StateStorage } from "zustand/middleware";
import type { UserProfile } from "@/types";

interface AuthState {
  user: UserProfile | null;
  token: string | null;
  isAuthenticated: boolean;
  isHydrated: boolean;
}

interface AuthActions {
  login: (token: string, user: UserProfile) => void;
  logout: () => void;
  setUser: (user: UserProfile) => void;
  setHydrated: (state: boolean) => void;
}

type AuthStore = AuthState & AuthActions;

const cookieStorage: StateStorage = {
  getItem: (name: string): string | null => {
    if (typeof window === "undefined") return null;
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) {
      const cookieVal = parts.pop()?.split(";").shift();
      return cookieVal ? decodeURIComponent(cookieVal) : null;
    }
    return null;
  },
  setItem: (name: string, value: string): void => {
    if (typeof window === "undefined") return;
    const secure = window.location.protocol === "https:" ? "; Secure" : "";
    document.cookie = `${name}=${encodeURIComponent(value)}; path=/; max-age=604800; SameSite=Lax${secure}`;
  },
  removeItem: (name: string): void => {
    if (typeof window === "undefined") return;
    document.cookie = `${name}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; SameSite=Lax`;
  },
};

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isHydrated: false,

      login: (token: string, user: UserProfile): void => {
        set({ token, user, isAuthenticated: true });
      },

      logout: (): void => {
        set({ token: null, user: null, isAuthenticated: false });
      },

      setUser: (user: UserProfile): void => {
        set({ user });
      },

      setHydrated: (state: boolean): void => {
        set({ isHydrated: state });
      },
    }),
    {
      name: "sas-auth-storage",
      storage: createJSONStorage(() => cookieStorage),
      onRehydrateStorage: () => {
        return (state): void => {
          state?.setHydrated(true);
        };
      },
    }
  )
);
