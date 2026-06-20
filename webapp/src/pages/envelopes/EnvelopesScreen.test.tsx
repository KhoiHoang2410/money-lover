import { describe, it, expect, beforeAll, beforeEach, vi } from "vitest";
import { render, screen, fireEvent, waitFor, within } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { Client } from "openapi-fetch";
import type { paths, Envelope } from "@/api/types";
import i18n from "@/i18n";
import { EnvelopesScreen } from "./EnvelopesScreen";

/*
 * Component/integration tests for the Envelopes feature (issue 08). The typed
 * client is mocked at the openapi-fetch surface — every figure comes from the
 * API (no client math) and each mutation must re-read the ["envelopes"] cache.
 */

const vnd = (amount_minor: number) => ({ amount_minor, currency: "VND" });

function makeEnvelope(over: Partial<Envelope> = {}): Envelope {
  return {
    id: 1,
    name: "Food",
    icon: "🍜",
    is_reserve: false,
    currency: "VND",
    allocation: vnd(3_000_000),
    carried: vnd(0),
    spent: vnd(1_200_000),
    remaining: vnd(1_800_000),
    ...over,
  };
}

interface MockClient {
  GET: ReturnType<typeof vi.fn>;
  POST: ReturnType<typeof vi.fn>;
  PATCH: ReturnType<typeof vi.fn>;
  DELETE: ReturnType<typeof vi.fn>;
}

function makeClient(over: Partial<MockClient> = {}): MockClient {
  return {
    GET: vi.fn(),
    POST: vi.fn(),
    PATCH: vi.fn(),
    DELETE: vi.fn(),
    ...over,
  };
}

function renderScreen(client: MockClient) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={queryClient}>
      <EnvelopesScreen client={client as unknown as Client<paths>} />
    </QueryClientProvider>,
  );
}

