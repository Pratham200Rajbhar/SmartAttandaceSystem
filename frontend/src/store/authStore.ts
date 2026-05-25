import { create } from "zustand";
import { persist } from "zustand/middleware";
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
      onRehydrateStorage: () => {
        return (state): void => {
          state?.setHydrated(true);
        };
      },
    }
  )
);
