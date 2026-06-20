import { createContext, useContext } from "react";

/*
 * Auth session shape (ADR-0014). `status` is the single source of truth the
 * route guards read: "loading" while the app bootstraps a refresh, then
 * "authed" / "unauthed". The access token never lives here — it stays in the
 * client module's memory; this context exposes only the actions and the
 * display-only User identity.
 */
export type AuthStatus = "loading" | "authed" | "unauthed";

export interface AuthUser {
  /** Display handle for the profile chip (username/email). Not a secret. */
  username: string;
}

export interface RegisterInput {
  username: string;
  password: string;
  timezone: string;
}

export interface LoginInput {
  username: string;
  password: string;
}

export interface AuthContextValue {
  status: AuthStatus;
  user: AuthUser | null;
  register: (input: RegisterInput) => Promise<void>;
  login: (input: LoginInput) => Promise<void>;
  logout: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | undefined>(
  undefined,
);

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within an <AuthProvider>");
  }
  return ctx;
}
