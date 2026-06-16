import Testing
import Foundation
@testable import MoneyLover

/// Feat — adding a foreign Account or a gold/stock Holding seeds the rate keys it needs to value
/// in VND. `RateKeys` derives those keys purely.
@Suite struct RateKeysTests {
    @Test func vndAccountNeedsNoKey() {
        let source = makeSource(name: "Cash", kind: .account, currency: .vnd)
        #expect(RateKeys.required(for: source).isEmpty)
    }

    @Test func vndCreditCardNeedsNoKey() {
        let source = makeSource(name: "Card", kind: .creditCard, currency: .vnd)
        #expect(RateKeys.required(for: source).isEmpty)
    }

    @Test func foreignAccountNeedsFxKey() {
        let usd = makeSource(name: "Wise USD", kind: .account, currency: .usd)
        let sgd = makeSource(name: "Wise SGD", kind: .account, currency: .sgd)
        #expect(RateKeys.required(for: usd) == ["fx.USD"])
        #expect(RateKeys.required(for: sgd) == ["fx.SGD"])
    }

    @Test func goldHoldingNeedsGoldKey() {
        let gold = makeSource(name: "Gold", kind: .holding, currency: .vnd,
                              holding: HoldingInfo(quantity: 5, unit: .chi))
        #expect(RateKeys.required(for: gold) == ["gold"])
    }

    @Test func stockHoldingNeedsTickerKey() {
        let fpt = makeSource(name: "FPT", kind: .holding, currency: .vnd,
                             holding: HoldingInfo(quantity: 500, unit: .shares, ticker: "FPT"))
        #expect(RateKeys.required(for: fpt) == ["stock.FPT"])
    }
}
