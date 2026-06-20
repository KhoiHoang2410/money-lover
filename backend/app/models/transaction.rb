# A Transaction owned by a User (CONTEXT.md): an Expense, Income, Transfer,
# Invest or Adjustment. Tenant-scoped via Tenanted — only ever loaded through
# `current_user.transactions`, so another user's row is unreachable (ADR-0014).
#
# This is the persistence edge: it stores money as integer minor units + a
# currency code and exposes the domain value objects the pure engines consume —
# `BalanceEngine::Transaction` for ledger deltas, `Invest` for the
# `HoldingQuantity` oversell guard. Float never crosses the boundary (ADR-0015).
class Transaction < ApplicationRecord
  include Tenanted

  EXPENSE = "expense".freeze
  INCOME = "income".freeze
  TRANSFER = "transfer".freeze
  INVEST = "invest".freeze
  ADJUSTMENT = "adjustment".freeze
  KINDS = [ EXPENSE, INCOME, TRANSFER, INVEST, ADJUSTMENT ].freeze

  BUY = "buy".freeze
  SELL = "sell".freeze
  DIRECTIONS = [ BUY, SELL ].freeze

  belongs_to :source, class_name: "Source"
  belongs_to :destination, class_name: "Source", optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :currency, presence: true

  # The transaction amount as a `Money` in the source currency (a signed
  # reconcile delta for an Adjustment).
  def amount
    MoneyMapping.load(minor_units: amount_minor_units, currency: currency)
  end

  # The amount that lands in the destination of a cross-currency Transfer, as a
  # `Money` in the destination currency — or nil for a same-currency move.
  def destination_amount
    return nil if destination_amount_minor_units.nil?

    MoneyMapping.load(minor_units: destination_amount_minor_units, currency: destination_currency)
  end

  # The computed Fee of a cross-currency Transfer (TransferFxMath), as a `Money`
  # in the destination currency — or nil otherwise.
  def fee
    return nil if fee_minor_units.nil?

    MoneyMapping.load(minor_units: fee_minor_units, currency: destination_currency)
  end

  def cross_currency?
    kind == TRANSFER && destination_currency.present? && destination_currency != currency
  end

  # The signed `BalanceEngine::Transaction` value object this row maps to — the
  # single derivation of its ledger deltas (its per-source effects come from
  # BalanceEngine, ADR-0007/issue 07).
  def to_balance_txn
    BalanceEngine::Transaction.build(
      kind: kind,
      amount: amount,
      source_id: source_id,
      destination_id: destination_id,
      destination_amount: destination_amount,
      direction: trade_direction
    )
  end

  # The `Invest` value object for the HoldingQuantity engine (oversell guard +
  # live quantity), or nil when this is not an Invest trade.
  def to_invest
    return nil unless kind == INVEST && trade_direction.present? && trade_quantity.present?

    Invest.new(
      direction: trade_direction,
      quantity: trade_quantity,
      destination_id: destination_id,
      source_id: source_id
    )
  end
end
