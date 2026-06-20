import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import type { Client } from "openapi-fetch";
import type { paths } from "@/api/types";
import {
  apiClient,
  refreshSession,
  setAccessToken,
  setAuthFailureHandler,
} from "@/api/client";
import { toApiError } from "./api-error";
import {
  AuthContext,
  type AuthStatus,
  type AuthUser,
  type LoginInput,
  type RegisterInput,
} from "./context";

// The username is display-only (the profile chip) and survives reloads via
// localStorage so the chip renders immediately after a cookie refresh. The
// access token is NOT persisted — it stays in JS memory (ADR-0014).
const USERNAME_KEY = "money-lover.username";

// Typed initial state values, kept generic-free so the i18n copy scanner (which
// reads .tsx files) is never confused by `useState<Union>` angle brackets.
const INITIAL_STATUS: AuthStatus = "loading";
const NO_USER: AuthUser | null = null;

function readStoredUsername(): string | null {
  try {
    return localStorage.getItem(USERNAME_KEY);
  } catch {
    return null;
  }
}

function storeUsername(username: string | null): void {
  try {
    if (username) localStorage.setItem(USERNAME_KEY, username);
    else localStorage.removeItem(USERNAME_KEY);
  } catch {
    /* ignore quota / disabled storage */
  }
}

interface AuthProviderProps {
  children: React.ReactNode;
  /** Injectable for tests; defaults to the real typed client. */
  client?: Client<paths>;
}

export function AuthProvider({
  children,
  client = apiClient,
}: AuthProviderProps) {
  const [status, setStatus] = useState(INITIAL_STATUS);
  const [user, setUser] = useState(NO_USER);

  const setSignedIn = useCallback((username: string) => {
    storeUsername(username);
    setUser({ username });
    setStatus("authed");
  }, []);

  const setSignedOut = useCallback(() => {
    setAccessToken(undefined);
    storeUsername(null);
    setUser(null);
    setStatus("unauthed");
  }, []);

  // A transparent-refresh failure (from the client interceptor) drops us to the
  // signed-out state, which sends protected routes to /login. Keep the handler
  // stable across renders via a ref so we register it exactly once.
  const setSignedOutRef = useRef(setSignedOut);
  setSignedOutRef.current = setSignedOut;
  useEffect(() => {
    setAuthFailureHandler(() => setSignedOutRef.current());
    return () => setAuthFailureHandler(undefined);
  }, []);

  // Bootstrap: on load, try to mint an access token from the refresh cookie.
  // Success → restore the session; failure → signed out. This is what makes a
  // reload keep the user signed in.
  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const ok = await refreshSession();
      if (cancelled) return;
      if (ok) {
        const username = readStoredUsername();
        setUser(username ? { username } : null);
        setStatus("authed");
      } else {
        setSignedOut();
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [setSignedOut]);

  const register = useCallback(
    async ({ username, password, timezone }: RegisterInput) => {
      const { data, error } = await client.POST("/auth/register", {
        body: { username, password, timezone },
      });
      if (error) throw toApiError(error);
      setAccessToken(data.access_token);
      setSignedIn(username);
    },
    [client, setSignedIn],
  );

  const login = useCallback(
    async ({ username, password }: LoginInput) => {
      const { data, error } = await client.POST("/auth/login", {
        body: { username, password },
      });
      if (error) throw toApiError(error);
      setAccessToken(data.access_token);
      setSignedIn(username);
    },
    [client, setSignedIn],
  );

  const logout = useCallback(async () => {
    // Revoke server-side (idempotent); clear local state regardless of outcome.
    try {
      await client.POST("/auth/logout", { body: {} });
    } catch {
      /* network error — still clear locally */
    }
    setSignedOut();
  }, [client, setSignedOut]);

  const value = useMemo(
    () => ({ status, user, register, login, logout }),
    [status, user, register, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
