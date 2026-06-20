# frozen_string_literal: true

# Derives a Holding's live quantity from its opening quantity and the Invest
# trades that touch it, and guards against overselling. Pure, exact, no Float.
#
# Mirrors the Swift `HoldingQuantityEngine`
# (`ios/MoneyLover/Core/HoldingQuantityEngine.swift`) and the `canSave` oversell
# guard in `TransactionForm.swift`:
#
#   live quantity = opening quantity + Σ Buys − Σ Sells   (ADR-0010)
#
# the `current = opening + Σ transactions` invariant applied to units instead of
# money. A Sell is allowed iff it does not drive the quantity negative.
module HoldingQuantity
  # Raised when a Sell would drive a Holding's quantity below zero.
  class OversellError < StandardError; end

  module_function

  # The signed unit delta an Invest applies to Holding `holding_id`, or nil when
  # the trade doesn't touch it (different kind, different holding, missing data).
  # A Buy adds units, a Sell removes them.
  #
  # @return [Rational, nil]
  def unit_delta(trade, holding_id:)
    return nil unless trade.kind == :invest && trade.destination_id == holding_id
    return nil if trade.direction.nil? || trade.quantity.nil?

    trade.buy? ? trade.quantity : -trade.quantity
  end

  # A Holding's live quantity: its opening quantity plus the net of every Invest
  # trade on it. Trades for other Holdings are ignored.
  #
  # @param opening      [Integer, Rational, BigDecimal, String, Quantity] opening units
  # @param holding_id   the Holding id whose trades count
  # @param transactions [Array<Invest>] the candidate trades
  # @return [Rational] the exact live quantity
  def live_quantity(opening:, holding_id:, transactions: [])
    running = exact(opening)
    transactions.reduce(running) do |acc, trade|
      acc + (unit_delta(trade, holding_id: holding_id) || 0)
    end
  end

  # Whether a Sell of `sell_quantity` is allowed against `live_quantity`:
  # allowed iff sell_quantity <= live_quantity (overselling is blocked).
  def sell_allowed?(live_quantity:, sell_quantity:)
    exact(sell_quantity) <= exact(live_quantity)
  end

  # The resulting quantity after a Sell, raising `OversellError` if the Sell
  # would drive the Holding negative (the blocked case the Swift `Core` forbids).
  #
  # @return [Rational]
  def apply_sell(live_quantity:, sell_quantity:)
    live = exact(live_quantity)
    sell = exact(sell_quantity)
    if sell > live
      raise OversellError, "cannot sell #{sell.to_f} units of a holding with only #{live.to_f} held"
    end

    live - sell
  end

  # Coerces an opening/quantity value to an exact Rational, accepting a Quantity
  # (using its magnitude) and rejecting Float via `Quantity.exact`.
  def exact(value)
    return value.value if value.is_a?(Quantity)

    Quantity.exact(value)
  end
end
