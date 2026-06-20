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
  def initialize(source, rates: Rates.empty)
    @source = source
    @rates = rates
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
  # (CONTEXT.md). The Transactions API (issue 14) is the only writer of those
  # deltas; until it lands, a money source's current balance is its opening
  # balance, and a Holding (no money balance) is ₫0 in the base currency.
  def current_balance
    if source.account_like?
      BalanceEngine.current(opening: source.opening_balance, deltas: [])
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
end
