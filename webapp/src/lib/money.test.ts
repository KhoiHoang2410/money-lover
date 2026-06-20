import { describe, it, expect } from "vitest";
import {
  formatMoney,
  parseMoney,
  formatQuantity,
  currencyMinorExponent,
} from "./money";

describe("currencyMinorExponent", () => {
  it("knows VND has no minor digits and USD has two", () => {
    expect(currencyMinorExponent("VND")).toBe(0);
    expect(currencyMinorExponent("USD")).toBe(2);
  });
});

describe("formatMoney", () => {
  it("formats VND minor units with ₫ and vi-VN grouping, no decimals", () => {
    const out = formatMoney({ amount_minor: 125_000_000, currency: "VND" });
    expect(out).toContain("125.000.000");
    expect(out).toContain("₫");
    expect(out).not.toContain(",");
  });

  it("formats USD minor units with two decimals (en-US)", () => {
    expect(formatMoney({ amount_minor: 12_345, currency: "USD" }, "en-US")).toBe(
      "$123.45",
    );
  });

  it("formats negative amounts", () => {
    expect(formatMoney({ amount_minor: -5_000, currency: "USD" }, "en-US")).toBe(
      "-$50.00",
    );
  });

  it("formats small sub-unit amounts with leading zero", () => {
    expect(formatMoney({ amount_minor: 7, currency: "USD" }, "en-US")).toBe(
      "$0.07",
    );
  });
});

describe("parseMoney", () => {
  it("parses vi-VN grouped VND text to minor units", () => {
    expect(parseMoney("1.234.567", "VND")).toBe(1_234_567);
  });

  it("parses en-US grouped USD text to minor units", () => {
    expect(parseMoney("1,234.56", "USD", "en-US")).toBe(123_456);
  });

  it("scales integer USD input by the currency exponent", () => {
    expect(parseMoney("100", "USD", "en-US")).toBe(10_000);
  });

  it("parses sub-unit fractions exactly (no float drift)", () => {
    // 0.07 * 100 in float is 7.000000000000001 — string math gives exactly 7.
    expect(parseMoney("0.07", "USD", "en-US")).toBe(7);
    expect(parseMoney("0.10", "USD", "en-US")).toBe(10);
  });

  it("truncates extra fraction digits rather than rounding", () => {
    expect(parseMoney("1.239", "USD", "en-US")).toBe(123);
  });

  it("throws on non-numeric input", () => {
    expect(() => parseMoney("abc", "USD", "en-US")).toThrow();
    expect(() => parseMoney("", "USD", "en-US")).toThrow();
  });
});

describe("formatQuantity", () => {
  it("passes the exact decimal string through, with an optional unit", () => {
    expect(formatQuantity("3.5", "chỉ")).toBe("3.5 chỉ");
    expect(formatQuantity("0.0001")).toBe("0.0001");
  });
});

describe("no float math", () => {
  it("round-trips a large VND value without precision loss", () => {
    const minor = 9_007_199_254_000; // < MAX_SAFE_INTEGER, would lose precision under naive float scaling
    const formatted = formatMoney({ amount_minor: minor, currency: "VND" });
    expect(formatted).toContain("9.007.199.254.000");
    expect(parseMoney("9.007.199.254.000", "VND")).toBe(minor);
  });
});
