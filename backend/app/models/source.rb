# A money source owned by a User (CONTEXT.md): an Account or Credit card (a money
# balance) or a Holding (valued by quantity × market price). Tenant-scoped via
# Tenanted — only ever loaded through `current_user.sources`, so another user's
# source is unreachable, not merely hidden (ADR-0014).
#
# This is the persistence edge: it stores money as integer minor units + a
# currency code and exposes the domain `Money`/`Quantity`/`Holding` value objects
# the pure engines (BalanceEngine, Valuator) consume — Float never crosses the
# boundary (ADR-0015).
class Source < ApplicationRecord
  include Tenanted

  ACCOUNT = "account".freeze
  CREDIT_CARD = "credit_card".freeze
  HOLDING = "holding".freeze
  KINDS = [ ACCOUNT, CREDIT_CARD, HOLDING ].freeze

  # The base currency every total is expressed in (CONTEXT.md). A Holding has no
  # held currency of its own, so it persists VND.
  BASE_CURRENCY = "VND".freeze

  validates :kind, inclusion: { in: KINDS }
  validates :name, presence: true
  validates :currency, presence: true

  # True for the money-balance sources (Account, Credit card); false for a
  # Holding, which has no opening money balance.
  def account_like?
    kind == ACCOUNT || kind == CREDIT_CARD
  end

  def holding?
    kind == HOLDING
  end

  # The opening money balance as a `Money`, or nil for a Holding.
  def opening_balance
    return nil unless account_like?

    MoneyMapping.load(minor_units: opening_minor_units || 0, currency: currency)
  end

  # The opening `Quantity` of a Holding, or nil for a money source.
  def opening_quantity_value
    return nil unless holding?

    Quantity.new(opening_quantity, unit: holding_unit)
  end

  # The valuation-relevant `Holding` facts (quantity + ticker), or nil otherwise.
  def holding_facts
    return nil unless holding?

    Holding.new(quantity: opening_quantity_value, ticker: ticker)
  end

  # Whether any transaction references this source — the delete-integrity guard
  # (issue 13). The Transactions ledger arrives in issue 14; until then nothing
  # can reference a source, so this is false and deletes are unblocked.
  def referenced_by_transactions?
    false
  end
end
