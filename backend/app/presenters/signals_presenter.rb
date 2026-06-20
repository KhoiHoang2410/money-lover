# frozen_string_literal: true

# Read model for the Signals surface (issue 20). Bridges the AR edge to the pure
# SignalEngine (ADR-0006): it loads the caller's Envelopes, in-month Expenses and
# Goals, builds the engine's value objects, sums each Goal's live balance via the
# pure GoalTracker, and returns the computed Signals — strongest first.
#
# "Today" is `as_of` (a Date already resolved in the User's timezone by the
# controller); the month boundary is derived from it so the engine stays
# clock-free. Every collection is tenant-scoped by the controller (ADR-0014).
class SignalsPresenter
  # Adapter so an ActiveRecord Transaction quacks like the value object
  # GoalTracker.contributions expects (kind / amount / goal_id / date).
  Contribution = Struct.new(:kind, :amount, :goal_id, :date, keyword_init: true)

  # @param envelopes    [Array<Envelope>]    the caller's Envelopes.
  # @param transactions [Array<Transaction>] the caller's ledger rows.
  # @param goals        [Array<GoalRecord>]  the caller's Goals.
  # @param as_of        [Date]               "today" in the User's timezone.
  def initialize(envelopes:, transactions:, goals:, as_of:)
    @envelopes = envelopes
    @transactions = transactions
    @goals = goals
    @as_of = as_of
  end

  # The computed Signals (strongest-first), as SignalEngine::Signal value objects.
  def signals
    SignalEngine.signals(
      envelopes: envelope_inputs,
      transactions: transaction_inputs,
      goals: goal_inputs,
      as_of: @as_of
    )
  end

  private

  # The first day of the caller's current month, derived from `as_of`, used to
  # pick each Envelope's effective Allocation snapshot (ADR-0014).
  def month
    @month ||= @as_of.beginning_of_month
  end

  def envelope_inputs
    @envelopes.map do |envelope|
      SignalEngine::Envelope.new(
        id: envelope.id,
        name: envelope.name,
        allocation: envelope.allocation_for(month),
        carried: envelope.carried,
        is_reserve: envelope.is_reserve
      )
    end
  end

  def transaction_inputs
    @transactions.map do |txn|
      SignalEngine::Transaction.new(
        id: txn.id,
        kind: txn.kind,
        amount: txn.amount,
        envelope_id: txn.envelope_id,
        date: txn.occurred_on,
        note: txn.note
      )
    end
  end

  def goal_inputs
    @goals.map do |goal|
      domain = goal.to_domain
      actual = GoalTracker.contributed(
        transactions: contribution_adapters, goal_id: goal.id, currency: domain.currency
      )
      SignalEngine::GoalState.new(goal: domain, actual: actual)
    end
  end

  def contribution_adapters
    @contribution_adapters ||= @transactions.map do |txn|
      Contribution.new(kind: txn.kind, amount: txn.amount, goal_id: txn.goal_id, date: txn.occurred_on)
    end
  end
end
