import Testing
@testable import MoneyLover

@Suite struct AppInfoTests {
    @Test func formatComposesNameVersionAndBuild() {
        #expect(AppInfo.format(version: "0.2.0", build: "2") == "Money Lover 0.2.0 (2)")
    }

    @Test func formatHandlesArbitrarySemver() {
        #expect(AppInfo.format(version: "1.10.3", build: "47") == "Money Lover 1.10.3 (47)")
    }
}
