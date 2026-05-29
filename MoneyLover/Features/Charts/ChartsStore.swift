import Foundation
import Observation

/// View state for the Charts screen: the four trend datasets plus the per-Envelope range switch.
@MainActor
@Observable
final class ChartsStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let ratesRepo: RatesRepository
    private let envelopesRepo: EnvelopeRepository
    private let goalsRepo: GoalRepository

    private(set) var balancePoints: [MonthPoint] = []
    private(set) var spendingPoints: [MonthPoint] = []
    private(set) var goals: [Goal] = []
    private(set) var envelopes: [Envelope] = []

    private var transactions: [Transaction] = []
    private var contributionsByGoal: [UUID: [Contribution]] = [:]
    private var earliest: Date?

    var range: ChartRange = .month
    var errorMessage: String?

    init(
        sources: SourceRepository,
        transactions: TransactionRepository,
        rates: RatesRepository,
        envelopes: EnvelopeRepository,
        goals: GoalRepository
    ) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.ratesRepo = rates
        self.envelopesRepo = envelopes
        self.goalsRepo = goals
    }

    func load() {
        do {
            let sources = try sourcesRepo.all()
            transactions = try transactionsRepo.all()
            let rates = try ratesRepo.snapshot()
            envelopes = try envelopesRepo.all()
            goals = try goalsRepo.all()
            contributionsByGoal = Dictionary(uniqueKeysWithValues: try goals.map {
                ($0.id, try goalsRepo.contributions(goalID: $0.id))
            })
            earliest = transactions.map(\.date).min()

            balancePoints = TrendEngine.balanceTrend(sources: sources, transactions: transactions, rates: rates, asOf: .now)
            spendingPoints = TrendEngine.spendingTrend(transactions: transactions, asOf: .now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Per-Envelope spending for the selected range, or a refusal when history is too short.
    func bucketSpending() -> SpendingChartOutcome {
        SpendingBucketEngine.spending(
            range: range,
            envelopes: envelopes,
            transactions: transactions,
            asOf: .now,
            earliest: earliest
        )
    }

    /// Cumulative saving trend for a goal over the last six months.
    func savingPoints(for goal: Goal) -> [MonthPoint] {
        TrendEngine.savingTrend(contributions: contributionsByGoal[goal.id] ?? [], asOf: .now)
    }
}
