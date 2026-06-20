# frozen_string_literal: true

# The single authority for a money source's **current balance**:
#
#     current balance = opening balance + Σ (signed balance-affecting transactions)
#
# (CONTEXT.md "Current balance"). A pure Ruby module — no Rails, no DB — that
# operates entirely in integer minor units via the `Money` value type (issue 04),
# so Float never enters balance math (ADR-0015). Persistence and the atomic write
# path live in the Sources/Transactions APIs (issues 13/14); this engine only
# computes.
#
# It is the parity oracle's Ruby side for `golden/fixtures/balances.json`
# (issue 03 / ADR-0015): every case there must reproduce byte-identically.
#
# Two entry points mirror the Swift `Core` shape:
#   - `current(opening:, deltas:)` — opening plus a list of already-signed `Money`
#     deltas, raising on a currency mismatch.
#   - `balance(source:, transactions:)` — derives each transaction's signed delta
#     for `source` from its kind, then folds it onto the opening balance.
module BalanceEngine
  # A money source whose balance we track: an Account or a Liability (a Credit
  # card). A Holding is *not* a money source here — it anchors on quantity, not a
  # money balance (CONTEXT.md "Opening balance" / "Holding").
  #
  # `opening_balance` is the `Money` anchor for all balance math. For a Credit
  # card the balance is a Liability, carried as a non-positive `Money` (debt is
  # negative), so the same "opening + Σ deltas" invariant applies uniformly.
  Source = Data.define(:id, :kind, :currency, :opening_balance) do
    def self.build(id:, kind:, currency:, opening_balance:)
      new(
        id: id,
        kind: kind.to_sym,
        currency: Currency.normalize(currency),
        opening_balance: opening_balance
      )
    end
  end

  # A balance-affecting transaction. `amount` is always a non-negative magnitude
  # in the relevant source's currency; the *sign* is derived from `kind` and the
  # source's side, never stored on the amount (except `adjustment`, whose amount
  # is the signed reconcile delta).
  #
  #   - `source_id`        — the source the money primarily leaves/affects.
  #   - `destination_id`   — the receiving source, for a Transfer / Invest leg.
  #   - `destination_amount` — the amount that *arrives* at the destination for a
  #     cross-currency Transfer (the destination side credits this, not the
  #     source-currency `amount`; CONTEXT.md "Transfer"). Falls back to `amount`
  #     for a same-currency move.
  #   - `direction`        — `:buy` / `:sell` for an Invest money leg.
  Transaction = Data.define(
    :kind, :amount, :source_id, :destination_id, :destination_amount, :direction
  ) do
    def self.build(kind:, amount:, source_id: nil, destination_id: nil,
                   destination_amount: nil, direction: nil)
      new(
        kind: kind.to_sym,
        amount: amount,
        source_id: source_id,
        destination_id: destination_id,
        destination_amount: destination_amount,
        direction: direction&.to_sym
      )
    end
  end

  module_function

  # opening + Σ deltas, all in `opening`'s currency. Each delta is an
  # already-signed `Money`; a mismatched-currency delta raises
  # `MoneyError::CurrencyMismatch` rather than silently coercing.
  #
  # @param opening [Money]
  # @param deltas  [Array<Money>]
  # @return [Money]
  def current(opening:, deltas:)
    Money.sum([ opening, *deltas ], currency: opening.currency)
  end

  # Current balance of `source` given the full transaction list. Transactions
  # that do not touch `source` contribute nothing; the rest are reduced to a
  # signed `Money` delta in `source`'s currency by `delta_for`.
  #
  # @param source       [BalanceEngine::Source]
  # @param transactions [Array<BalanceEngine::Transaction>]
  # @return [Money]
  def balance(source:, transactions:)
    deltas = transactions.filter_map { |txn| delta_for(source, txn) }
    current(opening: source.opening_balance, deltas: deltas)
  end

  # The signed `Money` effect of `txn` on `source`, or `nil` if `txn` does not
  # affect this source. Encodes each kind's balance rule (issue 07 scope):
  #
  #   - Expense:    source ↓ (an Account/debit reduces; a Credit card's debt
  #     grows, i.e. its non-positive balance moves further negative — same `-amount`).
  #   - Income:     source ↑.
  #   - Transfer:   source side ↓ by `amount`; destination side ↑ by the amount
  #     that arrives (`destination_amount`, the cross-currency-correct figure).
  #   - Invest:     the Account money leg — a Buy pays out (↓), a Sell receives (↑).
  #   - Adjustment: applies the signed reconcile delta directly.
  def delta_for(source, txn)
    case txn.kind
    when :expense
      txn.amount.negate if txn.source_id == source.id
    when :income
      txn.amount if txn.source_id == source.id
    when :transfer
      if txn.source_id == source.id
        txn.amount.negate
      elsif txn.destination_id == source.id
        txn.destination_amount || txn.amount
      end
    when :invest
      invest_leg(source, txn)
    when :adjustment
      txn.amount if txn.source_id == source.id
    else
      raise ArgumentError, "unknown transaction kind: #{txn.kind.inspect}"
    end
  end

  # The Account-side money movement of an Invest: a Buy debits the Account
  # (pays quantity × accepted price), a Sell credits it. The Holding's quantity
  # leg is the Valuator/HoldingQuantity engine's concern (issue 08), not here.
  def invest_leg(source, txn)
    return unless txn.source_id == source.id

    case txn.direction
    when :buy  then txn.amount.negate
    when :sell then txn.amount
    else
      raise ArgumentError, "invest transaction needs direction :buy or :sell, got #{txn.direction.inspect}"
    end
  end
end
