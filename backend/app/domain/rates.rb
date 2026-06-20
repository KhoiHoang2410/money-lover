# frozen_string_literal: true

# A snapshot of the conversion rates needed to value any source in the base
# currency (VND): FX rates for foreign Accounts, the SJC gold price per chỉ, and
# HOSE stock prices per share by ticker.
#
# Mirrors the Swift `Rates` struct in `ios/MoneyLover/Core/Rates.swift`. The
# numbers are exact (Integer/Rational/BigDecimal/numeric String) — never Float,
# so they can flow into `Money` math without losing precision (ADR-0015).
#
# This is the "resolved-rate provider" the Valuator depends on: per-user override
# vs global resolution happens upstream (issue 19), keeping this value object and
# the Valuator pure.
class Rates
  # VND per 1 major unit of each currency, keyed by currency Symbol.
  attr_reader :fx
  # VND per chỉ of SJC gold.
  attr_reader :gold_per_chi
  # VND per share, keyed by ticker String.
  attr_reader :stock

  # @param fx           [Hash] currency (any case Symbol/String) => exact rate
  # @param gold_per_chi [Integer, Rational, BigDecimal, String] VND per chỉ
  # @param stock        [Hash] ticker String => exact VND-per-share rate
  def initialize(fx: {}, gold_per_chi: 0, stock: {})
    @fx = fx.each_with_object({}) do |(code, rate), acc|
      acc[Currency.normalize(code)] = rate
    end.freeze
    @gold_per_chi = gold_per_chi
    @stock = stock.transform_keys(&:to_s).freeze
    freeze
  end

  # An empty rate table: VND is its own unit, everything else degrades to 0.
  def self.empty
    new(fx: { VND: 1 }, gold_per_chi: 0, stock: {})
  end

  # VND per 1 major unit of `currency`. Always 1 for VND; a missing foreign rate
  # degrades to 0 so the Valuator yields ₫0 rather than crashing.
  def fx_rate(currency)
    code = Currency.normalize(currency)
    return 1 if code == :VND

    fx[code] || 0
  end

  # VND per share for `ticker`, or 0 for an unknown ticker.
  def stock_price(ticker)
    stock[ticker.to_s] || 0
  end
end
