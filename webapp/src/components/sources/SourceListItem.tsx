import { Link } from "react-router";
import { useTranslation } from "react-i18next";
import type { Source } from "@/api/types";
import { formatMoney, formatQuantity } from "@/lib/money";
import { showsValuation } from "@/lib/sources";

interface SourceListItemProps {
  source: Source;
}

/*
 * One row in the sources list (issue 05, read-only). Presentation only — every
 * figure comes straight from the API and is rendered through the foundation
 * formatters; this component does NO money or quantity arithmetic.
 *
 * Holdings lead with the exact quantity string (chỉ / lượng / shares) and show
 * the VND valuation beneath. Foreign-currency Accounts/Credit cards lead with
 * the native current balance and show the VND valuation beneath. VND money
 * sources show a single figure (native already is the base currency).
 */
export function SourceListItem({ source }: SourceListItemProps) {
  const { t } = useTranslation();
  const isHolding = source.kind === "holding";

  const primary = isHolding
    ? formatQuantity(
        source.holding?.opening_quantity ?? "0",
        source.holding ? t(`sources.unit.${source.holding.unit}`) : undefined,
      )
    : formatMoney(source.current_balance);

  const showValuation = showsValuation(source);

  return (
    <Link
      to={`/sources/${source.id}`}
      className="flex items-center justify-between gap-4 rounded-lg bg-card p-5 transition-colors hover:bg-accent"
    >
      <div className="min-w-0">
        <p className="truncate font-semibold">{source.name}</p>
        {isHolding && source.holding?.ticker ? (
          <p className="mt-0.5 text-xs text-muted-foreground">
            {source.holding.ticker}
          </p>
        ) : (
          <p className="mt-0.5 text-xs text-muted-foreground">
            {source.currency}
          </p>
        )}
      </div>

      <div className="shrink-0 text-right">
        <p className="font-bold tabular-nums">{primary}</p>
        {showValuation && (
          <p className="mt-0.5 text-xs text-muted-foreground tabular-nums">
            {formatMoney(source.valuation)}
          </p>
        )}
      </div>
    </Link>
  );
}
