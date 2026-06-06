import Testing
import Foundation
@testable import MoneyLover

/// The bundled HOSE/HNX symbol list decodes and the search filter works (ADR-0001: offline list).
@Suite struct VNTickerListTests {
    @Test func bundledListLoadsAndIsSorted() {
        let all = VNTickerList.all
        #expect(!all.isEmpty)
        #expect(all == all.sorted { $0.symbol < $1.symbol })
    }

    @Test func emptyQueryReturnsEverything() {
        #expect(VNTickerList.matching("  ").count == VNTickerList.all.count)
    }

    @Test func matchesSymbolCaseInsensitively() {
        let hits = VNTickerList.matching("fpt")
        #expect(hits.contains { $0.symbol == "FPT" })
    }

    @Test func matchesCompanyName() {
        let hits = VNTickerList.matching("vinamilk")
        #expect(hits.contains { $0.symbol == "VNM" })
    }

    @Test func unknownQueryReturnsNothing() {
        #expect(VNTickerList.matching("zzzznotreal").isEmpty)
    }
}
