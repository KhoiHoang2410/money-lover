# Read model for a Goal: wraps the persisted GoalRecord and runs the pure
# GoalTracker engine to expose the numbers the clients render — the live balance
# (Σ Contributions), Expected-by-today / ahead-delay progress, and per-line
# Schedule status + shortfall. Keeps the AR edge and the engine apart (ADR-0006):
# the controller builds one of these per goal and hands it to GoalRepresenter.
#
# "Today" is passed in as `as_of` (a Date already resolved in the User's timezone
# by the controller) so the engine stays clock-free.
class GoalPresenter
  # One Schedule line as rendered: the planned amount plus its cumulative status
  # and shortfall (GoalTracker), keyed back to the line's (year, month).
  Line = Struct.new(:year, :month, :planned, :status, :shortfall, keyword_init: true)

  # Adapter so an ActiveRecord Transaction quacks like the value object
  # GoalTracker.contributions expects (kind / amount / goal_id / date) — the
  # engine never sees ActiveRecord.
  Contribution = Struct.new(:kind, :amount, :goal_id, :date, keyword_init: true)

  # @param goal         [GoalRecord]
  # @param transactions [Array<Transaction>] the caller's ledger rows; the
  #   Contributions tagged with this goal are summed into its balance.
  # @param as_of        [Date] "today" in the User's timezone.
  def initialize(goal, transactions:, as_of:)
    @goal = goal
    @transactions = transactions
    @as_of = as_of
  end

  def id = @goal.id
  def name = @goal.name
  def icon = @goal.icon
  def currency = @goal.currency
  def target = @goal.target

  def start_month = domain.start_month
  def end_month = domain.end_month

  # The Goal's balance: the sum of its Contributions (CONTEXT.md), an Asset.
  def balance = contributed

  # Expected-by-today + the exact ahead/delay ratio and its sign (GoalTracker).
  def progress
    GoalTracker.progress(goal: domain, actual: contributed, as_of: @as_of)
  end

  # The Schedule lines decorated with their cumulative status + shortfall.
  # GoalTracker keys both hashes by the line's month number (its documented
  # contract, issue 11), so a Goal's Schedule carries distinct months per line.
  def schedule_lines
    statuses = GoalTracker.schedule_status(goal: domain, contributed: contributed, as_of: @as_of)
    shortfalls = GoalTracker.shortfalls(goal: domain, contributed: contributed)

    domain.schedule.map do |line|
      Line.new(
        year: line.year,
        month: line.month,
        planned: line.amount,
        status: statuses[line.month],
        shortfall: shortfalls[line.month]
      )
    end
  end

  private

  def domain = @domain ||= @goal.to_domain

  def contributed
    @contributed ||= GoalTracker.contributed(
      transactions: contribution_adapters,
      goal_id: @goal.id,
      currency: domain.currency
    )
  end

  def contribution_adapters
    @transactions.map do |txn|
      Contribution.new(kind: txn.kind, amount: txn.amount, goal_id: txn.goal_id, date: txn.occurred_on)
    end
  end
end
