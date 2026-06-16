import Foundation

/// Fetches live conversion rates. Implemented live by `LivePriceProvider`; faked in tests.
protocol PriceProviding: Sendable {
    /// Fetches FX (USD/SGD→VND), SJC gold per chỉ, and the given HOSE tickers.
    func fetchRates(tickers: [String]) async -> Rates
}
