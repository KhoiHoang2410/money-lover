import { useQuery } from "@tanstack/react-query";
import { Link, useParams } from "react-router";
import { useTranslation } from "react-i18next";
import { ArrowLeft } from "lucide-react";
import type { Client } from "openapi-fetch";
import type { paths, Source } from "@/api/types";
import { apiClient } from "@/api/client";
import { formatMoney, formatQuantity } from "@/lib/money";
import { showsValuation } from "@/lib/sources";

interface SourceDetailScreenProps {
  /** Injectable for tests; defaults to the real typed client. */
  client?: Client<paths>;
}

interface FieldRowProps {
  label: string;
  value: string;
}

function FieldRow({ label, value }: FieldRowProps) {
  return (
    <div className="flex items-baseline justify-between gap-4 border-b border-border py-3 last:border-b-0">
      <dt className="text-sm text-muted-foreground">{label}</dt>
      <dd className="text-right font-medium tabular-nums">{value}</dd>
    </div>
  );
}

/*
 * Source detail (issue 05, read-only): reads GET /api/sources/:id through the
 * typed client and renders a single source's fields and current balance /
 * valuation. Money and quantities are rendered through the foundation
 * formatters; no arithmetic happens here.
 */
export function SourceDetailScreen({
  client = apiClient,
}: SourceDetailScreenProps) {
  const { t } = useTranslation();
  const { id } = useParams<{ id: string }>();
  const sourceId = Number(id);

  const { data, isPending, isError } = useQuery({
    queryKey: ["source", sourceId],
    queryFn: async () => {
      const { data, error } = await client.GET("/api/sources/{id}", {
        params: { path: { id: sourceId } },
      });
      if (error) throw new Error("source request failed");
      return data;
    },
    retry: false,
  });

  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6">
      <Link
        to="/sources"
        className="inline-flex items-center gap-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        {t("sources.back")}
      </Link>

      {isPending && (
        <p className="rounded-lg bg-card p-5 text-sm text-muted-foreground">
          {t("sources.loading")}
        </p>
      )}

      {isError && (
        <p className="rounded-lg bg-card p-5 text-sm text-destructive">
          {t("sources.detailError")}
        </p>
      )}

      {data && <SourceDetailCard source={data} />}
    </div>
  );
}

function SourceDetailCard({ source }: { source: Source }) {
  const { t } = useTranslation();
  const isHolding = source.kind === "holding";
  const showValuation = showsValuation(source);

  return (
    <section className="rounded-lg bg-card p-7">
      <header className="mb-4">
        <h1 className="text-2xl font-bold">{source.name}</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {t(`sources.kind.${source.kind}`)}
        </p>
      </header>

      <dl>
        <FieldRow
          label={t("sources.kindLabel")}
          value={t(`sources.kind.${source.kind}`)}
        />
        <FieldRow label={t("sources.currencyLabel")} value={source.currency} />

        {isHolding && source.holding && (
          <FieldRow
            label={t("sources.quantityLabel")}
            value={formatQuantity(
              source.holding.opening_quantity,
              t(`sources.unit.${source.holding.unit}`),
            )}
          />
        )}

        {isHolding && source.holding?.ticker && (
          <FieldRow
            label={t("sources.tickerLabel")}
            value={source.holding.ticker}
          />
        )}

        {source.opening_balance && (
          <FieldRow
            label={t("sources.openingBalanceLabel")}
            value={formatMoney(source.opening_balance)}
          />
        )}

        {!isHolding && (
          <FieldRow
            label={t("sources.currentBalanceLabel")}
            value={formatMoney(source.current_balance)}
          />
        )}

        {showValuation && (
          <FieldRow
            label={t("sources.valuationLabel")}
            value={formatMoney(source.valuation)}
          />
        )}
      </dl>
    </section>
  );
}
