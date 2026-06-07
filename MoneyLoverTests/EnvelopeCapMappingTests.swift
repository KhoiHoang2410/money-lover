import Testing
import Foundation
@testable import MoneyLover

/// Feat — envelope weekly/monthly caps survive the domain ⇄ record mapping (and stay nil when unset).
@Suite struct EnvelopeCapMappingTests {
    @Test func capsRoundTrip() {
        let envelope = Envelope(
            name: "Food", iconName: "fork.knife",
            allocation: vnd(5_000_000),
            weeklyCap: vnd(300_000),
            monthlyCap: vnd(1_200_000)
        )
        let record = EnvelopeRecord(domain: envelope)
        #expect(record.weeklyCapMinorUnits == 300_000)
        #expect(record.monthlyCapMinorUnits == 1_200_000)

        let restored = record.toDomain()
        #expect(restored.weeklyCap == vnd(300_000))
        #expect(restored.monthlyCap == vnd(1_200_000))
    }

    @Test func unsetCapsStayNil() {
        let envelope = Envelope(name: "Rent", iconName: "house.fill", allocation: vnd(8_000_000))
        let record = EnvelopeRecord(domain: envelope)
        #expect(record.weeklyCapMinorUnits == nil)
        #expect(record.monthlyCapMinorUnits == nil)
        #expect(record.toDomain().weeklyCap == nil)
        #expect(record.toDomain().monthlyCap == nil)
    }

    @Test func updatePersistsCapEdits() {
        let record = EnvelopeRecord(domain: Envelope(name: "Fun", iconName: "sparkles", allocation: vnd(7_000_000)))
        var edited = record.toDomain()
        edited.weeklyCap = vnd(500_000)
        edited.monthlyCap = nil
        record.update(from: edited)
        #expect(record.weeklyCapMinorUnits == 500_000)
        #expect(record.monthlyCapMinorUnits == nil)
    }
}
