import Foundation
import SwiftData

/// Stores cached/overridden rates and assembles a `Rates` snapshot for the Valuator.
@MainActor
final class RatesRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func records() throws -> [RateRecord] {
        try context.fetch(FetchDescriptor<RateRecord>(sortBy: [SortDescriptor(\.key)]))
    }

    /// Builds the rate snapshot used for valuation.
    func snapshot() throws -> Rates {
        var fx: [Currency: Decimal] = [.vnd: 1]
        var gold: Decimal = 0
        var stock: [String: Decimal] = [:]
        for record in try records() {
            switch record.key {
            case "fx.USD": fx[.usd] = record.value
            case "fx.SGD": fx[.sgd] = record.value
            case "gold": gold = record.value
            default:
                if record.key.hasPrefix("stock.") {
                    stock[String(record.key.dropFirst("stock.".count))] = record.value
                }
            }
        }
        return Rates(fx: fx, goldPerChi: gold, stock: stock)
    }

    /// Ensures a placeholder rate row exists for each key, so a newly-added foreign Account or
    /// Holding immediately shows up on the Rates screen for the owner to fill in or refresh. Existing
    /// keys (manual or fetched) are left untouched; missing ones are inserted at ₫0. Idempotent.
    func ensure(keys: [String], at date: Date = .now) throws {
        guard !keys.isEmpty else { return }
        let existing = Set(try records().map(\.key))
        let missing = keys.filter { !existing.contains($0) }
        guard !missing.isEmpty else { return }
        for key in missing {
            context.insert(RateRecord(key: key, value: 0, isManual: false, fetchedAt: date))
        }
        try context.save()
    }

    /// Upserts a single rate. Manual overrides are preserved unless `isManual` is set again.
    func upsert(key: String, value: Decimal, isManual: Bool, fetchedAt: Date) throws {
        let descriptor = FetchDescriptor<RateRecord>(predicate: #Predicate { $0.key == key })
        if let record = try context.fetch(descriptor).first {
            record.value = value
            record.isManual = isManual
            record.fetchedAt = fetchedAt
        } else {
            context.insert(RateRecord(key: key, value: value, isManual: isManual, fetchedAt: fetchedAt))
        }
        try context.save()
    }

    /// Saves freshly-fetched rates, but never overwrites a manual override.
    func saveFetched(_ rates: Rates, at date: Date) throws {
        let existing = Dictionary(uniqueKeysWithValues: try records().map { ($0.key, $0) })
        func put(_ key: String, _ value: Decimal) throws {
            if existing[key]?.isManual == true { return }
            try upsert(key: key, value: value, isManual: false, fetchedAt: date)
        }
        if let usd = rates.fx[.usd] { try put("fx.USD", usd) }
        if let sgd = rates.fx[.sgd] { try put("fx.SGD", sgd) }
        if rates.goldPerChi > 0 { try put("gold", rates.goldPerChi) }
        for (ticker, price) in rates.stock { try put("stock.\(ticker)", price) }
    }
}
