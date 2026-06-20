import { describe, it, expect, beforeAll, beforeEach, afterEach, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { fireEvent } from "@testing-library/react";
import { MemoryRouter, Routes, Route, Navigate } from "react-router";
import type { Client } from "openapi-fetch";
import type { paths } from "@/api/types";
import i18n from "@/i18n";
import { setAccessToken } from "@/api/client";
import { AuthProvider } from "./AuthProvider";
import { RequireAuth, RedirectIfAuthed } from "./guards";
import { AppShell } from "@/components/shell/AppShell";
import { LoginScreen } from "@/pages/LoginScreen";
import { RegisterScreen } from "@/pages/RegisterScreen";
import { DashboardScreen } from "@/pages/DashboardScreen";
import { SettingsScreen } from "@/pages/SettingsScreen";

/*
 * Protected routing (issue 03): unauthenticated visitors to app routes bounce to
 * /login; authenticated visitors to /login or /register bounce to the Dashboard;
 * logout drops the session and returns to /login.
 */
const USERNAME_KEY = "money-lover.username";

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function mockRefresh(ok: boolean): void {
  vi.stubGlobal(
    "fetch",
    vi.fn(async () =>
      ok
        ? jsonResponse(
            {
              access_token: "tok",
              refresh_token: "r",
              token_type: "Bearer",
              expires_in: 900,
            },
            200,
          )
        : jsonResponse(
            { error: { code: "unauthorized", message: "no cookie" } },
            401,
          ),
    ),
  );
}

function renderApp(initialPath: string, client: Client<paths>) {
  return render(
    <AuthProvider client={client}>
      <MemoryRouter initialEntries={[initialPath]}>
        <Routes>
          <Route element={<RedirectIfAuthed />}>
            <Route path="/login" element={<LoginScreen />} />
            <Route path="/register" element={<RegisterScreen />} />
          </Route>
          <Route element={<RequireAuth />}>
            <Route element={<AppShell />}>
              <Route path="/" element={<DashboardScreen />} />
              <Route path="/settings" element={<SettingsScreen />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </MemoryRouter>
    </AuthProvider>,
  );
}

function fakeClient(): Client<paths> {
  return {
    POST: vi.fn().mockResolvedValue({ data: {} }),
    GET: vi.fn().mockResolvedValue({ data: {} }),
  } as unknown as Client<paths>;
}

describe("protected routing", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  beforeEach(() => {
    setAccessToken(undefined);
    localStorage.clear();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("redirects an unauthenticated visitor from an app route to /login", async () => {
    mockRefresh(false);
    renderApp("/", fakeClient());

    await waitFor(() =>
      expect(screen.getByText("Welcome back")).toBeInTheDocument(),
    );
  });

  it("redirects an authenticated visitor away from /login to the Dashboard", async () => {
    localStorage.setItem(USERNAME_KEY, "alice");
    mockRefresh(true);
    renderApp("/login", fakeClient());

    await waitFor(() =>
      expect(screen.getByText("Dashboard coming soon")).toBeInTheDocument(),
    );
    expect(screen.queryByText("Welcome back")).not.toBeInTheDocument();
  });

  it("redirects an authenticated visitor away from /register to the Dashboard", async () => {
    localStorage.setItem(USERNAME_KEY, "alice");
    mockRefresh(true);
    renderApp("/register", fakeClient());

    await waitFor(() =>
      expect(screen.getByText("Dashboard coming soon")).toBeInTheDocument(),
    );
  });

  it("logout drops the session and returns to /login", async () => {
    localStorage.setItem(USERNAME_KEY, "alice");
    mockRefresh(true);
    const client = fakeClient();
    renderApp("/settings", client);

    await waitFor(() =>
      expect(screen.getByText("Log out")).toBeInTheDocument(),
    );

    fireEvent.click(screen.getByText("Log out"));

    await waitFor(() =>
      expect(screen.getByText("Welcome back")).toBeInTheDocument(),
    );
    expect(client.POST).toHaveBeenCalledWith("/auth/logout", { body: {} });
  });
});
