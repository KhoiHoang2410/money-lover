module Api
  # Read-only net-worth and report-data API (issue 18). Every figure is derived
  # on read from the caller's own rows (Tenancy) by the pure engines — nothing is
  # stored — so the ledger stays the single source of truth and another user's
  # data is structurally unreachable. All money is integer minor units in the
  # base currency VND (ADR-0015); responses conform to the OpenAPI contract.
  #
  #   - `net_worth`             — asset / debt / net (NetWorthEngine).
  #   - `spending_trends`       — Σ Expenses per month over a date range.
  #   - `envelope_distribution` — per-Envelope spent for a month (BudgetEngine).
  #   - `goal_progress`         — per-Goal balance / target / expected (GoalTracker).
  #   - `net_worth_history`     — net worth at each month-end over a date range.
  class ReportsController < BaseController
    # GET /api/net_worth
    def net_worth
      result = NetWorthReport.compute(
        sources: sources, goals: goals, transactions: transactions,
        rates: rates, as_of: as_of
      )
      render json: { asset: money(result.asset), debt: money(result.debt), net: money(result.net) }
    end

    # GET /api/reports/spending_trends?from=YYYY-MM-DD&to=YYYY-MM-DD
    def spending_trends
      range = validate_range!
      expenses = transactions.select { |t| t.kind == Transaction::EXPENSE && in_range?(t, range) }

      totals = Hash.new { |h, k| h[k] = Money.zero(:VND) }
      expenses.each { |t| totals[month_key(t.occurred_on)] = totals[month_key(t.occurred_on)].add(to_vnd(t.amount)) }

      months = each_month(range[:from], range[:to]).map do |first|
        { month: month_label(first), spent: money(totals[month_key(first)]) }
      end
      render json: { from: range[:from].iso8601, to: range[:to].iso8601, currency: "VND", months: months }
    end

    # GET /api/reports/envelope_distribution?month=YYYY-MM
    def envelope_distribution
      first = validate_month!
      budget_txns = month_budget_txns(first)

      lines = envelopes.map do |envelope|
        spent = BudgetEngine.spent(envelope_id: envelope.id, transactions: budget_txns, currency: envelope.currency)
        { id: envelope.id, name: envelope.name, spent: money(spent) }
      end
      total = Money.sum(lines.map { |l| Money.new(minor_units: l[:spent][:amount_minor], currency: :VND) }, currency: :VND)
      render json: { month: month_label(first), total: money(total), envelopes: lines }
    end

    # GET /api/reports/goal_progress
    def goal_progress
      lines = goals.map do |goal|
        presenter = GoalPresenter.new(goal, transactions: transactions, as_of: as_of)
        progress = presenter.progress
        {
          id: goal.id,
          name: presenter.name,
          balance: money(presenter.balance),
          target: money(presenter.target),
          expected: money(progress.expected),
          fraction_of_target: progress.fraction_of_target
        }
      end
      render json: { goals: lines }
    end

    # GET /api/reports/net_worth_history?from=YYYY-MM-DD&to=YYYY-MM-DD
    def net_worth_history
      range = validate_range!
      points = each_month(range[:from], range[:to]).map do |first|
        cutoff = first.end_of_month
        as_of_txns = transactions.select { |t| t.occurred_on <= cutoff }
        result = NetWorthReport.compute(
          sources: sources, goals: goals, transactions: as_of_txns, rates: rates, as_of: cutoff
        )
        { month: month_label(first), asset: money(result.asset), debt: money(result.debt), net: money(result.net) }
      end
      render json: { from: range[:from].iso8601, to: range[:to].iso8601, points: points }
    end

    private

    def sources
      @sources ||= tenant_scope(:sources).order(:id).to_a
    end

    def goals
      @goals ||= tenant_scope(:goals).order(:id).to_a
    end

    def transactions
      @transactions ||= tenant_scope(:transactions).to_a
    end

    def envelopes
      @envelopes ||= tenant_scope(:envelopes).includes(:allocations).order(:id).to_a
    end

    def rates
      @rates ||= RateService.resolved_rates(current_user)
    end

    # "Today" in the User's timezone (CONTEXT.md): timezone defines month
    # boundaries and "today" for the report aggregates.
    def as_of
      zone.today
    end

    def zone
      ActiveSupport::TimeZone[current_user.timezone] || ActiveSupport::TimeZone["UTC"]
    end

    # Serializes a `Money` to the contract's MoneyMinorUnits shape.
    def money(value)
      { amount_minor: value.minor_units, currency: value.currency.to_s }
    end

    # Values any `Money` in VND: the identity for VND, else converted via the
    # resolved FX rate (a missing rate degrades to ₫0, never raises — ADR-0015).
    def to_vnd(value)
      NetWorthEngine.to_vnd(value, rates)
    end

    def in_range?(txn, range)
      txn.occurred_on >= range[:from] && txn.occurred_on <= range[:to]
    end

    def month_key(date)
      [ date.year, date.month ]
    end

    def month_label(date)
      format("%04d-%02d", date.year, date.month)
    end

    # The first day of each month from `from` through `to`, inclusive.
    def each_month(from, to)
      months = []
      cursor = from.beginning_of_month
      last = to.beginning_of_month
      while cursor <= last
        months << cursor
        cursor = cursor.next_month
      end
      months
    end

    # The caller's Expenses in `first`'s month, as BudgetEngine value objects.
    def month_budget_txns(first)
      window = first.beginning_of_month..first.end_of_month
      transactions.select { |t| window.cover?(t.occurred_on) }.map do |t|
        BudgetEngine::Transaction.build(
          kind: t.kind, amount: t.amount, source_id: t.source_id, envelope_id: t.envelope_id
        )
      end
    end

    def validate_range!
      result = Reports::RangeContract.new.call(params.permit(:from, :to).to_h)
      return result.to_h if result.success?

      raise ApiError::Validation.new("Report range is invalid.", details: result.errors.to_h)
    end

    def validate_month!
      result = Reports::MonthContract.new.call(params.permit(:month).to_h)
      raise ApiError::Validation.new("Report month is invalid.", details: result.errors.to_h) unless result.success?

      month = result.to_h[:month]
      return MonthWindow.current_first_of_month(current_user.timezone) if month.nil?

      Date.strptime(month, "%Y-%m")
    end
  end
end
