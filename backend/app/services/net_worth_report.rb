# frozen_string_literal: true

# Composes the persisted edge (Sources, Transactions, Goals) into the pure
# `NetWorthEngine` (issue 09) so a request can read its net worth and the
# aggregated data behind the clients' reports (issue 18). The Rails controller
# loads the caller's rows; this module turns them into the engine value objects
# and folds them — no AR query, no Float (ADR-0015), so the money-correctness
# invariants stay the engines' single source of truth.
#
# Net worth = NetWorthEngine.compute over every money/holding Source's current
# balance plus every Goal balance, valued in VND via the caller's resolved
# `Rates` (RateService, issue 19). A holding is valued at its opening quantity,
# exactly as the Sources API does (issue 13), keeping parity with the
# `golden/fixtures/net_worth.json` oracle.
module NetWorthReport
  module_function

  # The asset / debt / net `NetWorthEngine::Result` for the caller.
  #
  # @param sources      [Array<Source>]      the caller's money/holding sources
  # @param goals        [Array<GoalRecord>]  the caller's goals
  # @param transactions [Array<Transaction>] the caller's ledger rows
  # @param rates        [Rates]              resolved conversion rates
  # @param as_of        [Date]               "today" in the caller's timezone
  # @return [NetWorthEngine::Result]
  def compute(sources:, goals:, transactions:, rates:, as_of:)
    entries = sources.map { |source| entry_for(source, transactions) }
    goal_balances = goals.map { |goal| goal_balance(goal, transactions, as_of) }
    NetWorthEngine.compute(entries: entries, rates: rates, goal_balances: goal_balances)
  end

  # One source as a `NetWorthEngine::Entry`. A money source carries its current
  # balance (BalanceEngine over the caller's ledger); a Holding carries ₫0 plus
  # its valuation facts (the engine prices it off quantity, not a money balance).
  def entry_for(source, transactions)
    if source.account_like?
      NetWorthEngine::Entry.build(
        kind: source.kind,
        currency: source.currency,
        balance: current_balance(source, transactions)
      )
    else
      NetWorthEngine::Entry.build(
        kind: :holding,
        currency: source.currency,
        balance: Money.zero(:VND),
        holding: source.holding_facts
      )
    end
  end

  # Current balance = opening + Σ balance-affecting transactions (BalanceEngine).
  def current_balance(source, transactions)
    engine_source = BalanceEngine::Source.build(
      id: source.id,
      kind: source.kind,
      currency: source.currency,
      opening_balance: source.opening_balance
    )
    BalanceEngine.balance(
      source: engine_source,
      transactions: transactions.map(&:to_balance_txn)
    )
  end

  # A Goal's balance is the sum of its Contributions (GoalPresenter/GoalTracker),
  # an Asset added to the net-worth total directly (ADR-0007).
  def goal_balance(goal, transactions, as_of)
    GoalPresenter.new(goal, transactions: transactions, as_of: as_of).balance
  end
end
