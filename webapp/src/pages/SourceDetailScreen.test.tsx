import { describe, it, expect, beforeAll, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter, Routes, Route } from "react-router";
import type { Client } from "openapi-fetch";
import type { paths, Source } from "@/api/types";
import i18n from "@/i18n";
import { SourceDetailScreen } from "./SourceDetailScreen";

const usdAccount: Source = {
  id: 2,
  kind: "account",
  name: "USD savings",
  currency: "USD",
  opening_balance: { amount_minor: 9_000, currency: "USD" },
  current_balance: { amount_minor: 10_000, currency: "USD" },
  valuation: { amount_minor: 2_540_000, currency: "VND" },
};

const stockHolding: Source = {
  id: 5,
  kind: "holding",
  name: "FPT shares",
  currency: "VND",
  holding: { opening_quantity: "150", unit: "shares", ticker: "FPT" },
  current_balance: { amount_minor: 18_000_000, currency: "VND" },
  valuation: { amount_minor: 18_000_000, currency: "VND" },
};

function clientReturning(source: Source): Client<paths> {
  return {
    GET: vi.fn().mockResolvedValue({ data: source }),
  } as unknown as Client<paths>;
}

function renderDetail(client: Client<paths>, id = "2") {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[`/sources/${id}`]}>
        <Routes>
          <Route
            path="/sources/:id"
            element={<SourceDetailScreen client={client} />}
          />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

describe("SourceDetailScreen (read-only detail)", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  it("renders a foreign-currency account with native + VND valuation", async () => {
    renderDetail(clientReturning(usdAccount), "2");

    await waitFor(() =>
      expect(screen.getByText("USD savings")).toBeInTheDocument(),
    );
    expect(screen.getByText("Current balance")).toBeInTheDocument();
    expect(screen.getByText(/100,00/)).toBeInTheDocument();
    expect(screen.getByText("Value in VND")).toBeInTheDocument();
    expect(screen.getByText(/2\.540\.000/)).toBeInTheDocument();
  });

  it("renders a holding's quantity, ticker, and VND valuation (exact strings)", async () => {
    renderDetail(clientReturning(stockHolding), "5");

    await waitFor(() =>
      expect(screen.getByText("FPT shares")).toBeInTheDocument(),
    );
    expect(screen.getByText("150 shares")).toBeInTheDocument();
    expect(screen.getByText("FPT")).toBeInTheDocument();
    expect(screen.getByText(/18\.000\.000/)).toBeInTheDocument();
  });

  it("surfaces an error state when the request fails", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({ error: { detail: "nope" } }),
    } as unknown as Client<paths>;

    renderDetail(client, "2");

    await waitFor(() =>
      expect(
        screen.getByText("We couldn't load this source."),
      ).toBeInTheDocument(),
    );
  });
});
