# frozen_string_literal: true

# Pure Reconcile engine (issue 12, ADR-0015 / CONTEXT.md "Reconcile").
#
# Reconcile is the mode where the owner re-enters each source's **real balance**;
# any drift from the source's **Current balance** (computed by `BalanceEngine`,
# issue 07) becomes an **Adjustment** transaction that absorbs the difference
# (CONTEXT.md "Adjustment"). This module derives those Adjustments — nothing
# more. It is a pure Ruby module: no Rails, no DB, no clock, so it is the Ruby
# side of the parity oracle for `golden/fixtures/reconcile.json`.
#
# Money correctness: the drift is `real_balance − computed`, computed entirely in
# integer minor units via `Money` (Float never enters — ADR-0015). The amount is
# *signed* (positive when reality is higher, negative when lower) so applying it
# through `BalanceEngine` brings the Current balance exactly to reality. A real
# balance whose currency differs from the source's is rejected with
# `MoneyError::CurrencyMismatch` rather than silently coerced.
#
# Persistence is out of scope: the Reconciliation action endpoint (issue 17)
# wraps this, writing the Adjustment transactions atomically.
module ReconcileService
  # The drift-absorbing Adjustment for one source. `amount` is the signed
  # `Money` delta; `kind` is always `:adjustment` (so it folds through
  # `BalanceEngine#delta_for` as a direct signed delta). Carries the optional
  # `note` (description) and `envelope_id` (Envelope assignment) the owner adds
  # during Reconcile (CONTEXT.md "Adjustment").
  Adjustment = Data.define(:source_id, :amount, :envelope_id, :note) do
    def kind = :adjustment
  end

  # The result of reconciling several sources at once: one `Adjustment` per
  # source whose reality drifted, plus the ids of the sources that were already
  # on the money (no adjustment needed).
  Result = Data.define(:adjustments, :unchanged_sources)

  module_function

  # The Adjustment that brings `source`'s Current balance to `real_balance`, or
  # `nil` when they already agree (an equal balance needs no Adjustment).
  #
  # @param source       [BalanceEngine::Source]
  # @param transactions [Array<BalanceEngine::Transaction>] the source's ledger
  # @param real_balance [Money] the balance the owner re-entered
  # @param envelope_id  [String, nil] optional Envelope assignment
  # @param note         [String, nil] optional description
  # @return [ReconcileService::Adjustment, nil]
  def adjustment(source:, transactions:, real_balance:, envelope_id: nil, note: nil)
    computed = BalanceEngine.balance(source: source, transactions: transactions)
    # `real_balance − computed` raises CurrencyMismatch when reality is in a
    # different currency than the source (computed is in the source's currency).
    drift = real_balance.subtract(computed)
    return nil if drift.zero?

    Adjustment.new(source_id: source.id, amount: drift, envelope_id: envelope_id, note: note)
  end

  # Reconciles many sources against their re-entered balances, sharing one
  # transaction ledger. Produces an independent `Adjustment` for each source
  # whose reality drifted and records the unchanged sources separately.
  #
  # @param sources       [Array<BalanceEngine::Source>]
  # @param transactions  [Array<BalanceEngine::Transaction>]
  # @param real_balances [Hash{String=>Money}] source id → re-entered balance
  # @return [ReconcileService::Result]
  def reconcile(sources:, transactions:, real_balances:)
    adjustments = []
    unchanged = []

    sources.each do |source|
      real = real_balances.fetch(source.id)
      adj = adjustment(source: source, transactions: transactions, real_balance: real)
      if adj.nil?
        unchanged << source.id
      else
        adjustments << adj
      end
    end

    Result.new(adjustments: adjustments, unchanged_sources: unchanged)
  end

  # The `BalanceEngine::Transaction` form of an Adjustment, so the derived drift
  # can be folded back through `BalanceEngine` (proving it lands on reality, and
  # used by the issue-17 write path).
  #
  # @param adjustment [ReconcileService::Adjustment]
  # @return [BalanceEngine::Transaction]
  def as_transaction(adjustment)
    BalanceEngine::Transaction.build(
      kind: :adjustment,
      amount: adjustment.amount,
      source_id: adjustment.source_id
    )
  end
end
