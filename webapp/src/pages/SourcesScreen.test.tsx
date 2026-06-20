import { describe, it, expect, beforeAll, vi } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router";
import type { Client } from "openapi-fetch";
import type { paths, Source, SourceList } from "@/api/types";
import i18n from "@/i18n";
import { SourcesScreen } from "./SourcesScreen";

const vndAccount: Source = {
  id: 1,
  kind: "account",
  name: "Cash wallet",
  currency: "VND",
  current_balance: { amount_minor: 2_500_000, currency: "VND" },
  valuation: { amount_minor: 2_500_000, currency: "VND" },
};

const usdAccount: Source = {
  id: 2,
  kind: "account",
  name: "USD savings",
  currency: "USD",
  current_balance: { amount_minor: 10_000, currency: "USD" },
  valuation: { amount_minor: 2_540_000, currency: "VND" },
};

const creditCard: Source = {
  id: 3,
  kind: "credit_card",
  name: "Visa",
  currency: "VND",
  current_balance: { amount_minor: -1_200_000, currency: "VND" },
  valuation: { amount_minor: -1_200_000, currency: "VND" },
};

const goldHolding: Source = {
  id: 4,
  kind: "holding",
  name: "SJC gold",
  currency: "VND",
  holding: { opening_quantity: "3", unit: "chi" },
  current_balance: { amount_minor: 21_000_000, currency: "VND" },
  valuation: { amount_minor: 21_000_000, currency: "VND" },
};

function clientReturning(sources: Source[]): Client<paths> {
  const body: SourceList = { sources };
  return {
    GET: vi.fn().mockResolvedValue({ data: body }),
  } as unknown as Client<paths>;
}

function renderScreen(client: Client<paths>) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <SourcesScreen client={client} />
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

describe("SourcesScreen (read-only list)", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  it("lists all three kinds under labeled groups", async () => {
    renderScreen(
      clientReturning([vndAccount, usdAccount, creditCard, goldHolding]),
    );

    await waitFor(() =>
      expect(screen.getByText("Cash wallet")).toBeInTheDocument(),
    );
    expect(screen.getByText("Accounts")).toBeInTheDocument();
    expect(screen.getByText("Credit cards")).toBeInTheDocument();
    expect(screen.getByText("Holdings")).toBeInTheDocument();
    expect(screen.getByText("Visa")).toBeInTheDocument();
    expect(screen.getByText("SJC gold")).toBeInTheDocument();
  });

  it("shows native + VND valuation for a foreign-currency account", async () => {
    renderScreen(clientReturning([usdAccount]));

    const row = (await screen.findByText("USD savings")).closest("a");
    expect(row).not.toBeNull();
    const scoped = within(row as HTMLElement);
    // Native USD figure and the VND valuation both render (formatting only).
    expect(scoped.getByText(/100,00/)).toBeInTheDocument();
    expect(scoped.getByText(/2\.540\.000/)).toBeInTheDocument();
  });

  it("shows quantity + VND valuation for a holding (exact string, no math)", async () => {
    renderScreen(clientReturning([goldHolding]));

    const row = (await screen.findByText("SJC gold")).closest("a");
    const scoped = within(row as HTMLElement);
    expect(scoped.getByText("3 chỉ")).toBeInTheDocument();
    expect(scoped.getByText(/21\.000\.000/)).toBeInTheDocument();
  });

  it("renders an empty state when there are no sources", async () => {
    renderScreen(clientReturning([]));

    await waitFor(() =>
      expect(screen.getByText("No money sources yet.")).toBeInTheDocument(),
    );
  });

  it("surfaces an error state when the request fails", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({ error: { detail: "boom" } }),
    } as unknown as Client<paths>;

    renderScreen(client);

    await waitFor(() =>
      expect(
        screen.getByText("We couldn't load your sources."),
      ).toBeInTheDocument(),
    );
  });
});
