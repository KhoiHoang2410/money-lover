# frozen_string_literal: true

# Values a single source in the base currency (VND), given its current balance
# and a resolved `Rates` snapshot. Pure — no network, no DB, no Float.
#
# Mirrors the Swift `Valuator` in `ios/MoneyLover/Core/Valuator.swift`:
#   - Account / credit card: balance × FX rate (major units × VND-per-major-unit).
#   - Gold Holding: quantity-in-chỉ × gold price per chỉ (1 lượng = 10 chỉ).
#   - Stock Holding: quantity × that ticker's share price.
#
# A missing FX rate, an unknown ticker, or a zero price degrades the value to ₫0
# — the Valuator never raises on missing market data (parity with the golden
# `valuation.json` fixture and ADR-0015).
module Valuator
  module_function

  # @param kind     [Symbol, String] :account, :credit_card, or :holding
  # @param currency [Symbol, String] the source's native currency
  # @param balance  [Money] the source's current balance (₫0 for a Holding)
  # @param rates    [Rates] resolved conversion rates
  # @param holding  [Holding, nil] the Holding facts (required when kind is :holding)
  # @return [Money] the value in VND
  def value_in_vnd(kind:, currency:, balance:, rates:, holding: nil)
    case normalize_kind(kind)
    when :account, :credit_card
      Money.from_major(balance.amount * rates.fx_rate(currency), :VND)
    when :holding
      value_holding(holding, rates)
    else
      Money.zero(:VND)
    end
  end

  # The value of a Holding in VND, or ₫0 when its facts/price are missing.
  def value_holding(holding, rates)
    return Money.zero(:VND) if holding.nil?

    if holding.gold?
      Money.from_major(holding.quantity.in_chi * rates.gold_per_chi, :VND)
    else
      Money.from_major(holding.quantity.value * rates.stock_price(holding.ticker), :VND)
    end
  end

  def normalize_kind(kind)
    kind.to_s.downcase.to_sym
  end
end
