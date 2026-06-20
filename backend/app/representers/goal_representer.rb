require "roar/decorator"
require "roar/json"
require "bigdecimal"

# Public shape of a Goal (issue 16). Decorates a GoalPresenter so the live
# balance, Expected-by-today progress, and per-line Schedule status + shortfall
# render alongside the stored fields. Money is always integer minor units
# (MoneyMinorUnits in the OpenAPI contract) — never a float (ADR-0015).
#
# The ahead/delay ratio (`progress.pct`) is an exact Rational; it is rendered as a
# bounded decimal STRING (never a JSON number) and is null until something is due.
class GoalRepresenter < Roar::Decorator
  include Roar::JSON

  # Decimal places the ahead/delay ratio is rendered to. A ratio is not money, but
  # we still keep it a string and out of Float to stay precision-honest.
  RATIO_SCALE = 6

  property :id
  property :name
  property :icon, render_nil: false
  property :currency
  property :target, exec_context: :decorator
  property :start_month, exec_context: :decorator, render_nil: false
  property :end_month, exec_context: :decorator, render_nil: false
  property :balance, exec_context: :decorator
  property :schedule, exec_context: :decorator
  property :progress, exec_context: :decorator

  def target = money(represented.target)
  def balance = money(represented.balance)
  def start_month = month(represented.start_month)
  def end_month = month(represented.end_month)

  def schedule
    represented.schedule_lines.map do |line|
      {
        year: line.year,
        month: line.month,
        planned: money(line.planned),
        status: line.status.to_s,
        shortfall: money(line.shortfall)
      }
    end
  end

  def progress
    result = represented.progress
    {
      expected: money(result.expected),
      pct: ratio(result.pct),
      pct_sign: result.pct_sign.to_s
    }
  end

  private

  # Serializes a `Money` to the contract's MoneyMinorUnits shape, or nil.
  def money(value)
    return nil if value.nil?

    { amount_minor: value.minor_units, currency: value.currency.to_s }
  end

  # A funding-window month as a { year, month } object, or nil when unset.
  def month(value)
    return nil if value.nil?

    { year: value.year, month: value.month }
  end

  # The exact ahead/delay Rational as a bounded decimal string, or nil when no
  # ratio is defined yet (nothing due). Exact integer division in BigDecimal — no
  # Float ever enters (ADR-0015).
  def ratio(rational)
    return nil if rational.nil?

    value = BigDecimal(rational.numerator).div(BigDecimal(rational.denominator), RATIO_SCALE + 4)
    text = value.round(RATIO_SCALE).to_s("F")
    text.sub(/(\.\d*?)0+\z/, '\1').sub(/\.\z/, "")
  end
end
