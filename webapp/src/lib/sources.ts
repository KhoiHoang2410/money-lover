import type { Source, SourceKind } from "@/api/types";

/*
 * Read-only source presentation helpers (issue 05). No money/quantity math here:
 * grouping and display decisions only — every figure is rendered straight from
 * the API via the foundation formatters (src/lib/money.ts).
 */

/** The base currency all valuations are reported in (CONTEXT.md). */
export const BASE_CURRENCY = "VND";

/** Stable group order for the list: accounts, then credit cards, then holdings. */
export const SOURCE_KIND_ORDER: readonly SourceKind[] = [
  "account",
  "credit_card",
  "holding",
];

/**
 * A source needs the native + base-currency dual display when its own currency
 * differs from the base currency (a foreign-currency Account, or any Holding,
 * which carries a quantity plus a VND valuation). Pure comparison — no math.
 */
export function showsValuation(source: Source): boolean {
  return source.kind === "holding" || source.currency !== BASE_CURRENCY;
}

/** Group sources by kind, preserving SOURCE_KIND_ORDER and dropping empty kinds. */
export function groupSourcesByKind(
  sources: readonly Source[],
): { kind: SourceKind; sources: Source[] }[] {
  return SOURCE_KIND_ORDER.map((kind) => ({
    kind,
    sources: sources.filter((s) => s.kind === kind),
  })).filter((group) => group.sources.length > 0);
}
