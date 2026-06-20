require "roar/decorator"
require "roar/json"

# Public shape of an Envelope (issue 15). Decorates an EnvelopePresenter so the
# computed spent / remaining for the month render alongside the stored fields.
# Money is always integer minor units (MoneyMinorUnits in the OpenAPI contract)
# — never a float (ADR-0015). Optional caps are omitted, not null, when unset.
class EnvelopeRepresenter < Roar::Decorator
  include Roar::JSON

  property :id
  property :name
  property :icon, render_nil: true
  property :is_reserve
  property :currency

  property :allocation, exec_context: :decorator
  property :carried, exec_context: :decorator
  property :spent, exec_context: :decorator
  property :remaining, exec_context: :decorator
  property :weekly_cap, exec_context: :decorator, render_nil: false
  property :monthly_cap, exec_context: :decorator, render_nil: false

  def allocation = money(represented.allocation)
  def carried = money(represented.carried)
  def spent = money(represented.spent)
  def remaining = money(represented.remaining)
  def weekly_cap = money(represented.weekly_cap)
  def monthly_cap = money(represented.monthly_cap)

  private

  # Serializes a `Money` to the contract's MoneyMinorUnits shape, or nil.
  def money(value)
    return nil if value.nil?

    { amount_minor: value.minor_units, currency: value.currency.to_s }
  end
end
