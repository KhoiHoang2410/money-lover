# Read model for a Source: wraps the persisted record and computes its live
# current balance (BalanceEngine) and base-currency valuation (Valuator) for the
# representer. Keeps the pure engines and the AR edge apart — the controller
# builds one of these per source and hands it to SourceRepresenter.
class SourcePresenter
  attr_reader :source

  # @param source [Source]
  # @param rates  [Rates] resolved conversion rates. Rate persistence/override
  #   resolution arrives in issue 19; until then valuations use the empty table
  #   (VND is its own unit; foreign FX / gold / stock prices degrade to ₫0 rather
  #   than raising — Valuator's documented behaviour).
  # @param transactions [Array<Transaction>] the caller's ledger rows. The
  #   current balance is recomputed from these on every read (issue 14), so an
  #   edit/delete needs no balance bookkeeping — the engine derives it. Defaults
  #   to none (a freshly-created source has no transactions yet).
  def initialize(source, rates: Rates.empty, transactions: [])
    @source = source
    @rates = rates
    @transactions = transactions
  end

  def id = source.id
  def kind = source.kind
  def name = source.name
  def icon = source.icon
  def logo = source.logo
  def currency = source.currency
  def opening_balance = source.opening_balance
  def holding? = source.holding?
  def holding_unit = source.holding_unit
  def ticker = source.ticker

  # The raw exact opening quantity (BigDecimal) for a Holding, else nil.
  def opening_quantity = source.opening_quantity

  # Current balance = opening balance + Σ balance-affecting transactions
  # (CONTEXT.md), derived by BalanceEngine from the caller's ledger rows. A
  # Holding has no money balance, so it is ₫0 in the base currency.
  def current_balance
    if source.account_like?
      BalanceEngine.balance(source: engine_source, transactions: engine_transactions)
    else
      Money.zero(:VND)
    end
  end

  # Value of this source in the base currency (VND).
  def valuation
    Valuator.value_in_vnd(
      kind: source.kind,
      currency: source.currency,
      balance: current_balance,
      rates: @rates,
      holding: source.holding_facts
    )
  end

  private

  # This money source as a BalanceEngine value object (the pure engine never
  # sees ActiveRecord).
  def engine_source
    BalanceEngine::Source.build(
      id: source.id,
      kind: source.kind,
      currency: source.currency,
      opening_balance: source.opening_balance
    )
  end

  # The ledger rows as BalanceEngine::Transaction value objects. Rows that do not
  # touch this source contribute nothing (the engine filters by id).
  def engine_transactions
    @transactions.map { |txn| txn.respond_to?(:to_balance_txn) ? txn.to_balance_txn : txn }
  end
end
