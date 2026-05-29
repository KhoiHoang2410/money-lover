import Foundation

/// An exact monetary amount, stored as integer minor units in a single currency.
/// Never use `Double`/`Float` for money — this type is the only representation.
struct Money: Hashable, Sendable, Codable {
    /// The amount in the currency's smallest unit (đồng for VND, cents for USD/SGD).
    let minorUnits: Int
    let currency: Currency

    init(minorUnits: Int, currency: Currency) {
        self.minorUnits = minorUnits
        self.currency = currency
    }

    /// Builds money from a major-unit amount (e.g. 40000 VND, 1.50 USD), rounding to minor units.
    init(major: Decimal, currency: Currency) {
        let scaled = (major * Decimal(currency.minorUnitScale)) as NSDecimalNumber
        self.minorUnits = scaled.rounding(accordingToBehavior: nil).intValue
        self.currency = currency
    }

    /// Zero in the given currency.
    static func zero(_ currency: Currency) -> Money {
        Money(minorUnits: 0, currency: currency)
    }

    /// The major-unit value as an exact `Decimal`, for display/formatting only.
    var amount: Decimal {
        Decimal(minorUnits) / Decimal(currency.minorUnitScale)
    }

    var isZero: Bool { minorUnits == 0 }
    var isNegative: Bool { minorUnits < 0 }

    /// Localized currency string, e.g. "₫40,000" or "$1.00".
    var formatted: String {
        amount.formatted(.currency(code: currency.rawValue))
    }

    func adding(_ other: Money) throws -> Money {
        try requireSameCurrency(other)
        return Money(minorUnits: minorUnits + other.minorUnits, currency: currency)
    }

    func subtracting(_ other: Money) throws -> Money {
        try requireSameCurrency(other)
        return Money(minorUnits: minorUnits - other.minorUnits, currency: currency)
    }

    var negated: Money {
        Money(minorUnits: -minorUnits, currency: currency)
    }

    private func requireSameCurrency(_ other: Money) throws {
        guard currency == other.currency else {
            throw MoneyError.currencyMismatch(currency, other.currency)
        }
    }
}
