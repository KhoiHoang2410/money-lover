# frozen_string_literal: true

# The valuation-relevant facts about a Holding: its exact `Quantity` plus an
# optional stock `ticker`. Gold Holdings carry no ticker and price off the gold
# rate; stock Holdings carry a ticker and price off that ticker's share price.
#
# Mirrors the Swift `HoldingInfo` in `ios/MoneyLover/Core/HoldingInfo.swift`.
# The quantity is a `Quantity` (exact decimal, ADR-0010/0015) — never money,
# never a Float.
class Holding
  # The holding's `Quantity` (value + unit).
  attr_reader :quantity
  # The HOSE ticker String for a stock Holding, or nil for gold.
  attr_reader :ticker

  # @param quantity [Quantity] exact units held
  # @param ticker   [String, nil] stock ticker; nil/empty means a gold Holding
  def initialize(quantity:, ticker: nil)
    @quantity = quantity
    @ticker = ticker.nil? || ticker.to_s.empty? ? nil : ticker.to_s
    freeze
  end

  # True when this Holding is a gold Holding (priced per chỉ), not a stock.
  def gold?
    ticker.nil?
  end
end
