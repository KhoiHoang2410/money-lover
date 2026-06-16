import Testing
import Foundation
@testable import MoneyLover

/// Feat — export/import. The `DataBackup` payload encodes to JSON and decodes back identically, so a
/// file written on one device restores faithfully on another.
@Suite struct DataBackupTests {
    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func sample() -> DataBackup {
        let account = makeSource(name: "MBBank", currency: .vnd, opening: vnd(80_000_000))
        let gold = makeSource(name: "Gold", kind: .holding, currency: .vnd,
                              holding: HoldingInfo(quantity: 5, unit: .chi))
        let food = Envelope(name: "Food", iconName: "fork.knife", allocation: vnd(5_000_000),
                            weeklyCap: vnd(300_000), monthlyCap: vnd(1_200_000))
        let expense = makeExpense(vnd(40_000), source: account.id, envelope: food.id, date: date(2026, 6, 2))
        let goal = makeGoal(target: vnd(80_000_000), startMonth: ym(2026, 1), endMonth: ym(2026, 8),
                            schedule: [sched(2026, 1, vnd(10_000_000))])
        let rate = DataBackup.Rate(key: "gold", value: 15_950_000, isManual: false, fetchedAt: date(2026, 6, 1))
        return DataBackup(
            exportedAt: date(2026, 6, 6),
            sources: [account, gold],
            transactions: [expense],
            envelopes: [food],
            goals: [goal],
            rates: [rate]
        )
    }

    @Test func roundTripsThroughJSON() throws {
        let backup = sample()
        let data = try encoder.encode(backup)
        let restored = try decoder.decode(DataBackup.self, from: data)
        #expect(restored == backup)
    }

    @Test func carriesAllRecords() throws {
        let restored = try decoder.decode(DataBackup.self, from: try encoder.encode(sample()))
        #expect(restored.version == DataBackup.currentVersion)
        #expect(restored.sources.count == 2)
        #expect(restored.transactions.count == 1)
        #expect(restored.envelopes.first?.weeklyCap == vnd(300_000))
        #expect(restored.goals.first?.schedule.count == 1)
        #expect(restored.rates.first?.key == "gold")
    }
}
