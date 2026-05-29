import Foundation

/// One planned contribution toward a Goal in a specific calendar month.
struct ScheduledContribution: Hashable, Sendable, Codable, Identifiable {
    var id: UUID
    var year: Int
    var month: Int   // 1...12
    var amount: Money

    init(id: UUID = UUID(), year: Int, month: Int, amount: Money) {
        self.id = id
        self.year = year
        self.month = month
        self.amount = amount
    }
}
