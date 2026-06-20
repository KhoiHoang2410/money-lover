# The persistence edge for a Goal (CONTEXT.md): a long-term savings target owned
# by a User. Tenant-scoped via Tenanted — only ever loaded through
# `current_user.goals`, so another user's goal is unreachable (ADR-0014).
#
# Named `GoalRecord` (table `goals`) because the bare `Goal` constant is the pure
# domain value object in app/domain/goal.rb that the `GoalTracker` engine consumes
# (the same split as Source → BalanceEngine::Source). This class stores money as
# integer minor units + a currency (never a float — ADR-0015) and the Schedule as
# JSON, and builds the domain `Goal` the engine works on via `#to_domain`.
#
# A Goal's *balance* is not a column: it is the sum of the `.transfer`
# transactions tagged with this goal's id (ADR-0007), derived on read by
# `GoalTracker.contributed`. The ledger is the single source of truth for funding.
class GoalRecord < ApplicationRecord
  include Tenanted

  self.table_name = "goals"

  validates :name, presence: true
  validates :currency, presence: true
  validates :target_minor_units, presence: true

  # The savings target as a `Money` in the goal's currency.
  def target
    MoneyMapping.load(minor_units: target_minor_units, currency: currency)
  end

  # The pure domain `Goal` (target + funding window + Schedule) the GoalTracker
  # engine consumes. Pure value objects only — no ActiveRecord crosses into the
  # engine (ADR-0006).
  def to_domain
    Goal.new(
      id: id,
      name: name,
      target: target,
      start_month: month_value(start_year, start_month),
      end_month: month_value(end_year, end_month),
      schedule: schedule_lines
    )
  end

  private

  def month_value(year, month)
    return nil if year.nil? || month.nil?

    Goal::Month.new(year: year, month: month)
  end

  # The stored Schedule (a JSON array of { year, month, amount_minor_units }) as
  # domain `Goal::ScheduleLine`s, each amount a `Money` in the goal's currency.
  def schedule_lines
    Array(schedule).map do |line|
      Goal::ScheduleLine.new(
        year: line["year"],
        month: line["month"],
        amount: MoneyMapping.load(minor_units: line["amount_minor_units"], currency: currency)
      )
    end
  end
end
