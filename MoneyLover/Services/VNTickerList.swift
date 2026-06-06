import Foundation

/// Loads the bundled list of selectable HOSE/HNX stock symbols (ADR-0001: offline, refreshed by
/// app update). Decoded once and cached.
enum VNTickerList {
    /// All bundled tickers, sorted by symbol. Empty if the resource is missing or malformed.
    static let all: [VNTicker] = load()

    /// Tickers whose symbol or company name contains `query` (case-insensitive). Empty query → all.
    static func matching(_ query: String) -> [VNTicker] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        let needle = trimmed.lowercased()
        return all.filter {
            $0.symbol.lowercased().contains(needle) || $0.name.lowercased().contains(needle)
        }
    }

    private static func load() -> [VNTicker] {
        guard let url = Bundle.main.url(forResource: "vn-tickers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tickers = try? JSONDecoder().decode([VNTicker].self, from: data)
        else { return [] }
        return tickers.sorted { $0.symbol < $1.symbol }
    }
}
