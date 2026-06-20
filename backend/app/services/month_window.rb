# frozen_string_literal: true

# Resolves a User's current month boundary in their own timezone (CONTEXT.md
# "User": timezone defines month boundaries and "today"). Returns the first day
# of the month as a Date, which the Envelopes read path uses to pick the month's
# Allocation snapshot and the in-month Expenses for spent/remaining (ADR-0014).
module MonthWindow
  module_function

  # The first day of the User's current month, in `timezone`.
  def current_first_of_month(timezone)
    zone = ActiveSupport::TimeZone[timezone.to_s] || ActiveSupport::TimeZone["UTC"]
    zone.today.beginning_of_month
  end
end
