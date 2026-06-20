import { describe, it, expect, beforeAll, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { Client } from "openapi-fetch";
import type { components, paths } from "@/api/types";
import i18n from "@/i18n";
import { DashboardScreen } from "./DashboardScreen";

type NetWorth = components["schemas"]["NetWorth"];
type SignalList = components["schemas"]["SignalList"];

const NET_WORTH: NetWorth = {
  asset: { amount_minor: 125_000_000, currency: "VND" },
  debt: { amount_minor: -30_000_000, currency: "VND" },
  net: { amount_minor: 95_000_000, currency: "VND" },
};

const SIGNALS: SignalList = {
  signals: [
    {
      id: "projectedOverspend-12",
      kind: "projectedOverspend",
      severity: "warning",
      title: "Food is on track to overspend",
      detail: "At this pace it runs out before month-end.",
    },
    {
      id: "goalBehind-3",
      kind: "goalBehind",
      severity: "info",
      title: "Emergency fund is behind plan",
      detail: "You're a month behind the saving schedule.",
    },
  ],
};

/**
 * A stub typed client that answers each endpoint independently so net-worth and
 * signals states can be exercised in isolation. `undefined` overrides → reject.
 */
function stubClient(opts: {
  netWorth?: { data?: NetWorth; error?: unknown };
  signals?: { data?: SignalList; error?: unknown };
}): Client<paths> {
  return {
    GET: vi.fn((path: string) => {
      if (path === "/api/net_worth") {
        return Promise.resolve(opts.netWorth ?? { error: { detail: "boom" } });
      }
      if (path === "/signals") {
        return Promise.resolve(opts.signals ?? { error: { detail: "boom" } });
      }
      return Promise.resolve({ error: { detail: "unknown path" } });
    }),
  } as unknown as Client<paths>;
}

function renderDashboard(client: Client<paths>) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <DashboardScreen client={client} />
    </QueryClientProvider>,
  );
}

describe("DashboardScreen", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  describe("net worth", () => {
    it("renders asset, debt and net formatted as ₫ from minor units", async () => {
      const client = stubClient({
        netWorth: { data: NET_WORTH },
        signals: { data: { signals: [] } },
      });

      renderDashboard(client);

      // Assets 125_000_000 minor → vi-VN ₫ string; no client arithmetic.
      await waitFor(() =>
        expect(screen.getByText(/125\.000\.000/)).toBeInTheDocument(),
      );
      // Debt is kept negative by the API and shown verbatim.
      expect(screen.getByText(/-30\.000\.000/)).toBeInTheDocument();
      // Net is the API's `net` field — never asset+debt computed here.
      expect(screen.getByText(/95\.000\.000/)).toBeInTheDocument();
      expect(client.GET).toHaveBeenCalledWith("/api/net_worth");
    });

    it("shows a loading state while net worth is pending", () => {
      const client = stubClient({
        netWorth: { data: NET_WORTH },
        signals: { data: { signals: [] } },
      });

      renderDashboard(client);

      expect(screen.getByText("Loading net worth…")).toBeInTheDocument();
    });

    it("shows an error state when net worth fails", async () => {
      const client = stubClient({
        netWorth: { error: { detail: "boom" } },
        signals: { data: { signals: [] } },
      });

      renderDashboard(client);

      await waitFor(() =>
        expect(
          screen.getByText("Couldn't load your net worth."),
        ).toBeInTheDocument(),
      );
    });
  });

  describe("signals", () => {
    it("renders each signal's title and detail verbatim", async () => {
      const client = stubClient({
        netWorth: { data: NET_WORTH },
        signals: { data: SIGNALS },
      });

      renderDashboard(client);

      await waitFor(() =>
        expect(
          screen.getByText("Food is on track to overspend"),
        ).toBeInTheDocument(),
      );
      expect(
        screen.getByText("At this pace it runs out before month-end."),
      ).toBeInTheDocument();
      expect(
        screen.getByText("Emergency fund is behind plan"),
      ).toBeInTheDocument();
      expect(client.GET).toHaveBeenCalledWith("/signals");
    });

    it("shows an empty state when there are no signals", async () => {
      const client = stubClient({
        netWorth: { data: NET_WORTH },
        signals: { data: { signals: [] } },
      });

      renderDashboard(client);

      await waitFor(() =>
        expect(
          screen.getByText("No signals right now — you're all caught up."),
        ).toBeInTheDocument(),
      );
    });

    it("shows an error state when signals fail", async () => {
      const client = stubClient({
        netWorth: { data: NET_WORTH },
        signals: { error: { detail: "boom" } },
      });

      renderDashboard(client);

      await waitFor(() =>
        expect(
          screen.getByText("Couldn't load your signals."),
        ).toBeInTheDocument(),
      );
    });
  });
});
