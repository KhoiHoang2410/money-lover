import Testing
import Foundation
@testable import MoneyLover

@Suite struct ValuatorTests {
    private let rates = Rates(
        fx: [.vnd: 1, .usd: 25_500, .sgd: 18_500],
        goldPerChi: 15_950_000,
        stock: ["FPT": 72_000]
    )

    private func source(_ kind: SourceKind, _ currency: Currency, holding: HoldingInfo? = nil) -> Source {
        Source(name: "x", kind: kind, currency: currency, openingBalance: .zero(currency), iconName: "x", holding: holding)
    }

    @Test func vndAccountIsIdentity() {
        let value = Valuator.valueInVND(source: source(.account, .vnd), balance: Money(minorUnits: 80_000_000, currency: .vnd), rates: rates)
        #expect(value == Money(minorUnits: 80_000_000, currency: .vnd))
    }

    @Test func usdAccountConvertsByFX() {
        // $1,100 × 25,500 = ₫28,050,000
        let value = Valuator.valueInVND(source: source(.account, .usd), balance: Money(minorUnits: 1_100_00, currency: .usd), rates: rates)
        #expect(value == Money(minorUnits: 28_050_000, currency: .vnd))
    }

    @Test func goldInChiUsesPricePerChi() {
        let gold = source(.holding, .vnd, holding: HoldingInfo(quantity: 5, unit: .chi))
        // 5 × 15,950,000 = ₫79,750,000
        #expect(Valuator.valueInVND(source: gold, balance: .zero(.vnd), rates: rates) == Money(minorUnits: 79_750_000, currency: .vnd))
    }

    @Test func goldInLuongMultipliesByTen() {
        let gold = source(.holding, .vnd, holding: HoldingInfo(quantity: 1, unit: .luong))
        // 1 lượng = 10 chỉ × 15,950,000 = ₫159,500,000
        #expect(Valuator.valueInVND(source: gold, balance: .zero(.vnd), rates: rates) == Money(minorUnits: 159_500_000, currency: .vnd))
    }

    @Test func stockUsesPricePerShare() {
        let stock = source(.holding, .vnd, holding: HoldingInfo(quantity: 500, unit: .shares, ticker: "FPT"))
        #expect(Valuator.valueInVND(source: stock, balance: .zero(.vnd), rates: rates) == Money(minorUnits: 36_000_000, currency: .vnd))
    }

    @Test func creditCardDebtStaysNegativeInVND() {
        let value = Valuator.valueInVND(source: source(.creditCard, .vnd), balance: Money(minorUnits: -18_300_000, currency: .vnd), rates: rates)
        #expect(value == Money(minorUnits: -18_300_000, currency: .vnd))
        #expect(value.isNegative)
    }
}
