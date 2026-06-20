# frozen_string_literal: true

# A single Invest trade: a Buy or Sell that moves units between a VND Account
# (`source_id`) and a Holding (`destination_id`). The `quantity` is the exact
# number of units transacted (a decimal magnitude, not money, not Float).
#
# Mirrors the Invest-shaped fields of the Swift `Transaction`
# (`ios/MoneyLover/Core/Transaction.swift`) that `HoldingQuantityEngine` reads:
# `kind`, `tradeDirection`, `tradeQuantity`, `destinationID`. Glossary keeps the
# entity a "Holding/Invest" — never a "Trade" — so this models the *event*.
class Invest
  # The transaction kind (always :invest for an Invest event).
  attr_reader :kind
  # :buy adds units to the Holding; :sell removes them.
  attr_reader :direction
  # The exact units transacted, as a Rational.
  attr_reader :quantity
  # The Account the money moves to/from.
  attr_reader :source_id
  # The Holding whose quantity this trade changes.
  attr_reader :destination_id

  # @param direction      [Symbol, String] :buy or :sell
  # @param quantity       [Integer, Rational, BigDecimal, String] exact units (no Float)
  # @param destination_id the Holding id this trade touches
  # @param source_id      the Account id (optional for quantity math)
  # @param kind           [Symbol, String] transaction kind, defaults to :invest
  def initialize(direction:, quantity:, destination_id:, source_id: nil, kind: :invest)
    @kind = kind.to_s.to_sym
    @direction = direction.to_s.to_sym
    @quantity = Quantity.exact(quantity)
    @destination_id = destination_id
    @source_id = source_id
    freeze
  end

  def buy?
    direction == :buy
  end

  def sell?
    direction == :sell
  end
end
