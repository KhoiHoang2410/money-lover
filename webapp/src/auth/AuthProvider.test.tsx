import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { getAccessToken, setAccessToken } from "@/api/client";
import { AuthProvider } from "./AuthProvider";
import { useAuth } from "./context";

/*
 * Bootstrap = "reload stays signed in" (ADR-0014): on load the provider mints an
 * access token from the httpOnly refresh cookie. Success → authed (token in
 * memory, username restored from localStorage); failure → unauthed.
 */
const USERNAME_KEY = "money-lover.username";

function StatusProbe() {
  const { status, user } = useAuth();
  return (
    <div>
      <span data-testid="status">{status}</span>
      <span data-testid="user">{user?.username ?? "none"}</span>
    </div>
  );
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

describe("AuthProvider bootstrap (refresh-on-load)", () => {
  beforeEach(() => {
    setAccessToken(undefined);
    localStorage.clear();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("restores the session when the refresh cookie yields a token", async () => {
    localStorage.setItem(USERNAME_KEY, "alice");
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        jsonResponse(
          {
            access_token: "fresh-token",
            refresh_token: "r",
            token_type: "Bearer",
            expires_in: 900,
          },
          200,
        ),
      ),
    );

    render(
      <AuthProvider>
        <StatusProbe />
      </AuthProvider>,
    );

    await waitFor(() =>
      expect(screen.getByTestId("status")).toHaveTextContent("authed"),
    );
    expect(getAccessToken()).toBe("fresh-token");
    expect(screen.getByTestId("user")).toHaveTextContent("alice");
  });

  it("lands unauthed and clears the token when refresh fails", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        jsonResponse(
          { error: { code: "unauthorized", message: "no cookie" } },
          401,
        ),
      ),
    );

    render(
      <AuthProvider>
        <StatusProbe />
      </AuthProvider>,
    );

    await waitFor(() =>
      expect(screen.getByTestId("status")).toHaveTextContent("unauthed"),
    );
    expect(getAccessToken()).toBeUndefined();
  });
});
