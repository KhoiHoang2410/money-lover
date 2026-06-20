import { useQuery } from "@tanstack/react-query";
import { useTranslation } from "react-i18next";
import type { Client } from "openapi-fetch";
import type { paths, MoneyMinorUnits } from "@/api/types";
import { apiClient, API_BASE_URL } from "@/api/client";
import { formatMoney } from "@/lib/money";
import { LanguageSwitcher } from "@/components/LanguageSwitcher";
import { cn } from "@/lib/utils";

// A fixed sample to prove ₫ formatting from integer minor units (no math).
const SAMPLE_BALANCE: MoneyMinorUnits = {
  amount_minor: 125_000_000,
  currency: "VND",
};

interface HealthScreenProps {
  /** Injectable for tests; defaults to the real typed client. */
  client?: Client<paths>;
}

/*
 * Proof screen (issue #108): reads a LIVE endpoint (`GET /health`) through the
 * typed openapi-fetch client and renders the result. The response is typed as
 * HealthStatus — referencing a field the contract doesn't define would be a
 * compile error, which is the whole point of the rig. No feature logic here.
 */
export function HealthScreen({ client = apiClient }: HealthScreenProps) {
  const { t } = useTranslation();

  const { data, isPending, isError } = useQuery({
    queryKey: ["health"],
    queryFn: async () => {
      const { data, error } = await client.GET("/health");
      if (error) throw new Error("health request failed");
      return data;
    },
    retry: false,
  });

  const statusText = isPending
    ? t("health.checking")
    : isError
      ? t("health.error")
      : data?.status === "ok"
        ? t("health.ok")
        : t("health.error");

  const statusTone = isPending
    ? "text-muted-foreground"
    : !isError && data?.status === "ok"
      ? "text-primary"
      : "text-destructive";

  const endpoint = `${API_BASE_URL}/health`;

  return (
    <main className="mx-auto flex min-h-dvh max-w-2xl flex-col gap-6 px-5 py-12">
      <header className="flex items-center justify-between gap-4">
        <span className="text-sm font-semibold tracking-tight text-muted-foreground">
          {t("common.appName")}
        </span>
        <LanguageSwitcher />
      </header>

      <section className="rounded-lg bg-card p-7">
        <h1 className="text-2xl font-bold">{t("health.title")}</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          {t("health.subtitle")}
        </p>

        <dl className="mt-6 flex items-baseline justify-between">
          <dt className="text-sm text-muted-foreground">
            {t("health.statusLabel")}
          </dt>
          <dd className={cn("text-lg font-bold", statusTone)}>{statusText}</dd>
        </dl>

        <dl className="mt-3 flex items-baseline justify-between">
          <dt className="text-sm text-muted-foreground">
            {t("health.endpointLabel")}
          </dt>
          <dd className="text-sm text-foreground">{endpoint}</dd>
        </dl>
      </section>

      <section className="rounded-lg bg-hero p-7 text-hero-foreground">
        <span className="text-sm font-medium opacity-70">
          {t("health.sampleBalanceLabel")}
        </span>
        <p className="mt-1 text-4xl font-bold tabular-nums">
          {formatMoney(SAMPLE_BALANCE)}
        </p>
        <p className="mt-2 text-xs opacity-70">
          {t("health.sampleBalanceNote")}
        </p>
      </section>
    </main>
  );
}
