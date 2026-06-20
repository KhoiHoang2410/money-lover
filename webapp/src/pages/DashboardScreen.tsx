import { useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import type { Client } from "openapi-fetch";
import type { components, paths } from "@/api/types";
import { apiClient } from "@/api/client";
import { formatMoney } from "@/lib/money";
import { cn } from "@/lib/utils";

type NetWorth = components["schemas"]["NetWorth"];
type SignalList = components["schemas"]["SignalList"];
type Signal = components["schemas"]["Signal"];

interface DashboardScreenProps {
  /** Injectable for tests; defaults to the real typed client. */
  client?: Client<paths>;
}

/*
 * The authenticated landing screen (webapp issue #110): the User's net worth and
 * their Signals, read-only, in the lime-dark style (ADR-0018 accent-inversion —
 * the net total is the off-white hero, the surrounding cards stay dark).
 *
 * Every figure comes from the API: net worth from GET /api/net_worth, signals
 * from GET /signals. The browser performs NO money math — amounts are integer
 * minor units formatted via formatMoney, and signal text is deterministic
 * server phrasing rendered verbatim (ADR-0004 paused; never computed here).
 */
export function DashboardScreen({ client = apiClient }: DashboardScreenProps) {
  return (
    <div className="flex flex-col gap-6">
      <NetWorthSection client={client} />
      <SignalsSection client={client} />
    </div>
  );
}

function NetWorthSection({ client }: { client: Client<paths> }) {
  const { t } = useTranslation();

  const { data, isPending, isError } = useQuery({
    queryKey: ["net_worth"],
    queryFn: async () => {
      const { data, error } = await client.GET("/api/net_worth");
      if (error) throw new Error("net_worth request failed");
      return data;
    },
    retry: false,
  });

  if (isPending) {
    return (
      <SectionShell>
        <p className="text-sm text-muted-foreground">
          {t("dashboard.netWorth.loading")}
        </p>
      </SectionShell>
    );
  }

  if (isError || !data) {
    return (
      <SectionShell>
        <p className="text-sm text-destructive">
          {t("dashboard.netWorth.error")}
        </p>
      </SectionShell>
    );
  }

  const netWorth: NetWorth = data;

  return (
    <section className="flex flex-col gap-4">
      {/* Hero (accent-inversion): the net total on the off-white card. */}
      <div className="rounded-lg bg-hero p-7 text-hero-foreground">
        <span className="text-sm font-medium opacity-70">
          {t("dashboard.netWorth.net")}
        </span>
        <p className="mt-1 text-4xl font-bold tabular-nums">
          {formatMoney(netWorth.net)}
        </p>
      </div>

      {/* Surrounding cards stay dark. */}
      <div className="grid gap-4 sm:grid-cols-2">
        <FigureCard
          label={t("dashboard.netWorth.asset")}
          value={formatMoney(netWorth.asset)}
        />
        <FigureCard
          label={t("dashboard.netWorth.debt")}
          value={formatMoney(netWorth.debt)}
        />
      </div>
    </section>
  );
}

function FigureCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg bg-card p-6">
      <span className="text-sm text-muted-foreground">{label}</span>
      <p className="mt-1 text-2xl font-bold tabular-nums">{value}</p>
    </div>
  );
}

function SignalsSection({ client }: { client: Client<paths> }) {
  const { t } = useTranslation();

  const { data, isPending, isError } = useQuery({
    queryKey: ["signals"],
    queryFn: async () => {
      const { data, error } = await client.GET("/signals");
      if (error) throw new Error("signals request failed");
      return data;
    },
    retry: false,
  });

  const signals: Signal[] = (data as SignalList | undefined)?.signals ?? [];

  const content = renderSignalsContent({ isPending, isError, signals, t });

  return (
    <SectionShell>
      <h2 className="text-lg font-bold">{t("dashboard.signals.title")}</h2>
      <p className="mt-1 text-sm text-muted-foreground">
        {t("dashboard.signals.subtitle")}
      </p>

      <div className="mt-5">{content}</div>
    </SectionShell>
  );
}

function renderSignalsContent({
  isPending,
  isError,
  signals,
  t,
}: {
  isPending: boolean;
  isError: boolean;
  signals: Signal[];
  t: (key: string) => string;
}) {
  if (isPending) {
    return (
      <p className="text-sm text-muted-foreground">
        {t("dashboard.signals.loading")}
      </p>
    );
  }
  if (isError) {
    return (
      <p className="text-sm text-destructive">
        {t("dashboard.signals.error")}
      </p>
    );
  }
  if (signals.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">
        {t("dashboard.signals.empty")}
      </p>
    );
  }
  return (
    <ul className="flex flex-col gap-3">
      {signals.map((signal) => (
        <SignalRow key={signal.id} signal={signal} />
      ))}
    </ul>
  );
}

// Severity → accent tone. Display only; the API decides what fired and how it
// reads — we never recompute or reclassify in the browser.
const SEVERITY_TONE: Record<Signal["severity"], string> = {
  info: "bg-primary",
  warning: "bg-primary",
  critical: "bg-destructive",
};

function SignalRow({ signal }: { signal: Signal }) {
  return (
    <li className="flex gap-3 rounded-lg bg-secondary p-4">
      <span
        className={cn(
          "mt-1.5 h-2 w-2 shrink-0 rounded-full",
          SEVERITY_TONE[signal.severity],
        )}
        aria-hidden
      />
      <div className="flex flex-col gap-1">
        <span className="text-sm font-semibold text-foreground">
          {signal.title}
        </span>
        <span className="text-sm text-muted-foreground">{signal.detail}</span>
      </div>
    </li>
  );
}

function SectionShell({ children }: { children: React.ReactNode }) {
  return <section className="rounded-lg bg-card p-7">{children}</section>;
}
