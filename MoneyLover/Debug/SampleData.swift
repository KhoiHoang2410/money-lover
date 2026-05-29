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
            // Sources. Money accounts open at zero and get an explicit "Opening balance"
            // transaction below, so each account's history is non-empty and its balance still
            // resolves correctly (current = Σ transactions). Holdings value off quantity × rate.
            let mb = Source(name: "MBBank", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "banknote.fill", logoAsset: "mbbank")
            let vp = Source(name: "VPBank", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "banknote.fill", logoAsset: "vpbank")
            let vib = Source(name: "VIB", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "banknote.fill", logoAsset: "vib")
            let wiseSGD = Source(name: "Wise SGD", kind: .account, currency: .sgd, openingBalance: .zero(.sgd), iconName: "globe", logoAsset: "wise")
            let wiseUSD = Source(name: "Wise USD", kind: .account, currency: .usd, openingBalance: .zero(.usd), iconName: "globe", logoAsset: "wise")
            let cash = Source(name: "Cash", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "wallet.bifold.fill")
            let savings = Source(name: "Savings", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "banknote.fill")
            let gold = Source(name: "Gold SJC", kind: .holding, currency: .vnd, openingBalance: .zero(.vnd), iconName: "seal.fill", holding: HoldingInfo(quantity: 5, unit: .chi))
            let fpt = Source(name: "FPT", kind: .holding, currency: .vnd, openingBalance: .zero(.vnd), iconName: "chart.line.uptrend.xyaxis", holding: HoldingInfo(quantity: 500, unit: .shares, ticker: "FPT"))
            let vpCredit = Source(name: "VPBank Credit", kind: .creditCard, currency: .vnd, openingBalance: .zero(.vnd), iconName: "creditcard.fill")
            let mbCredit = Source(name: "MBBank Credit", kind: .creditCard, currency: .vnd, openingBalance: .zero(.vnd), iconName: "creditcard.fill")
            for source in [mb, vp, vib, wiseSGD, wiseUSD, cash, savings, gold, fpt, vpCredit, mbCredit] {
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

            let cal = Calendar.current
            let now = Date.now
            func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: now) ?? now }

            let comps = cal.dateComponents([.year, .month], from: now)
            let year = comps.year ?? 2026
            let month = comps.month ?? 1
            let monthStart = cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? now
            let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 30

            func dateOn(_ day: Int, hour: Int, minute: Int = 0) -> Date {
                cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? now
            }

            // Opening balances, materialised as one "Opening balance" adjustment per money account,
            // so every account has visible history and its balance still resolves correctly. Dated
            // to the start of the previous month: out of the current calendar month (so it doesn't
            // skew the day grid) but recent enough to show in the longer history ranges. Signed:
            // credit cards open negative (debt).
            let openingDate = cal.date(byAdding: .month, value: -1, to: monthStart) ?? daysAgo(40)
            let openings: [(Source, Money)] = [
                (mb, vnd(80_000_000)),
                (vp, vnd(12_500_000)),
                (vib, vnd(3_200_000)),
                (wiseSGD, Money(minorUnits: 2_400_00, currency: .sgd)),
                (wiseUSD, Money(minorUnits: 1_100_00, currency: .usd)),
                (cash, vnd(1_500_000)),
                (savings, vnd(520_000_000)),
                (vpCredit, vnd(-18_300_000)),
                (mbCredit, vnd(-4_000_000)),
            ]
            for (source, amount) in openings {
                try transactionsRepo.add(Transaction(date: openingDate, kind: .adjustment, amount: amount, sourceID: source.id, note: "Opening balance"))
            }

            // Recent multi-currency activity on the Wise accounts, so their history isn't just the
            // opening entry. These are foreign-currency (SGD/USD) and the calendar nets VND only,
            // so they don't appear in the day grid.
            try transactionsRepo.add(Transaction(date: daysAgo(1), kind: .expense, amount: Money(minorUnits: 32_00, currency: .sgd), sourceID: wiseSGD.id, note: "Grab SG", envelopeID: transport.id))
            try transactionsRepo.add(Transaction(date: daysAgo(3), kind: .expense, amount: Money(minorUnits: 58_00, currency: .sgd), sourceID: wiseSGD.id, note: "Hawker dinner", envelopeID: food.id))
            try transactionsRepo.add(Transaction(date: daysAgo(6), kind: .income, amount: Money(minorUnits: 500_00, currency: .sgd), sourceID: wiseSGD.id, note: "Contract payout"))
            try transactionsRepo.add(Transaction(date: daysAgo(2), kind: .expense, amount: Money(minorUnits: 12_99, currency: .usd), sourceID: wiseUSD.id, note: "Spotify + iCloud", envelopeID: fun.id))
            try transactionsRepo.add(Transaction(date: daysAgo(9), kind: .income, amount: Money(minorUnits: 300_00, currency: .usd), sourceID: wiseUSD.id, note: "Freelance USD"))
            let incomeAccounts = [mb, vp, cash]
            let incomeNotes = ["Freelance", "Refund", "Interest", "Side gig", "Cashback", "Bonus"]
            let expenseAccounts = [mb, vp, cash, vpCredit]
            let expenseEnvs = [food, transport, fun]
            let expenseNotes = ["Cà phê", "Lunch", "Groceries", "Grab", "Snacks", "Dinner", "Bánh mì", "Fuel", "Movie", "Coffee"]

            for day in 1...daysInMonth {
                // One guaranteed income and one guaranteed expense.
                try transactionsRepo.add(Transaction(
                    date: dateOn(day, hour: 9),
                    kind: .income,
                    amount: vnd(200_000 + (day % 5) * 180_000 + 150_000),
                    sourceID: incomeAccounts[day % incomeAccounts.count].id,
                    note: incomeNotes[day % incomeNotes.count]))
                try transactionsRepo.add(Transaction(
                    date: dateOn(day, hour: 12),
                    kind: .expense,
                    amount: vnd(35_000 + (day % 7) * 28_000 + 25_000),
                    sourceID: expenseAccounts[day % expenseAccounts.count].id,
                    note: expenseNotes[day % expenseNotes.count],
                    envelopeID: expenseEnvs[day % expenseEnvs.count].id))

                // Extra entries on selected days (day 15 → 15 total; weekly markers → 5 total).
                let extra = day == 15 ? 13 : (day % 7 == 0 ? 3 : 0)
                for i in 0..<extra {
                    let isIncome = i % 3 == 2
                    if isIncome {
                        try transactionsRepo.add(Transaction(
                            date: dateOn(day, hour: 14, minute: i * 3),
                            kind: .income,
                            amount: vnd(120_000 + i * 60_000),
                            sourceID: incomeAccounts[i % incomeAccounts.count].id,
                            note: incomeNotes[i % incomeNotes.count]))
                    } else {
                        try transactionsRepo.add(Transaction(
                            date: dateOn(day, hour: 15, minute: i * 3),
                            kind: .expense,
                            amount: vnd(45_000 + i * 40_000),
                            sourceID: expenseAccounts[i % expenseAccounts.count].id,
                            note: expenseNotes[i % expenseNotes.count],
                            envelopeID: expenseEnvs[i % expenseEnvs.count].id))
                    }
                }
            }

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

            // Spread the funding across the current month from different accounts, so each goal's
            // progress (and its contribution history) is visibly distinct: House early-stage (~12%),
            // Car mid (~20%), Travel nearly funded (~79%).
            let clamp = { (day: Int) in min(day, daysInMonth) }
            try goalsRepo.addContribution(goalID: house.id, amount: vnd(320_000_000), fromAccountID: savings.id, date: dateOn(clamp(3), hour: 10), note: "→ House")
            try goalsRepo.addContribution(goalID: house.id, amount: vnd(40_000_000), fromAccountID: mb.id, date: dateOn(clamp(22), hour: 10), note: "→ House top-up")
            try goalsRepo.addContribution(goalID: car.id, amount: vnd(100_000_000), fromAccountID: savings.id, date: dateOn(clamp(5), hour: 10), note: "→ Car")
            try goalsRepo.addContribution(goalID: car.id, amount: vnd(20_000_000), fromAccountID: savings.id, date: dateOn(clamp(18), hour: 10), note: "→ Car top-up")
            try goalsRepo.addContribution(goalID: travel.id, amount: vnd(50_000_000), fromAccountID: savings.id, date: dateOn(clamp(8), hour: 10), note: "→ Travel")
            try goalsRepo.addContribution(goalID: travel.id, amount: vnd(8_000_000), fromAccountID: mb.id, date: dateOn(clamp(20), hour: 10), note: "→ Travel top-up")
            try goalsRepo.addContribution(goalID: travel.id, amount: vnd(5_000_000), fromAccountID: mb.id, date: dateOn(clamp(26), hour: 10), note: "→ Travel top-up")
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
        try? context.delete(model: GoalRecord.self)
        try? context.save()
    }
}
#endif
