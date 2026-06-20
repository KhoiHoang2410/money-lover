import { describe, it, expect, beforeAll, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { Client } from "openapi-fetch";
import type { paths } from "@/api/types";
import i18n from "@/i18n";
import { HealthScreen } from "./HealthScreen";

function renderWithClient(client: Client<paths>) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <HealthScreen client={client} />
    </QueryClientProvider>,
  );
}

describe("HealthScreen (proof screen)", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  it("renders live status read through the typed client", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({ data: { status: "ok" } }),
    } as unknown as Client<paths>;

    renderWithClient(client);

    expect(screen.getByText("System health")).toBeInTheDocument();
    await waitFor(() =>
      expect(screen.getByText("Operational")).toBeInTheDocument(),
    );
    expect(client.GET).toHaveBeenCalledWith("/health");
  });

  it("formats the sample balance as ₫ from integer minor units", () => {
    const client = {
      GET: vi.fn().mockResolvedValue({ data: { status: "ok" } }),
    } as unknown as Client<paths>;

    renderWithClient(client);

    expect(screen.getByText(/125\.000\.000/)).toBeInTheDocument();
  });

  it("surfaces an error state when the request fails", async () => {
    const client = {
      GET: vi.fn().mockResolvedValue({ error: { detail: "boom" } }),
    } as unknown as Client<paths>;

    renderWithClient(client);

    await waitFor(() =>
      expect(screen.getByText("Unreachable")).toBeInTheDocument(),
    );
  });
});
