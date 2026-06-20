# frozen_string_literal: true

# A long-term savings target with a funding window and a planned Schedule
# (CONTEXT.md › Goals). This is a pure value object — no Rails, no DB — used by
# the `GoalTracker` engine the same way `Money` is used by the money engines
# (ADR-0006 pure services, ADR-0015 exact money).
#
# A Goal holds:
#   - `target`      — the savings target as `Money` (VND-only for now).
#   - `start_month` / `end_month` — the funding window (`Goal::Month`).
#   - `schedule`    — the planned contributions (`Goal::ScheduleLine`), one per
#     funded month. Need not be flat or continuous. Stored oldest-first.
#
# A Goal's *balance* (the accumulated Contributions) is not stored here — it is
# computed by `GoalTracker.contributed` from the user's Transfer transactions.
class Goal
  # A year+month coordinate (Contributions are month-based, not day-based).
  Month = Data.define(:year, :month) do
    # A total order key so months across years compare correctly.
    def year_month = (year * 12) + month
  end

  # One planned line of a Goal's Schedule: a month and its planned `Money`
  # amount. A line is a *plan*, distinct from an actual Contribution.
  ScheduleLine = Data.define(:year, :month, :amount) do
    def year_month = (year * 12) + month
  end

  attr_reader :id, :name, :target, :start_month, :end_month, :schedule

  def initialize(target:, schedule:, id: nil, name: nil, start_month: nil, end_month: nil)
    @id = id
    @name = name
    @target = target
    @start_month = start_month
    @end_month = end_month
    # Oldest-first is the canonical order the engine fills and reports lines in.
    @schedule = schedule.sort_by(&:year_month).freeze
    freeze
  end

  # The Goal's currency is its target currency; the whole Schedule shares it.
  def currency = target.currency
end
