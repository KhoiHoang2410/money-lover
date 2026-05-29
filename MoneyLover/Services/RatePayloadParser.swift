import Foundation

/// Pure parsers for the three price endpoints (ADR-0003). Unit-tested against captured payloads.
enum RatePayloadParser {
    private struct ERAPIResponse: Decodable { let rates: [String: Decimal] }
    private struct PNJResponse: Decodable {
        struct Item: Decodable { let masp: String; let giaban: Decimal }
        let data: [Item]
    }
    private struct VNDChart: Decodable { let c: [Decimal] }

    /// open.er-api.com → VND per 1 unit of the base currency (reads `rates.VND`).
    static func fxToVND(_ data: Data) -> Decimal? {
        (try? JSONDecoder().decode(ERAPIResponse.self, from: data))?.rates["VND"]
    }

    /// PNJ gold feed → VND per chỉ for SJC (`giaban` is thousand-VND per chỉ ⇒ ×1000).
    static func sjcGoldPerChi(_ data: Data) -> Decimal? {
        guard let item = (try? JSONDecoder().decode(PNJResponse.self, from: data))?.data
            .first(where: { $0.masp == "SJC" }) else { return nil }
        return item.giaban * 1000
    }

    /// VNDirect dchart → VND per share (last close, in thousand-VND ⇒ ×1000).
    static func stockLastClose(_ data: Data) -> Decimal? {
        guard let last = (try? JSONDecoder().decode(VNDChart.self, from: data))?.c.last else { return nil }
        return last * 1000
    }
}
