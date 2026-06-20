# Read model for an Envelope: wraps the persisted record and computes its
# spent / remaining for a given month via the pure BudgetEngine (issue 10), so
# all budget math stays in integer minor units (ADR-0015). Keeps the engine and
# the AR edge apart — the controller builds one of these per envelope (with the
# month's in-window Expenses) and hands it to EnvelopeRepresenter.
class EnvelopePresenter
  attr_reader :envelope

  # @param envelope     [Envelope]
  # @param month        [Date] the first day of the month to report (User tz).
  # @param transactions [Array<Transaction>] the caller's in-month ledger rows;
  #   only Expenses assigned to this Envelope (same currency) count toward spent.
  def initialize(envelope, month:, transactions: [])
    @envelope = envelope
    @month = month
    @transactions = transactions
  end

  def id = envelope.id
  def name = envelope.name
  def icon = envelope.icon
  def is_reserve = envelope.is_reserve
  def currency = envelope.currency
  def carried = envelope.carried
  def weekly_cap = envelope.weekly_cap
  def monthly_cap = envelope.monthly_cap

  # The effective Allocation for the reported month (snapshot, else default).
  def allocation = envelope.allocation_for(@month)

  # Σ of this month's Expenses assigned to this Envelope (BudgetEngine).
  def spent
    BudgetEngine.spent(
      envelope_id: envelope.id,
      transactions: engine_transactions,
      currency: Currency.normalize(envelope.currency)
    )
  end

  # allocation + carried − spent (BudgetEngine); negative when overspent.
  def remaining
    BudgetEngine.remaining(envelope: envelope.to_budget_envelope(@month), transactions: engine_transactions)
  end

  private

  # The in-month rows as BudgetEngine::Transaction value objects. Only Expenses
  # in this Envelope's currency are forwarded; the engine then filters to this
  # Envelope's id, and a different-currency Expense never enters the sum.
  def engine_transactions
    @transactions.filter_map do |txn|
      next unless txn.kind == Transaction::EXPENSE
      next unless txn.currency == envelope.currency

      BudgetEngine::Transaction.build(kind: txn.kind, amount: txn.amount, envelope_id: txn.envelope_id)
    end
  end
end
