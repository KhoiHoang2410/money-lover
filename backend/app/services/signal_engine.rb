# frozen_string_literal: true

# Pure deterministic Signal engine (issue 20, ADR-0004 paused → deterministic
# only). Ported from the Swift `SignalEngine` in
# `ios/MoneyLover/Core/SignalEngine.swift`: given a snapshot of the User's
# Envelopes, in-month Expenses and Goal states, it computes the spending/goal
# Signals the clients render — envelope pace (projected overspend), an overspent
# Envelope, a Goal behind plan, a drained Reserve, and an unusually large
# Expense (CONTEXT.md "Signal").
#
# It is a pure module — no Rails, no DB, no clock — so it is deterministically
# golden-testable. Every threshold is an EXACT integer comparison on minor units
# (Money), never a float (ADR-0015); ratios stay integer cross-multiplications
# (`spent * days_in_month > allocation * day`). "Today" is passed in as `as_of`
# (a Date already resolved in the User's timezone by the caller) so the engine
# itself stays clock-free.
#
# The "Recommendation" phrasing layer (and any model/LLM/voice) is deferred
# (ADR-0004 paused): the deterministic `title`/`detail` text is returned directly.
module SignalEngine
  # The strongest-first ranking of a Signal's severity (info < warning < critical).
  SEVERITY_RANK = { info: 0, warning: 1, critical: 2 }.freeze

  # A computed Signal: a stable `id` (kind + entity id, so clients diff cleanly),
  # its `kind`, `severity`, and the deterministic `title`/`detail` text.
  Signal = Data.define(:id, :kind, :severity, :title, :detail)

  # An Envelope as the engine sees it: its monthly Allocation, accumulated
  # `carried` balance, and whether it is the Reserve — all `Money`.
  Envelope = Data.define(:id, :name, :allocation, :carried, :is_reserve)

  # A ledger row the engine may count: an Expense's `amount` (Money) assigned to
  # an `envelope_id`, dated `date` (a Date), with an optional free-text `note`.
  Transaction = Data.define(:id, :kind, :amount, :envelope_id, :date, :note)

  # One Goal paired with the amount actually contributed so far (the caller sums
  # the Contributions via GoalTracker before handing it in).
  GoalState = Data.define(:goal, :actual)

  module_function

  # Every Signal that fires for the snapshot, strongest first. `as_of` is a Date
  # in the User's timezone; `envelopes`/`transactions`/`goals` are the engine
  # value objects above.
  def signals(envelopes:, transactions:, goals:, as_of:)
    day = as_of.day
    days_in_month = Date.new(as_of.year, as_of.month, -1).day
    month_expenses = month_expenses(transactions, as_of)

    result = []

    envelopes.each do |envelope|
      spent = month_spend(envelope.id, month_expenses, envelope.allocation.currency)
      signal =
        if envelope.is_reserve
          reserve_signal(envelope, spent)
        else
          envelope_signal(envelope, spent, day, days_in_month)
        end
      result << signal if signal
    end

    goals.each do |state|
      signal = goal_signal(state, as_of)
      result << signal if signal
    end

    big = large_expense_signal(month_expenses)
    result << big if big

    result.sort_by { |signal| -SEVERITY_RANK.fetch(signal.severity) }
  end

  # --- rules ----------------------------------------------------------------

  # An Envelope overspent (critical) or on track to overspend by linear pace
  # (warning), or nil when comfortably within plan. Only Envelopes with a
  # positive Allocation can fire.
  def envelope_signal(envelope, spent, day, days_in_month)
    allocation = envelope.allocation.minor_units
    return nil unless allocation.positive?

    spent_minor = spent.minor_units
    name = envelope.name

    if spent_minor > allocation
      over = Money.new(minor_units: spent_minor - allocation, currency: envelope.allocation.currency)
      return Signal.new(
        id: "#{:envelopeOverspent}-#{envelope.id}",
        kind: :envelopeOverspent,
        severity: :critical,
        title: "#{name} is overspent",
        detail: "#{money_text(over)} over the #{money_text(envelope.allocation)} plan."
      )
    end

    # Linear pace: spent/elapsed > allocation ⇔ spent·days_in_month > allocation·day.
    # Exact in integers — the spent-fraction strictly exceeds the elapsed-fraction.
    if day >= 1 && day < days_in_month && spent_minor * days_in_month > allocation * day
      return Signal.new(
        id: "#{:projectedOverspend}-#{envelope.id}",
        kind: :projectedOverspend,
        severity: :warning,
        title: "#{name} is on track to overspend",
        detail: "At this pace it runs out before month-end " \
                "(#{money_text(spent)} of #{money_text(envelope.allocation)})."
      )
    end

    nil
  end

  # The Reserve buffer drained to zero or below (allocation + carried − spent ≤ 0).
  def reserve_signal(envelope, spent)
    remaining = envelope.allocation.minor_units + envelope.carried.minor_units - spent.minor_units
    return nil if remaining.positive?

    money = Money.new(minor_units: remaining, currency: envelope.allocation.currency)
    Signal.new(
      id: "#{:reserveLow}-#{envelope.id}",
      kind: :reserveLow,
      severity: :critical,
      title: "Reserve is drained",
      detail: "Your #{envelope.name} buffer is down to #{money_text(money)}."
    )
  end

  # A Goal behind its Schedule: fires past a 10% shortfall vs Expected-by-today,
  # critical past 25%. Reuses the pure GoalTracker for the Expected amount.
  def goal_signal(state, as_of)
    progress = GoalTracker.progress(goal: state.goal, actual: state.actual, as_of: as_of)
    expected = progress.expected.minor_units
    actual = progress.actual.minor_units
    # Only nag past a 10% shortfall (actual < 0.9·expected ⇔ actual·10 < expected·9).
    return nil unless expected.positive? && actual * 10 < expected * 9

    shortfall = Money.new(minor_units: expected - actual, currency: progress.expected.currency)
    # Critical past a 25% shortfall (actual·4 < expected·3).
    severity = actual * 4 < expected * 3 ? :critical : :warning
    Signal.new(
      id: "#{:goalBehind}-#{state.goal.id}",
      kind: :goalBehind,
      severity: severity,
      title: "#{state.goal.name} is behind plan",
      detail: "#{money_text(shortfall)} short of where the schedule expects you."
    )
  end

  # An unusually large Expense: the biggest of the month's Expenses is more than
  # 3× the average of the rest. Needs at least 3 Expenses to be meaningful.
  def large_expense_signal(month_expenses)
    return nil if month_expenses.size < 3

    sum = month_expenses.sum { |txn| txn.amount.minor_units }
    biggest = month_expenses.max_by { |txn| txn.amount.minor_units }
    amount = biggest.amount.minor_units
    others = month_expenses.size - 1
    # Fires when the biggest expense is more than 3× the average of the rest.
    return nil unless amount * others > 3 * (sum - amount)

    note = biggest.note.to_s
    label = note.empty? ? "An expense" : "\"#{note}\""
    Signal.new(
      id: "#{:largeExpense}-#{biggest.id}",
      kind: :largeExpense,
      severity: :info,
      title: "Unusually large expense",
      detail: "#{label} of #{money_text(biggest.amount)} stands out this month."
    )
  end

  # --- helpers --------------------------------------------------------------

  # The Expenses whose date falls in `as_of`'s calendar month (year + month).
  def month_expenses(transactions, as_of)
    transactions.select do |txn|
      txn.kind.to_s == "expense" && txn.date.year == as_of.year && txn.date.month == as_of.month
    end
  end

  # Σ of the month's Expenses assigned to `envelope_id`, in `currency`.
  def month_spend(envelope_id, month_expenses, currency)
    amounts = month_expenses.select { |txn| txn.envelope_id == envelope_id }.map(&:amount)
    Money.sum(amounts, currency: currency)
  end

  # The deterministic plain-text rendering of a `Money`: the currency symbol and
  # the major-unit amount with thousands grouped (e.g. ₫200,000). Integer-only —
  # no Float ever enters (ADR-0015). VND-only in practice; falls back to the code.
  SYMBOLS = { VND: "₫" }.freeze

  def money_text(money)
    symbol = SYMBOLS.fetch(money.currency) { "#{money.currency} " }
    grouped = group_digits(money.minor_units.abs)
    sign = money.minor_units.negative? ? "-" : ""
    "#{sign}#{symbol}#{grouped}"
  end

  def group_digits(value)
    value.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
  end
end