describe("EnvelopesScreen", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("lists envelopes with month figures and marks the Reserve", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({
        data: {
          envelopes: [
            makeEnvelope(),
            makeEnvelope({
              id: 2,
              name: "Savings",
              is_reserve: true,
              allocation: vnd(0),
              spent: vnd(0),
              remaining: vnd(5_000_000),
            }),
          ],
        },
      }),
    });

    renderScreen(client);

    await waitFor(() => expect(screen.getByText("Food")).toBeInTheDocument());
    // Allocation / spent / remaining figures, all ₫-formatted from minor units.
    expect(screen.getByText(/3\.000\.000/)).toBeInTheDocument();
    expect(screen.getByText(/1\.200\.000/)).toBeInTheDocument();
    expect(screen.getByText(/1\.800\.000/)).toBeInTheDocument();
    // Reserve is visually distinguished with a badge.
    const reserveCard = screen.getByTestId("envelope-2");
    expect(within(reserveCard).getByText("Reserve")).toBeInTheDocument();
  });

  it("shows the empty state when there are no envelopes", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({ data: { envelopes: [] } }),
    });
    renderScreen(client);
    await waitFor(() =>
      expect(screen.getByText("No envelopes yet")).toBeInTheDocument(),
    );
  });

  it("surfaces an error state with retry", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({ error: { error: { message: "boom" } } }),
    });
    renderScreen(client);
    await waitFor(() =>
      expect(screen.getByText("Couldn't load envelopes")).toBeInTheDocument(),
    );
    expect(screen.getByRole("button", { name: "Retry" })).toBeInTheDocument();
  });

  it("creates an envelope, parsing the allocation to minor units", async () => {
    const created = makeEnvelope({ id: 9, name: "Travel" });
    const client = makeClient({
      GET: vi
        .fn()
        .mockResolvedValueOnce({ data: { envelopes: [] } })
        .mockResolvedValue({ data: { envelopes: [created] } }),
      POST: vi.fn().mockResolvedValue({ data: created }),
    });
    renderScreen(client);

    await waitFor(() =>
      expect(screen.getByText("No envelopes yet")).toBeInTheDocument(),
    );

    fireEvent.click(screen.getAllByRole("button", { name: "New envelope" })[0]);
    fireEvent.change(screen.getByLabelText("Name"), {
      target: { value: "Travel" },
    });
    // "2.000.000" in vi-VN grouping → 2,000,000 minor units (VND, exponent 0).
    fireEvent.change(screen.getByLabelText("Monthly allocation (₫)"), {
      target: { value: "2.000.000" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => expect(client.POST).toHaveBeenCalled());
    const [path, init] = client.POST.mock.calls[0];
    expect(path).toBe("/api/envelopes");
    expect(init.body.name).toBe("Travel");
    expect(init.body.allocation_minor_units).toBe(2_000_000);

    // The list re-reads the cache and shows the new envelope.
    await waitFor(() => expect(screen.getByText("Travel")).toBeInTheDocument());
  });

  it("surfaces the 422 when marking a second Reserve", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({ data: { envelopes: [makeEnvelope()] } }),
      POST: vi.fn().mockResolvedValue({
        error: {
          error: {
            code: "reserve_conflict",
            message: "A Reserve already exists",
          },
        },
      }),
    });
    renderScreen(client);

    await waitFor(() => expect(screen.getByText("Food")).toBeInTheDocument());
    fireEvent.click(screen.getAllByRole("button", { name: "New envelope" })[0]);
    fireEvent.change(screen.getByLabelText("Name"), {
      target: { value: "Backup" },
    });
    fireEvent.click(screen.getByLabelText("Mark as the Reserve"));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() =>
      expect(screen.getByText("A Reserve already exists")).toBeInTheDocument(),
    );
    expect(screen.getByRole("alert")).toHaveTextContent(
      "A Reserve already exists",
    );
  });

  it("deletes an envelope through the confirm dialog", async () => {
    const client = makeClient({
      GET: vi
        .fn()
        .mockResolvedValueOnce({ data: { envelopes: [makeEnvelope()] } })
        .mockResolvedValue({ data: { envelopes: [] } }),
      DELETE: vi.fn().mockResolvedValue({ data: undefined }),
    });
    renderScreen(client);

    await waitFor(() => expect(screen.getByText("Food")).toBeInTheDocument());
    fireEvent.click(screen.getByRole("button", { name: "Delete Food" }));
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));

    await waitFor(() => expect(client.DELETE).toHaveBeenCalled());
    const [path, init] = client.DELETE.mock.calls[0];
    expect(path).toBe("/api/envelopes/{id}");
    expect(init.params.path.id).toBe(1);
  });

  it("starter picker disables existing names and seeds the set", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({
        data: { envelopes: [makeEnvelope({ name: "Food" })] },
      }),
      POST: vi.fn().mockResolvedValue({ data: { envelopes: [] } }),
    });
    renderScreen(client);

    await waitFor(() => expect(screen.getByText("Food")).toBeInTheDocument());
    fireEvent.click(
      screen.getAllByRole("button", { name: "Starter envelopes" })[0],
    );

    // "Food" already exists → its row is disabled; a fresh one is not.
    expect(screen.getByTestId("starter-Food")).toHaveAttribute(
      "aria-disabled",
      "true",
    );
    expect(screen.getByTestId("starter-Transport")).toHaveAttribute(
      "aria-disabled",
      "false",
    );

    fireEvent.click(
      screen.getByRole("button", { name: "Add starter envelopes" }),
    );
    await waitFor(() => expect(client.POST).toHaveBeenCalled());
    expect(client.POST.mock.calls[0][0]).toBe("/api/starter_envelopes");
  });

  it("starter picker marks the designated Reserve only when none exists", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({
        data: { envelopes: [makeEnvelope({ name: "Food" })] },
      }),
    });
    renderScreen(client);
    await waitFor(() => expect(screen.getByText("Food")).toBeInTheDocument());
    fireEvent.click(
      screen.getAllByRole("button", { name: "Starter envelopes" })[0],
    );
    expect(
      within(screen.getByTestId("starter-Savings")).getByText("Reserve"),
    ).toBeInTheDocument();
  });

  it("starter picker hides the Reserve badge when a Reserve already exists", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({
        data: {
          envelopes: [
            makeEnvelope({ id: 3, name: "Cushion", is_reserve: true }),
          ],
        },
      }),
    });
    renderScreen(client);
    await waitFor(() => expect(screen.getByText("Cushion")).toBeInTheDocument());
    fireEvent.click(
      screen.getAllByRole("button", { name: "Starter envelopes" })[0],
    );
    expect(
      within(screen.getByTestId("starter-Savings")).queryByText("Reserve"),
    ).not.toBeInTheDocument();
  });

  it("applies the allocation template to the chosen month", async () => {
    const client = makeClient({
      GET: vi.fn().mockResolvedValue({ data: { envelopes: [makeEnvelope()] } }),
      POST: vi.fn().mockResolvedValue({ data: { envelopes: [makeEnvelope()] } }),
    });
    renderScreen(client);

    await waitFor(() => expect(screen.getByText("Food")).toBeInTheDocument());
    fireEvent.click(
      screen.getAllByRole("button", { name: "Allocation template" })[0],
    );
    fireEvent.click(screen.getByRole("button", { name: "Apply template" }));

    await waitFor(() => expect(client.POST).toHaveBeenCalled());
    const [path, init] = client.POST.mock.calls[0];
    expect(path).toBe("/api/allocation_template");
    expect(init.body.month).toMatch(/^\d{4}-\d{2}$/);
  });
});
