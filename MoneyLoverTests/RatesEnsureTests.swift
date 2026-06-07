import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// Feat — auto-seeding rates. `ensure` inserts a ₫0 placeholder for any missing key (so a new
/// foreign Account or Holding shows on the Rates screen) without disturbing existing values.
@MainActor
@Suite struct RatesEnsureTests {
    private func makeRepo() -> RatesRepository {
        let container = try! ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return RatesRepository(context: ModelContext(container))
    }

    private let at = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func insertsPlaceholdersForMissingKeys() throws {
        let repo = makeRepo()
        try repo.ensure(keys: ["fx.USD", "gold"])
        let snapshot = try repo.snapshot()
        #expect(snapshot.fx[.usd] == 0)
        #expect(snapshot.goldPerChi == 0)
    }

    @Test func leavesExistingValuesUntouched() throws {
        let repo = makeRepo()
        try repo.upsert(key: "gold", value: 15_950_000, isManual: true, fetchedAt: at)
        try repo.ensure(keys: ["gold", "fx.SGD"]) // gold already present; only SGD is added
        #expect(try repo.snapshot().goldPerChi == 15_950_000) // not overwritten with ₫0
        #expect(try repo.snapshot().fx[.sgd] == 0)            // new placeholder
    }

    @Test func emptyKeysIsNoOp() throws {
        let repo = makeRepo()
        try repo.ensure(keys: [])
        #expect(try repo.records().isEmpty)
    }
}
