import { test, expect, type Route } from "@playwright/test";

/*
 * Session-survival e2e (issue 03 / memory standard): register → authed shell →
 * reload stays authed → logout → back at /login.
 *
 * Hermetic: the Rails API is mocked at the network layer. The mock models the
 * httpOnly refresh-cookie session as server-side state (`session.active`):
 *   register/login → active = true
 *   refresh        → 200 token pair when active, else 401
 *   logout         → active = false
 * Because the access token is memory-only (ADR-0014), "reload stays authed" is
 * ONLY possible if the app calls POST /auth/refresh on load and applies the new
 * token. Break refresh-on-load and the reload assertion fails — the test bites.
 */
const TOKEN_PAIR = {
  access_token: "e2e-access",
  refresh_token: "e2e-refresh",
  token_type: "Bearer",
  expires_in: 900,
};

test("register, survive reload, then logout", async ({ page }) => {
  const session = { active: false };

  const corsFor = (origin: string) => ({
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept",
  });

  await page.route("**/auth/**", async (route: Route) => {
    const req = route.request();
    const origin = req.headers()["origin"] ?? "";
    const cors = corsFor(origin);
    const path = new URL(req.url()).pathname;

    if (req.method() === "OPTIONS") {
      return route.fulfill({ status: 204, headers: cors });
    }

    const json = (status: number, body: unknown) =>
      route.fulfill({
        status,
        headers: { ...cors, "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

    if (path.endsWith("/auth/register") || path.endsWith("/auth/login")) {
      session.active = true;
      return json(201, TOKEN_PAIR);
    }
    if (path.endsWith("/auth/refresh")) {
      return session.active
        ? json(200, TOKEN_PAIR)
        : json(401, { error: { code: "unauthorized", message: "no session" } });
    }
    if (path.endsWith("/auth/logout")) {
      session.active = false;
      return route.fulfill({ status: 204, headers: cors });
    }
    return route.continue();
  });

  // The authed Dashboard (issue #110) fetches net worth + signals on mount.
  // Mock them hermetically so the landing render is deterministic; the auth
  // assertions below stay the regression bite (only refresh-on-load survives a
  // reload), these just keep the dashboard from hitting real network.
  const apiJson = (origin: string, body: unknown) => ({
    status: 200,
    headers: { ...corsFor(origin), "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  await page.route("**/api/net_worth", async (route: Route) => {
    const origin = route.request().headers()["origin"] ?? "";
    if (route.request().method() === "OPTIONS") {
      return route.fulfill({ status: 204, headers: corsFor(origin) });
    }
    return route.fulfill(
      apiJson(origin, {
        asset: { amount_minor: 5_000_000, currency: "VND" },
        debt: { amount_minor: 1_500_000, currency: "VND" },
        net: { amount_minor: 3_500_000, currency: "VND" },
      }),
    );
  });

  await page.route("**/signals", async (route: Route) => {
    const origin = route.request().headers()["origin"] ?? "";
    if (route.request().method() === "OPTIONS") {
      return route.fulfill({ status: 204, headers: corsFor(origin) });
    }
    return route.fulfill(apiJson(origin, { signals: [] }));
  });

  // Unauthenticated deep-link to /register renders the register form (the
  // bootstrap refresh 401s while session is inactive).
  await page.goto("/register");
  await expect(page.getByText("Create your account")).toBeVisible();

  await page.getByLabel("Username or email").fill("e2e_user");
  await page.getByLabel("Password", { exact: true }).fill("secret123");
  await page.getByLabel("Confirm password").fill("secret123");
  await page.getByRole("button", { name: "Create account" }).click();

  // Lands authenticated inside the app shell (profile chip + Dashboard hero).
  await expect(page.getByRole("button", { name: "Open settings" })).toBeVisible();
  await expect(page.getByText("Net worth")).toBeVisible();

  // Reload: the access token is gone from memory; only refresh-on-load can
  // restore the session. This is the regression bite.
  await page.reload();
  await expect(page.getByRole("button", { name: "Open settings" })).toBeVisible();
  await expect(page.getByText("Net worth")).toBeVisible();

  // Logout from Settings → redirected back to /login.
  await page.getByRole("button", { name: "Open settings" }).click();
  await expect(page.getByText("Preferences")).toBeVisible();
  await page.getByRole("button", { name: "Log out" }).click();

  await expect(page.getByText("Welcome back")).toBeVisible();

  // And a reload now stays signed out (session was revoked).
  await page.reload();
  await expect(page.getByText("Welcome back")).toBeVisible();
});
