import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import {
  createApiClient,
  getAccessToken,
  setAccessToken,
  setAuthFailureHandler,
} from "./client";

/*
 * The session-on-the-wire concern (ADR-0014 / ADR-0018): every request carries
 * the in-memory access token as a Bearer header, and a 401 transparently rotates
 * the token via POST /auth/refresh (httpOnly cookie sent automatically) and
 * replays the original request once. A refresh failure routes to /login.
 *
 * These mock the global fetch the client calls, so they bite: break refresh-on-
 * 401 and the request surfaces the 401 instead of the retried 200.
 */
function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function urlOf(input: RequestInfo | URL): string {
  if (typeof input === "string") return input;
  if (input instanceof URL) return input.toString();
  return (input as Request).url;
}

describe("typed API client — session on the wire", () => {
  beforeEach(() => {
    setAccessToken(undefined);
    setAuthFailureHandler(undefined);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("attaches the in-memory access token as a Bearer header", async () => {
    const fetchMock = vi.fn(
      async (_input: RequestInfo | URL, _init?: RequestInit) =>
        jsonResponse({ status: "ok" }, 200),
    );
    vi.stubGlobal("fetch", fetchMock);

    setAccessToken("access-1");
    const client = createApiClient("http://api.test");
    await client.GET("/health");

    const req = fetchMock.mock.calls[0][0] as Request;
    expect(req.headers.get("Authorization")).toBe("Bearer access-1");
  });

  it("transparently refreshes on a 401 and replays with the new token", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
      const url = urlOf(input);
      if (url.endsWith("/auth/refresh")) {
        return jsonResponse(
          {
            access_token: "access-2",
            refresh_token: "r2",
            token_type: "Bearer",
            expires_in: 900,
          },
          200,
        );
      }
      const auth = (input as Request).headers.get("Authorization");
      if (auth === "Bearer access-2") return jsonResponse({ status: "ok" }, 200);
      return jsonResponse(
        { error: { code: "unauthorized", message: "expired" } },
        401,
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    setAccessToken("access-1");
    const client = createApiClient("http://api.test");
    const { data, error } = await client.GET("/health");

    expect(error).toBeUndefined();
    expect(data).toEqual({ status: "ok" });
    expect(getAccessToken()).toBe("access-2");

    // original (401) → refresh → retry (200)
    expect(fetchMock).toHaveBeenCalledTimes(3);
    const refreshCall = fetchMock.mock.calls.find((c) =>
      urlOf(c[0] as RequestInfo).endsWith("/auth/refresh"),
    );
    expect(refreshCall).toBeDefined();
    expect((refreshCall?.[1] as RequestInit).credentials).toBe("include");
  });

  it("routes to login when the refresh itself fails", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
      const url = urlOf(input);
      if (url.endsWith("/auth/refresh")) {
        return jsonResponse(
          { error: { code: "unauthorized", message: "no cookie" } },
          401,
        );
      }
      return jsonResponse(
        { error: { code: "unauthorized", message: "expired" } },
        401,
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const onAuthFailure = vi.fn();
    setAuthFailureHandler(onAuthFailure);
    setAccessToken("access-1");

    const client = createApiClient("http://api.test");
    const { error } = await client.GET("/health");

    expect(onAuthFailure).toHaveBeenCalledTimes(1);
    expect(error).toBeDefined();
    expect(getAccessToken()).toBeUndefined();
  });
});
