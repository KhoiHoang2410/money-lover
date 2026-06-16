import Foundation

/// Live price provider hitting the ADR-0003 endpoints. Per-source failures degrade gracefully
/// (missing rates are simply absent); the caller keeps the last-known value.
struct LivePriceProvider: PriceProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRates(tickers: [String]) async -> Rates {
        var fx: [Currency: Decimal] = [.vnd: 1]
        if let usd = await fetchDecimal("https://open.er-api.com/v6/latest/USD", RatePayloadParser.fxToVND) {
            fx[.usd] = usd
        }
        if let sgd = await fetchDecimal("https://open.er-api.com/v6/latest/SGD", RatePayloadParser.fxToVND) {
            fx[.sgd] = sgd
        }
        let gold = await fetchDecimal("https://edge-api.pnj.io/ecom-frontend/v1/get-gold-price?zone=00", RatePayloadParser.sjcGoldPerChi) ?? 0

        var stock: [String: Decimal] = [:]
        for ticker in tickers {
            let url = "https://dchart-api.vndirect.com.vn/dchart/history?symbol=\(ticker)&resolution=D&from=0&to=9999999999"
            if let price = await fetchDecimal(url, RatePayloadParser.stockLastClose) {
                stock[ticker] = price
            }
        }
        return Rates(fx: fx, goldPerChi: gold, stock: stock)
    }

    private func fetchDecimal(_ urlString: String, _ parse: @Sendable (Data) -> Decimal?) async -> Decimal? {
        guard let url = URL(string: urlString) else { return nil }
        guard let (data, _) = try? await session.data(from: url) else { return nil }
        return parse(data)
    }
}
