# frozen_string_literal: true

# Pure envelope-budgeting engine (issue 10, ADR-0015 / ADR-0007).
#
# An Envelope is a named virtual bucket income is divided into; its Allocation is
# the amount planned into it for the month (CONTEXT.md "Envelope" / "Allocation").
# This module computes the three numbers the clients render and the month-end
# Reserve sweep, entirely in integer minor units via the `Money` value type
# (issue 04), so Float never enters budget math (ADR-0015):
#
#   - `spent`      — Σ of the Expenses assigned to an Envelope (income/other
#     Envelopes contribute nothing).
#   - `remaining`  — allocation + carried − spent. `carried` is the Reserve's
#     accumulated balance (or a non-Reserve Envelope's roll-over); it can push
#     remaining above the Allocation, and overspending drives it negative.
#   - `month_end`  — the Reserve sweep: at month-end each non-Reserve Envelope's
#     leftover (Allocation − spent) moves into the Reserve; a positive leftover
#     adds, an overspent (negative) Envelope deducts. `reserve_delta` is the net
#     sum of those leftovers. The Reserve itself is never a sweep line — it
#     accumulates and does not reset (CONTEXT.md "Reserve").
#
# Parity oracle for `golden/fixtures/budgets.json` (issue 03 / ADR-0015): every
# case there must reproduce byte-identically, including the overspent-Envelope
# case that deducts from the Reserve.
#
# Time & the deferred month-end mechanism (PRD Further Notes, this issue's spec):
# resolved as **derived-on-read from stored per-month Allocation snapshots**, not
# a stateful per-timezone cron. This engine is pure and clock-free — it takes
# already-resolved per-month inputs (the caller resolves month boundaries in the
# User's timezone), so replaying or recomputing a month is idempotent and never
# double-applies a sweep. The choice is reversible (no stored sweep side-effects),
# so per the issue it needs no standalone ADR.
module BudgetEngine
  # An Envelope for budget math: its Allocation for the month, any `carried`
  # balance (the Reserve's accumulated total, or a non-Reserve roll-over; defaults
  # to zero in the Allocation's currency), and whether it is the Reserve.
  Envelope = Data.define(:id, :name, :allocation, :carried, :is_reserve) do
    def self.build(id:, name:, allocation:, carried: nil, is_reserve: false)
      new(
        id: id,
        name: name,
        allocation: allocation,
        carried: carried || Money.zero(allocation.currency),
        is_reserve: is_reserve
      )
    end
  end

  # A transaction that may be assigned to an Envelope. Only an `:expense` whose
  # `envelope_id` matches counts toward that Envelope's spent; the sign is implicit
  # (`amount` is a non-negative magnitude that reduces the Envelope's remaining).
  Transaction = Data.define(:kind, :amount, :source_id, :envelope_id) do
    def self.build(kind:, amount:, source_id: nil, envelope_id: nil)
      new(kind: kind.to_sym, amount: amount, source_id: source_id, envelope_id: envelope_id)
    end
  end

  # One Envelope's contribution to the Reserve sweep: its leftover (Allocation −
  # spent), positive when under budget, negative when overspent.
  SweepLine = Data.define(:envelope_id, :leftover)

  # The result of a month-end sweep: the per-Envelope `lines` (non-Reserve only)
  # and `reserve_delta`, the net `Money` moved into the Reserve.
  MonthEnd = Data.define(:reserve_delta, :lines) do
    def line_count = lines.size
  end

  module_function

  # Σ of the Expenses assigned to `envelope_id`. Income and Expenses assigned to
  # other Envelopes contribute nothing. `currency` fixes the result currency
  # (required so an empty/no-match list still yields a typed zero).
  #
  # @param envelope_id  [String, Symbol]
  # @param transactions [Array<BudgetEngine::Transaction>]
  # @param currency     [Symbol, String]
  # @return [Money]
  def spent(envelope_id:, transactions:, currency:)
    amounts = transactions.filter_map do |txn|
      txn.amount if expense_for?(txn, envelope_id)
    end
    Money.sum(amounts, currency: currency)
  end

  # An Envelope's remaining for the month: allocation + carried − spent. Negative
  # when the Envelope is overspent.
  #
  # @param envelope     [BudgetEngine::Envelope]
  # @param transactions [Array<BudgetEngine::Transaction>]
  # @return [Money]
  def remaining(envelope:, transactions:)
    currency = envelope.allocation.currency
    spent_amount = spent(envelope_id: envelope.id, transactions: transactions, currency: currency)
    envelope.allocation.add(envelope.carried).subtract(spent_amount)
  end

  # The month-end Reserve sweep over `envelopes`, given each Envelope's already
  # computed `spent` (a list of { envelope_id:, spent: }). Each non-Reserve
  # Envelope yields a `SweepLine` of leftover = Allocation − spent (zero spent
  # when absent); `reserve_delta` is their net sum. The Reserve is excluded from
  # the lines — it absorbs the delta rather than sweeping itself.
  #
  # @param envelopes        [Array<BudgetEngine::Envelope>]
  # @param spent_by_envelope [Hash{String=>Money}, #to_h] envelope_id ⇒ spent Money
  # @return [BudgetEngine::MonthEnd]
  def month_end(envelopes:, spent_by_envelope:)
    spent_map = spent_by_envelope.to_h
    currency = sweep_currency(envelopes)

    lines = envelopes.reject(&:is_reserve).map do |envelope|
      spent_amount = spent_map.fetch(envelope.id, Money.zero(currency))
      SweepLine.new(envelope_id: envelope.id, leftover: envelope.allocation.subtract(spent_amount))
    end

    reserve_delta = Money.sum(lines.map(&:leftover), currency: currency)
    MonthEnd.new(reserve_delta: reserve_delta, lines: lines)
  end

  # --- internal helpers -----------------------------------------------------

  def expense_for?(transaction, envelope_id)
    transaction.kind.to_s == "expense" && transaction.envelope_id == envelope_id
  end

  # The sweep's working currency: every Envelope's Allocation must share one
  # currency (no cross-currency sweep). Raises on an empty Envelope set, since
  # there is then no currency to total into.
  def sweep_currency(envelopes)
    raise ArgumentError, "month_end needs at least one envelope" if envelopes.empty?

    envelopes.first.allocation.currency
  end
end
