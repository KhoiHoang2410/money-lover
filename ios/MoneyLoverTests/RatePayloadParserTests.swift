import Testing
import Foundation
@testable import MoneyLover

@Suite struct RatePayloadParserTests {
    @Test func parsesFXVND() throws {
        let json = #"{"result":"success","base_code":"USD","rates":{"USD":1,"VND":25500,"SGD":1.35}}"#
        let value = try #require(RatePayloadParser.fxToVND(Data(json.utf8)))
        #expect(value == Decimal(25_500))
    }

    @Test func parsesSJCGoldPerChi() throws {
        let json = #"{"data":[{"masp":"SJC","tensp":"Vàng miếng SJC","giaban":15950,"giamua":15650},{"masp":"N24K","giaban":15950,"giamua":15650}]}"#
        let value = try #require(RatePayloadParser.sjcGoldPerChi(Data(json.utf8)))
        #expect(value == Decimal(15_950_000)) // 15950 × 1000
    }

    @Test func parsesStockLastClose() throws {
        let json = #"{"t":[1,2,3],"c":[71.2,73.5,72.0],"o":[1,1,1]}"#
        let value = try #require(RatePayloadParser.stockLastClose(Data(json.utf8)))
        #expect(value == Decimal(72_000)) // 72.0 × 1000
    }

    @Test func malformedPayloadReturnsNil() {
        #expect(RatePayloadParser.fxToVND(Data("not json".utf8)) == nil)
        #expect(RatePayloadParser.sjcGoldPerChi(Data("{}".utf8)) == nil)
        #expect(RatePayloadParser.stockLastClose(Data(#"{"c":[]}"#.utf8)) == nil)
    }
}
