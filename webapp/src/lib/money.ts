import type { MoneyMinorUnits } from "@/api/types";

/**
 * Money display helper (ADR-0015 / ADR-0013).
 *
 * The web client performs NO money arithmetic. This module only:
 *   - formats integer minor units → a display string, and
 *   - parses user input → integer minor units to POST.
 *
 * Every derived figure (fee, remaining, net worth, shortfall, …) comes from the
 * API. Internally we use string manipulation + BigInt — never floats, never
 * `* / parseFloat`. The currency's minor-unit exponent is read from `Intl`.
 */

const DEFAULT_LOCALE = "vi-VN";

const exponentCache = new Map<string, number>();

/** Number of fraction digits for an ISO-4217 currency (VND→0, USD→2, …). */
export function currencyMinorExponent(currency: string): number {
  const cached = exponentCache.get(currency);
  if (cached !== undefined) return cached;
  const digits =
    new Intl.NumberFormat("en-US", {
      style: "currency",
      currency,
    }).resolvedOptions().maximumFractionDigits ?? 2;
  exponentCache.set(currency, digits);
  return digits;
}

/** Integer minor units → exact decimal string (no float). e.g. (12345, 2) → "123.45". */
function minorToDecimalString(amountMinor: number, exponent: number): string {
  if (!Number.isInteger(amountMinor)) {
    throw new Error(`amount_minor must be an integer, got ${amountMinor}`);
  }
  const negative = amountMinor < 0;
  let digits = BigInt(Math.abs(amountMinor)).toString();
  if (exponent === 0) return (negative ? "-" : "") + digits;
  if (digits.length <= exponent) {
    digits = digits.padStart(exponent + 1, "0");
  }
  const cut = digits.length - exponent;
  const decimal = `${digits.slice(0, cut)}.${digits.slice(cut)}`;
  return (negative ? "-" : "") + decimal;
}

/**
 * Format minor units as a localized currency string (default vi-VN → ₫).
 * Money copy is independent of the UI-copy locale (PRD i18n).
 */
export function formatMoney(
  money: MoneyMinorUnits,
  locale: string = DEFAULT_LOCALE,
): string {
  const exponent = currencyMinorExponent(money.currency);
  const decimal = minorToDecimalString(money.amount_minor, exponent);
  const formatter = new Intl.NumberFormat(locale, {
    style: "currency",
    currency: money.currency,
  });
  // Intl.NumberFormat#format accepts a decimal string (arbitrary-precision,
  // spec'd) — using it keeps us off floats entirely.
  return formatter.format(decimal as unknown as number);
}

/** The group + decimal separators a locale uses for plain numbers. */
function separatorsFor(locale: string): { group: string; decimal: string } {
  const parts = new Intl.NumberFormat(locale).formatToParts(11111.1);
  const group = parts.find((p) => p.type === "group")?.value ?? ",";
  const decimal = parts.find((p) => p.type === "decimal")?.value ?? ".";
  return { group, decimal };
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Parse user-entered text → integer minor units (no float). Strips the locale's
 * grouping separators, normalizes the decimal separator, then scales by the
 * currency exponent via string/BigInt math. Throws on non-numeric input.
 */
export function parseMoney(
  input: string,
  currency: string,
  locale: string = DEFAULT_LOCALE,
): number {
  const exponent = currencyMinorExponent(currency);
  const { group, decimal } = separatorsFor(locale);

  let cleaned = input.trim();
  const negative = /^[-(]/.test(cleaned) || /[-)]$/.test(cleaned);
  cleaned = cleaned
    .replace(new RegExp(escapeRegExp(group), "g"), "")
    .replace(new RegExp(escapeRegExp(decimal), "g"), ".")
    .replace(/[^0-9.]/g, "");

  if (cleaned === "" || cleaned === ".") {
    throw new Error(`Cannot parse money from input: "${input}"`);
  }
  if (!/^\d*(\.\d*)?$/.test(cleaned)) {
    throw new Error(`Cannot parse money from input: "${input}"`);
  }

  const [intPart = "", fracPartRaw = ""] = cleaned.split(".");
  // Scale fraction to exactly `exponent` digits (pad / truncate — never round).
  const fracPart = fracPartRaw.slice(0, exponent).padEnd(exponent, "0");
  const digits = `${intPart}${fracPart}`.replace(/^0+(?=\d)/, "");
  const magnitude = BigInt(digits === "" ? "0" : digits);
  const signed = negative ? -magnitude : magnitude;
  return Number(signed);
}

/**
 * Display an exact decimal quantity string as-is (ADR-0015 — quantities are
 * exact decimal strings end to end, never parsed to a float). Optionally append
 * a unit label (chỉ, lượng, shares). Does NO math.
 */
export function formatQuantity(quantity: string, unit?: string): string {
  const value = quantity.trim();
  return unit ? `${value} ${unit}` : value;
}
