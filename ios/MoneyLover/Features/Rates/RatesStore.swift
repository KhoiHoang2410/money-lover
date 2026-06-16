import Foundation
import Observation

/// View state for the Rates feature: cached/overridden rate rows, refresh, and manual override.
@MainActor
@Observable
final class RatesStore {
    private let repo: RatesRepository
    private let provider: PriceProviding
    private let tickers: [String]
    private(set) var records: [RateRecord] = []
    var isRefreshing = false
    var errorMessage: String?

    init(repo: RatesRepository, provider: PriceProviding, tickers: [String]) {
        self.repo = repo
        self.provider = provider
        self.tickers = tickers
    }

    func load() {
        do {
            records = try repo.records()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        let rates = await provider.fetchRates(tickers: tickers)
        do {
            try repo.saveFetched(rates, at: .now)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setManual(key: String, value: Decimal) {
        do {
            try repo.upsert(key: key, value: value, isManual: true, fetchedAt: .now)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
