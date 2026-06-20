require "roar/decorator"
require "roar/json"

# Public shape of a Transaction (issue 14). Decorates a TransactionPresenter so
# money fields render as integer minor units (MoneyMinorUnits in the OpenAPI
# contract) — never a float (ADR-0015). Kind-specific blocks
# (destination_amount, fee, manual_rate, trade_*) are omitted, not null, when
# they don't apply.
class TransactionRepresenter < Roar::Decorator
  include Roar::JSON

  property :id
  property :kind
  property :source_id
  property :destination_id, render_nil: false
  property :amount, exec_context: :decorator
  property :destination_amount, exec_context: :decorator, render_nil: false
  property :fee, exec_context: :decorator, render_nil: false
  property :manual_rate, exec_context: :decorator, render_nil: false
  property :trade_quantity, exec_context: :decorator, render_nil: false
  property :trade_direction, render_nil: false
  property :envelope_id, render_nil: false
  property :goal_id, render_nil: false
  property :note, render_nil: false
  property :occurred_on, exec_context: :decorator
  property :backfill, exec_context: :decorator

  def amount
    money(represented.amount)
  end

  def destination_amount
    money(represented.destination_amount)
  end

  def fee
    money(represented.fee)
  end

  def manual_rate
    decimal_string(represented.manual_rate)
  end

  def trade_quantity
    decimal_string(represented.trade_quantity)
  end

  def occurred_on
    represented.occurred_on.iso8601
  end

  def backfill
    represented.backfill?
  end

  private

  # Serializes a `Money` to the contract's MoneyMinorUnits shape, or nil.
  def money(value)
    return nil if value.nil?

    { amount_minor: value.minor_units, currency: value.currency.to_s }
  end

  # A clean, exact decimal string for a BigDecimal, with no scientific notation
  # or trailing zeros: 3.0 → "3", 1.50 → "1.5".
  def decimal_string(big)
    return nil if big.nil?

    big.to_s("F").sub(/(\.\d*?)0+\z/, '\1').sub(/\.\z/, "")
  end
end
