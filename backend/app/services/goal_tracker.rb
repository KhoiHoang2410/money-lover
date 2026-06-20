# frozen_string_literal: true

# Pure goal-progress engine (issue 11, ADR-0015 / ADR-0007).
#
# Given a `Goal` (target + Schedule) and the user's Transfer transactions, it
# computes the numbers the clients render: Expected-by-today, % ahead/delay,
# per-line Schedule status, and per-line shortfall. It is a pure module — no
# Rails, no DB, no clock — so it is deterministically golden-testable against
# `golden/fixtures/goal_tracking.json`.
#
# Money correctness: every amount is an exact `Money` (integer minor units);
# Float never enters the math. Ratios (`pct`, `fraction_of_target`) stay exact
# `Rational`s and are only rendered to decimal strings at the edge.
#
# Time: "today" is passed in as `as_of` (a `Date` already resolved in the
# user's timezone by the caller) so the engine itself stays clock-free.
module GoalTracker
  # The result of `progress`: the Expected-by-today amount, the exact
  # ahead/delay ratio (`actual / expected - 1`, or nil when nothing is due yet),
  # and its sign. `fraction_of_target` (the clamped actual/target as an exact
  # decimal string) is computed on demand — it is only well-defined as a
  # terminating decimal, which not every actual/target ratio is.
  Progress = Data.define(:expected, :pct, :pct_sign, :actual, :target) do
    def fraction_of_target = GoalTracker.fraction_of_target(actual: actual, target: target)
  end

  # The Schedule-line statuses (CONTEXT.md › Schedule status).
  STATUSES = %i[funded due missed pending].freeze

  module_function

  # Expected-by-today: the cumulative scheduled amount due through `as_of`
  # (lines whose month is <= the as_of month). Empty window → zero in the
  # goal's currency.
  def expected_by_today(goal:, as_of:)
    cutoff = year_month(as_of)
    due = goal.schedule.select { |line| line.year_month <= cutoff }
    Money.sum(due.map(&:amount), currency: goal.currency)
  end

  # Goal progress at `as_of` for a given `actual` contributed amount.
  def progress(goal:, actual:, as_of:)
    expected = expected_by_today(goal: goal, as_of: as_of)
    Progress.new(
      expected: expected,
      pct: pct_ahead(actual: actual, expected: expected),
      pct_sign: pct_sign(actual: actual, expected: expected),
      actual: actual,
      target: goal.target
    )
  end

  # Per-line status, judged cumulatively against `contributed` filling lines
  # oldest-first: a line is `funded` once the running contributions cover it in
  # full; otherwise it is `due` (current month), `missed` (past month), or
  # `pending` (future month). Keyed by the line's month.
  def schedule_status(goal:, contributed:, as_of:)
    cutoff = year_month(as_of)
    remaining = [ contributed.minor_units, 0 ].max

    goal.schedule.each_with_object({}) do |line, statuses|
      need = line.amount.minor_units
      if remaining >= need
        remaining -= need
        statuses[line.month] = :funded
      else
        # First underfunded line exhausts the remaining pool; later lines get 0.
        remaining = 0
        statuses[line.month] = unfunded_status(line.year_month, cutoff)
      end
    end
  end

  # Per-line shortfall after allocating `contributed` to lines oldest-first:
  # scheduled amount minus the contributions allocated to that line. Keyed by
  # the line's month; fully funded lines report zero.
  def shortfalls(goal:, contributed:)
    remaining = [ contributed.minor_units, 0 ].max

    goal.schedule.each_with_object({}) do |line, by_month|
      need = line.amount.minor_units
      allocated = [ remaining, need ].min
      remaining -= allocated
      by_month[line.month] = Money.new(minor_units: need - allocated, currency: line.amount.currency)
    end
  end

  # The Goal's Contributions: the Transfer transactions tagged with this goal,
  # ordered oldest-first. (A Contribution is a dated Transfer into the Goal.)
  def contributions(transactions:, goal_id:)
    transactions.select { |tx| contribution_to?(tx, goal_id) }
                .sort_by(&:date)
  end

  # Goal balance: the sum of this goal's Contributions, in `currency`
  # (the goal's currency, needed when there are no contributions yet).
  def contributed(transactions:, goal_id:, currency:)
    amounts = contributions(transactions: transactions, goal_id: goal_id).map(&:amount)
    Money.sum(amounts, currency: currency)
  end

  # --- internal helpers -----------------------------------------------------

  def year_month(date) = (date.year * 12) + date.month

  def unfunded_status(line_year_month, cutoff)
    if line_year_month < cutoff
      :missed
    elsif line_year_month == cutoff
      :due
    else
      :pending
    end
  end

  def contribution_to?(transaction, goal_id)
    transaction.kind.to_s == "transfer" && transaction.goal_id == goal_id
  end

  # Sign of `actual / expected - 1`, i.e. whether the goal is ahead of, behind,
  # or exactly on plan. With nothing due yet, on-plan iff nothing contributed.
  def pct_sign(actual:, expected:)
    same_currency!(actual, expected)
    case actual.minor_units <=> expected.minor_units
    when 1 then :positive
    when -1 then :negative
    else :zero
    end
  end

  # Exact ahead/delay ratio, or nil when nothing is due yet (no defined ratio).
  def pct_ahead(actual:, expected:)
    return nil if expected.zero?

    same_currency!(actual, expected)
    Rational(actual.minor_units, expected.minor_units) - 1
  end

  # actual / target clamped to [0, 1], as an exact decimal string.
  def fraction_of_target(actual:, target:)
    same_currency!(actual, target)
    return actual.positive? ? "1" : "0" if target.minor_units.zero?

    fraction = Rational(actual.minor_units, target.minor_units)
    fraction = Rational(0) if fraction.negative?
    fraction = Rational(1) if fraction > 1
    decimal_string(fraction)
  end

  # Renders an exact terminating Rational as its shortest decimal string
  # ("1", "0.5"). Raises on a non-terminating fraction rather than rounding,
  # so money-shaped ratios never silently lose precision.
  def decimal_string(rational)
    rational = Rational(rational)
    return rational.numerator.to_s if rational.denominator == 1

    twos = factor_count(rational.denominator, 2)
    fives = factor_count(rational.denominator, 5)
    leftover = rational.denominator / (2**twos) / (5**fives)
    raise ArgumentError, "non-terminating decimal for #{rational}" unless leftover == 1

    digits = [ twos, fives ].max
    scaled = (rational * (10**digits)).to_i
    sign = scaled.negative? ? "-" : ""
    padded = scaled.abs.to_s.rjust(digits + 1, "0")
    whole = padded[0...-digits]
    fraction = padded[-digits..].sub(/0+\z/, "")
    fraction.empty? ? "#{sign}#{whole}" : "#{sign}#{whole}.#{fraction}"
  end

  def factor_count(value, factor)
    count = 0
    while (value % factor).zero?
      value /= factor
      count += 1
    end
    count
  end

  def same_currency!(left, right)
    return if left.currency == right.currency

    raise MoneyError::CurrencyMismatch.new(left.currency, right.currency)
  end
end
