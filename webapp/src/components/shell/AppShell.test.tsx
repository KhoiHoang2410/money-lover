import { describe, it, expect, beforeAll, afterEach, vi } from "vitest";
import { render, screen, act } from "@testing-library/react";
import { MemoryRouter, Routes, Route } from "react-router";
import i18n from "@/i18n";
import { AuthContext, type AuthContextValue } from "@/auth/context";
import { AppShell } from "./AppShell";

/*
 * Responsive app shell (PRD IA): full sidebar (≥1024px) → icon-rail (≥768px) →
 * hamburger drawer (<768px), driven by matchMedia so exactly one nav lives in
 * the DOM per breakpoint. The chrome copy is fully i18n-reactive.
 */
function noMatchMql(query: string): MediaQueryList {
  return {
    matches: false,
    media: query,
    onchange: null,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    addListener: vi.fn(),
    removeListener: vi.fn(),
    dispatchEvent: vi.fn(),
  } as unknown as MediaQueryList;
}

function setViewportWidth(width: number): void {
  window.matchMedia = ((query: string) => {
    const m = /\(min-width:\s*(\d+)px\)/.exec(query);
    const min = m ? Number(m[1]) : 0;
    return { ...noMatchMql(query), matches: width >= min } as MediaQueryList;
  }) as typeof window.matchMedia;
}

const AUTHED: AuthContextValue = {
  status: "authed",
  user: { username: "alice" },
  login: vi.fn(),
  register: vi.fn(),
  logout: vi.fn(),
};

function renderShell() {
  return render(
    <AuthContext.Provider value={AUTHED}>
      <MemoryRouter initialEntries={["/"]}>
        <Routes>
          <Route element={<AppShell />}>
            <Route path="/" element={<div data-testid="content" />} />
          </Route>
        </Routes>
      </MemoryRouter>
    </AuthContext.Provider>,
  );
}

describe("AppShell responsive modes", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  afterEach(async () => {
    window.matchMedia = ((query: string) =>
      noMatchMql(query)) as typeof window.matchMedia;
    await act(async () => {
      await i18n.changeLanguage("en-US");
    });
  });

  it("renders the full sidebar at desktop width (≥1024px)", () => {
    setViewportWidth(1280);
    renderShell();

    const sidebar = screen.getByTestId("app-sidebar");
    expect(sidebar).toHaveAttribute("data-mode", "sidebar");
    expect(
      screen.queryByLabelText("Open navigation menu"),
    ).not.toBeInTheDocument();
  });

  it("collapses to an icon-rail at tablet width (768–1023px)", () => {
    setViewportWidth(820);
    renderShell();

    expect(screen.getByTestId("app-sidebar")).toHaveAttribute(
      "data-mode",
      "rail",
    );
  });

  it("becomes a hamburger drawer at mobile width (<768px)", () => {
    setViewportWidth(480);
    renderShell();

    expect(screen.queryByTestId("app-sidebar")).not.toBeInTheDocument();
    expect(
      screen.getByLabelText("Open navigation menu"),
    ).toBeInTheDocument();
  });

  it("updates chrome copy when the language switches", async () => {
    setViewportWidth(1280);
    renderShell();

    expect(screen.getAllByText("Dashboard").length).toBeGreaterThan(0);

    await act(async () => {
      await i18n.changeLanguage("vi-VN");
    });

    expect(screen.getAllByText("Tổng quan").length).toBeGreaterThan(0);
    expect(screen.queryByText("Dashboard")).not.toBeInTheDocument();
  });
});
