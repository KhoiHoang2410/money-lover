import Foundation

/// A portable, self-contained snapshot of all the owner's data — every Source, Transaction,
/// Envelope, Goal, and Rate — for export to a file and re-import later or on another device.
/// Pure and `Codable`, so the JSON shape is unit-tested without persistence. Dates encode as ISO-8601.
struct DataBackup: Codable, Equatable {
    /// Schema version of this payload, so a future import can migrate older files.
    var version: Int
    var exportedAt: Date
    var sources: [Source]
    var transactions: [Transaction]
    var envelopes: [Envelope]
    var goals: [Goal]
    var rates: [Rate]

    /// The current backup schema version.
    static let currentVersion = 1

    init(
        version: Int = DataBackup.currentVersion,
        exportedAt: Date,
        sources: [Source],
        transactions: [Transaction],
        envelopes: [Envelope],
        goals: [Goal],
        rates: [Rate]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.sources = sources
        self.transactions = transactions
        self.envelopes = envelopes
        self.goals = goals
        self.rates = rates
    }

    /// A single cached/overridden rate row, mirroring `RateRecord` (no SwiftData dependency).
    struct Rate: Codable, Equatable {
        var key: String
        var value: Decimal
        var isManual: Bool
        var fetchedAt: Date
    }
}
