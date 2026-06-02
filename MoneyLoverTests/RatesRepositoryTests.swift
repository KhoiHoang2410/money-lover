import Testing
import Foundation
import SwiftData
@testable import MoneyLover

@MainActor
@Suite struct RatesRepositoryTests {
    private func makeRepo() -> RatesRepository {
        let container = try! ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return RatesRepository(context: ModelContext(container))
    }

    private let at = Date(timeIntervalSince1970: 1_700_000_000) // fixed; timestamps aren't asserted

    // TC-19-02 / TC-19-04: a manual override beats a later successful fetch.
    @Test func manualOverrideBeatsFetch() throws {
        let repo = makeRepo()
        try repo.upsert(key: "fx.SGD", value: 19_000, isManual: true, fetchedAt: at)
        try repo.saveFetched(
            Rates(fx: [.vnd: 1, .sgd: 18_500], goldPerChi: 0, stock: [:]),
            at: at
        )
        #expect(try repo.snapshot().fx[.sgd] == 19_000) // override preserved, fetch ignored
    }

    // TC-19-04: clearing the override (re-upsert with isManual: false) reverts to the fetched rate.
    @Test func clearingOverrideRevertsToFetched() throws {
        let repo = makeRepo()
        try repo.upsert(key: "fx.SGD", value: 19_000, isManual: true, fetchedAt: at)
        try repo.upsert(key: "fx.SGD", value: 19_000, isManual: false, fetchedAt: at) // clear override
        try repo.saveFetched(
            Rates(fx: [.vnd: 1, .sgd: 18_700], goldPerChi: 0, stock: [:]),
            at: at
        )
        #expect(try repo.snapshot().fx[.sgd] == 18_700) // fetch now applies
    }

    // A non-overridden key updates normally on saveFetched.
    @Test func nonOverriddenKeyUpdatesOnFetch() throws {
        let repo = makeRepo()
        try repo.saveFetched(
            Rates(fx: [.vnd: 1, .usd: 25_000], goldPerChi: 0, stock: [:]),
            at: at
        )
        #expect(try repo.snapshot().fx[.usd] == 25_000)

        try repo.saveFetched(
            Rates(fx: [.vnd: 1, .usd: 25_800], goldPerChi: 0, stock: [:]),
            at: at
        )
        #expect(try repo.snapshot().fx[.usd] == 25_800) // re-fetched value applied
    }
}
