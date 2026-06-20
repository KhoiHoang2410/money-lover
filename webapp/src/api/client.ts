import createClient, { type Client } from "openapi-fetch";
import type { paths } from "@/api/types";

/*
 * The ONE place HTTP happens (ADR-0018). Every request goes through this typed
 * `openapi-fetch` client, generated from the OpenAPI contract types — so a
 * request path, param, or response shape that drifts from the contract is a
 * TypeScript compile error, not a runtime surprise.
 *
 * Session model (ADR-0014): the access token lives in JS memory only; the
 * refresh token lives in an httpOnly cookie the browser sends automatically
 * (credentials: "include"). This module owns the whole session-on-the-wire
 * concern: it attaches the bearer token, and on a 401 it transparently rotates
 * the access token via POST /auth/refresh and replays the original request once.
 * Auth flows (register/login/logout) and React session state read/write the
 * in-memory token through the small surface exported here — nowhere else.
 */

export const API_BASE_URL: string =
  import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3000";

let accessToken: string | undefined;

/** Set/clear the bearer token used on authenticated requests. */
export function setAccessToken(token: string | undefined): void {
  accessToken = token;
}

/** The current in-memory access token (undefined when signed out). */
export function getAccessToken(): string | undefined {
  return accessToken;
}

// Called when a transparent refresh fails — the React session uses this to drop
// to the signed-out state (which routes protected views to /login).
let onAuthFailure: (() => void) | undefined;
export function setAuthFailureHandler(fn: (() => void) | undefined): void {
  onAuthFailure = fn;
}

// The /auth/* surface is the credential exchange itself: never try to "refresh"
// a failed auth call (that would recurse) — surface its 401 to the caller.
const AUTH_PATH = "/auth/";
function isAuthPath(url: string): boolean {
  return url.includes(AUTH_PATH);
}

// Single-flight guard: many in-flight requests can 401 at once after the access
// token expires; they must share one refresh round-trip, not stampede /auth.
let refreshInFlight: Promise<boolean> | undefined;

/*
 * Rotate the access token using the httpOnly refresh cookie (sent automatically
 * by credentials: "include"). Hits /auth/refresh with the raw fetch — bypassing
 * the typed client's retry logic on purpose — and updates the in-memory token.
 * Resolves true when a fresh access token was minted, false otherwise.
 */
export function refreshSession(baseUrl: string = API_BASE_URL): Promise<boolean> {
  refreshInFlight ??= (async () => {
    try {
      const res = await fetch(`${baseUrl}/auth/refresh`, {
        method: "POST",
        credentials: "include",
        headers: { Accept: "application/json" },
      });
      if (!res.ok) {
        setAccessToken(undefined);
        return false;
      }
      const pair = (await res.json()) as { access_token?: string };
      if (!pair.access_token) {
        setAccessToken(undefined);
        return false;
      }
      setAccessToken(pair.access_token);
      return true;
    } catch {
      setAccessToken(undefined);
      return false;
    } finally {
      refreshInFlight = undefined;
    }
  })();
  return refreshInFlight;
}

// Custom fetch: attach nothing here (the onRequest middleware sets the bearer);
// clone the request BEFORE sending so a 401 can be replayed with a fresh token.
const authFetch: typeof fetch = async (input, init) => {
  const request = input as Request;
  const retry = request.clone();

  const res = await fetch(request, init);
  if (res.status !== 401 || isAuthPath(request.url)) return res;

  const refreshed = await refreshSession();
  if (!refreshed) {
    onAuthFailure?.();
    return res;
  }
  if (accessToken) {
    retry.headers.set("Authorization", `Bearer ${accessToken}`);
  }
  return fetch(retry, init);
};

export function createApiClient(baseUrl: string = API_BASE_URL): Client<paths> {
  const client = createClient<paths>({
    baseUrl,
    // Send/receive the httpOnly refresh cookie on cross-origin auth calls.
    credentials: "include",
    headers: { Accept: "application/json" },
    fetch: authFetch,
  });

  // Attach the bearer token (when present) to every request.
  client.use({
    onRequest({ request }) {
      if (accessToken) {
        request.headers.set("Authorization", `Bearer ${accessToken}`);
      }
      return request;
    },
  });

  return client;
}

export const apiClient: Client<paths> = createApiClient();
