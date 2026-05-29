#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only sample data for previews and manual testing. Never compiled into release builds.
enum SampleData {
    @MainActor
    static func seed(into context: ModelContext) {
        let sourcesRepo = SourceRepository(context: context)
        let transactionsRepo = TransactionRepository(context: context)
        let envelopesRepo = EnvelopeRepository(context: context)
        let ratesRepo = RatesRepository(context: context)
        let goalsRepo = GoalRepository(context: context)

        // Idempotent: only seed an empty store.
        guard let existing = try? sourcesRepo.all(), existing.isEmpty else { return }

        func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }

        do {
            // Sources
            let mb = Source(name: "MBBank", kind: .account, currency: .vnd, openingBalance: vnd(80_000_000), iconName: "banknote.fill", logoAsset: "mbbank")
            let vp = Source(name: "VPBank", kind: .account, currency: .vnd, openingBalance: vnd(12_500_000), iconName: "banknote.fill", logoAsset: "vpbank")
            let vib = Source(name: "VIB", kind: .account, currency: .vnd, openingBalance: vnd(3_200_000), iconName: "banknote.fill", logoAsset: "vib")
            let wiseSGD = Source(name: "Wise SGD", kind: .account, currency: .sgd, openingBalance: Money(minorUnits: 2_400_00, currency: .sgd), iconName: "globe", logoAsset: "wise")
            let wiseUSD = Source(name: "Wise USD", kind: .account, currency: .usd, openingBalance: Money(minorUnits: 1_100_00, currency: .usd), iconName: "globe", logoAsset: "wise")
            let cash = Source(name: "Cash", kind: .account, currency: .vnd, openingBalance: vnd(1_500_000), iconName: "wallet.bifold.fill")
            let gold = Source(name: "Gold SJC", kind: .holding, currency: .vnd, openingBalance: .zero(.vnd), iconName: "seal.fill", holding: HoldingInfo(quantity: 5, unit: .chi))
            let fpt = Source(name: "FPT", kind: .holding, currency: .vnd, openingBalance: .zero(.vnd), iconName: "chart.line.uptrend.xyaxis", holding: HoldingInfo(quantity: 500, unit: .shares, ticker: "FPT"))
            let vpCredit = Source(name: "VPBank Credit", kind: .creditCard, currency: .vnd, openingBalance: vnd(-18_300_000), iconName: "creditcard.fill")
            let mbCredit = Source(name: "MBBank Credit", kind: .creditCard, currency: .vnd, openingBalance: vnd(-4_000_000), iconName: "creditcard.fill")
            for source in [mb, vp, vib, wiseSGD, wiseUSD, cash, gold, fpt, vpCredit, mbCredit] {
                try sourcesRepo.add(source)
            }

            // Envelopes (+ Reserve)
            let food = Envelope(name: "Food", iconName: "fork.knife", allocation: vnd(5_000_000))
            let rent = Envelope(name: "Rent", iconName: "house.fill", allocation: vnd(8_000_000))
            let transport = Envelope(name: "Transport", iconName: "car.fill", allocation: vnd(2_000_000))
            let fun = Envelope(name: "Fun", iconName: "sparkles", allocation: vnd(7_000_000))
            let reserve = Envelope(name: "Reserve", iconName: "star.fill", allocation: .zero(.vnd), carried: vnd(23_000_000), isReserve: true)
            for envelope in [food, rent, transport, fun, reserve] {
                try envelopesRepo.add(envelope)
            }

            // Rates (so valuation works offline)
            try ratesRepo.upsert(key: "fx.USD", value: 25_500, isManual: false, fetchedAt: .now)
            try ratesRepo.upsert(key: "fx.SGD", value: 18_500, isManual: false, fetchedAt: .now)
            try ratesRepo.upsert(key: "gold", value: 15_950_000, isManual: false, fetchedAt: .now)
            try ratesRepo.upsert(key: "stock.FPT", value: 72_000, isManual: false, fetchedAt: .now)

            // Transactions (recent, so the Calendar shows activity)
            let cal = Calendar.current
            func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: .now) ?? .now }
            try transactionsRepo.add(Transaction(date: daysAgo(20), kind: .income, amount: vnd(80_000_000), sourceID: mb.id, note: "Salary"))
            try transactionsRepo.add(Transaction(date: daysAgo(12), kind: .expense, amount: vnd(40_000), sourceID: vpCredit.id, note: "Bánh mì · 2 người", envelopeID: food.id))
            try transactionsRepo.add(Transaction(date: daysAgo(8), kind: .expense, amount: vnd(960_000), sourceID: vpCredit.id, note: "Groceries", envelopeID: food.id))
            try transactionsRepo.add(Transaction(date: daysAgo(5), kind: .expense, amount: vnd(2_300_000), sourceID: mb.id, note: "Grab + fuel", envelopeID: transport.id))
            try transactionsRepo.add(Transaction(date: daysAgo(3), kind: .expense, amount: vnd(3_100_000), sourceID: vpCredit.id, note: "Concert", envelopeID: fun.id))
            try transactionsRepo.add(Transaction(date: daysAgo(2), kind: .transfer, amount: vnd(18_300_000), sourceID: mb.id, destinationID: vpCredit.id, note: "Pay card"))

            // Goals + contributions
            func sched(_ y: Int, _ m: Int, _ millions: Int) -> ScheduledContribution {
                ScheduledContribution(year: y, month: m, amount: vnd(millions * 1_000_000))
            }
            let house = Goal(name: "House", iconName: "house.fill", target: vnd(3_000_000_000), targetDate: daysAgo(-365),
                             schedule: [sched(2026,1,100), sched(2026,2,100), sched(2026,3,100), sched(2026,5,150), sched(2026,7,100), sched(2026,8,100), sched(2026,9,100)])
            let car = Goal(name: "Car", iconName: "car.fill", target: vnd(600_000_000), targetDate: daysAgo(-365),
                           schedule: (1...12).map { sched(2026, $0, 25) })
            let travel = Goal(name: "Travel", iconName: "airplane", target: vnd(80_000_000), targetDate: daysAgo(-200),
                              schedule: (1...8).map { sched(2026, $0, 10) })
            for goal in [house, car, travel] { try goalsRepo.add(goal) }
            try goalsRepo.addContribution(goalID: house.id, amount: vnd(320_000_000), date: daysAgo(10))
            try goalsRepo.addContribution(goalID: car.id, amount: vnd(120_000_000), date: daysAgo(10))
            try goalsRepo.addContribution(goalID: travel.id, amount: vnd(62_000_000), date: daysAgo(10))
        } catch {
            print("SampleData seed failed: \(error)")
        }
    }

    @MainActor
    static func clear(into context: ModelContext) {
        try? context.delete(model: TransactionRecord.self)
        try? context.delete(model: SourceRecord.self)
        try? context.delete(model: EnvelopeRecord.self)
        try? context.delete(model: RateRecord.self)
        try? context.delete(model: ContributionRecord.self)
        try? context.delete(model: GoalRecord.self)
        try? context.save()
    }
}
#endif
