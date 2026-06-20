import { test, expect, type Route } from "@playwright/test";

/*
 * Envelopes write-flow e2e (issue 08). Hermetic: both /auth/** and /api/** are
 * mocked at the network layer (page.route), so no live backend is needed.
 *
 * The API mock holds the Envelope list as server-side state. POST /api/envelopes
 * appends one (with the month figures BudgetEngine would compute) and every
 * subsequent GET reflects it. The regression bite: the new Envelope only appears
 * because the create mutation invalidates the cache and the list re-reads it —
 * break the invalidation and the final assertion fails. No sleeps; we wait on
 * elements.
 */
const TOKEN_PAIR = {
  access_token: "e2e-access",
  refresh_token: "e2e-refresh",
  token_type: "Bearer",
  expires_in: 900,
};

const vnd = (amount_minor: number) => ({ amount_minor, currency: "VND" });

test("create an envelope → it appears with its month figures", async ({
  page,
}) => {
  const session = { active: false };
  type Envelope = {
    id: number;
    name: string;
    icon: string | null;
    is_reserve: boolean;
    currency: string;
    allocation: { amount_minor: number; currency: string };
    carried: { amount_minor: number; currency: string };
    spent: { amount_minor: number; currency: string };
    remaining: { amount_minor: number; currency: string };
  };
  const envelopes: Envelope[] = [];
  let nextId = 1;

  const corsFor = (origin: string) => ({
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
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

  await page.route("**/api/envelopes", async (route: Route) => {
    const req = route.request();
    const origin = req.headers()["origin"] ?? "";
    const cors = corsFor(origin);
    const json = (status: number, body: unknown) =>
      route.fulfill({
        status,
        headers: { ...cors, "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
    if (req.method() === "OPTIONS") {
      return route.fulfill({ status: 204, headers: cors });
    }
    if (req.method() === "GET") {
      return json(200, { envelopes });
    }
    if (req.method() === "POST") {
      const body = JSON.parse(req.postData() ?? "{}");
      const alloc = body.allocation_minor_units ?? 0;
      // The figures BudgetEngine would return for a brand-new Envelope.
      const created: Envelope = {
        id: nextId++,
        name: body.name,
        icon: body.icon ?? null,
        is_reserve: body.is_reserve ?? false,
        currency: "VND",
        allocation: vnd(alloc),
        carried: vnd(0),
        spent: vnd(0),
        remaining: vnd(alloc),
      };
      envelopes.push(created);
      return json(201, created);
    }
    return route.continue();
  });

  // Sign in through the real form so the app holds a session.
  await page.goto("/register");
  await expect(page.getByText("Create your account")).toBeVisible();
  await page.getByLabel("Username or email").fill("e2e_user");
  await page.getByLabel("Password", { exact: true }).fill("secret123");
  await page.getByLabel("Confirm password").fill("secret123");
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(page.getByRole("button", { name: "Open settings" })).toBeVisible();

  // Navigate to Envelopes; starts empty.
  await page.getByRole("link", { name: "Envelopes" }).first().click();
  await expect(page.getByText("No envelopes yet")).toBeVisible();

  // Create an Envelope.
  await page.getByRole("button", { name: "New envelope" }).first().click();
  await page.getByLabel("Name").fill("Groceries");
  await page.getByLabel("Monthly allocation (₫)").fill("3.000.000");
  await page.getByRole("button", { name: "Save" }).click();

  // It appears in the list with its month figures (no sleep — wait on elements).
  await expect(page.getByText("Groceries")).toBeVisible();
  await expect(page.getByText(/3\.000\.000/).first()).toBeVisible();
});
