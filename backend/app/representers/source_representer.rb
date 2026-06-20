require "roar/decorator"
require "roar/json"

# Public shape of a money source (issue 13). Decorates a SourcePresenter so the
# computed current balance + valuation render alongside the stored fields. Money
# is always integer minor units (MoneyMinorUnits in the OpenAPI contract) — never
# a float (ADR-0015).
#
# `opening_balance` is rendered only for money sources (Account/Credit card);
# `holding` only for Holdings — the irrelevant block is omitted, not null.
class SourceRepresenter < Roar::Decorator
  include Roar::JSON

  property :id
  property :kind
  property :name
  property :icon
  property :logo
  property :currency

  property :opening_balance, exec_context: :decorator, render_nil: false
  property :holding, exec_context: :decorator, render_nil: false
  property :current_balance, exec_context: :decorator
  property :valuation, exec_context: :decorator

  def opening_balance
    money(represented.opening_balance)
  end

  def current_balance
    money(represented.current_balance)
  end

  def valuation
    money(represented.valuation)
  end

  def holding
    return nil unless represented.holding?

    {
      opening_quantity: decimal_string(represented.opening_quantity),
      unit: represented.holding_unit,
      ticker: represented.ticker
    }
  end

  private

  # Serializes a `Money` to the contract's MoneyMinorUnits shape, or nil.
  def money(value)
    return nil if value.nil?

    { amount_minor: value.minor_units, currency: value.currency.to_s }
  end

  # A clean, exact decimal string for an opening quantity (BigDecimal), with no
  # scientific notation or trailing zeros: 3.0 → "3", 1.50 → "1.5".
  def decimal_string(big)
    return nil if big.nil?

    big.to_s("F").sub(/(\.\d*?)0+\z/, '\1').sub(/\.\z/, "")
  end
end
