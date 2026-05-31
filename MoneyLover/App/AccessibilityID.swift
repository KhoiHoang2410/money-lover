import Foundation

/// Stable accessibility identifiers for UI automation. Shared between the app target and the
/// `MoneyLoverUITests` target so the test code references the same constants the views set —
/// no magic strings, no drift. Identifiers are namespaced `screen.element` and, where a view is
/// repeated per model, suffixed with a stable key (e.g. a source/goal name).
///
/// Best practice: every element a test drives carries a unique identifier independent of its
/// visible label, locale, or layout — so tests survive copy and design changes.
enum A11y {
    enum Tab {
        static let overview = "tab.overview"
        static let goals = "tab.goals"
        static let calendar = "tab.calendar"
        static let input = "tab.input"
        static let config = "tab.config"
    }

    enum Overview {
        static let netWorth = "overview.netWorth"
        static let asset = "overview.asset"
        static let debt = "overview.debt"
        static let censorToggle = "overview.censorToggle"
        static func sourceRow(_ name: String) -> String { "overview.source.\(name)" }
        static func goalRow(_ name: String) -> String { "overview.goalAsset.\(name)" }
    }

    enum Input {
        static let addTransaction = "input.addTransaction"
        static let voice = "input.voice"
        static let reconcile = "input.reconcile"
        static let backfill = "input.backfill"
    }

    enum Txn {
        static let typePicker = "txn.typePicker"
        static let amount = "txn.amount"
        static let amountIn = "txn.amountIn"
        static let rate = "txn.rate"
        static let source = "txn.source"
        static let destination = "txn.destination"
        static let envelope = "txn.envelope"
        static let method = "txn.method"
        static let note = "txn.note"
        static let save = "txn.save"
    }

    enum Reconcile {
        static func field(_ name: String) -> String { "reconcile.field.\(name)" }
        static let envelope = "reconcile.envelope"
        static let note = "reconcile.note"
        static let record = "reconcile.record"
    }

    enum Goals {
        static let add = "goals.add"
        static func ring(_ name: String) -> String { "goals.ring.\(name)" }
        static let detailContribute = "goalDetail.contribute"
        static let contributionAmount = "contribution.amount"
        static let contributionAccount = "contribution.account"
        static let contributionSave = "contribution.save"
    }

    enum Config {
        static let sources = "config.sources"
        static let envelopes = "config.envelopes"
        static let rates = "config.rates"
        static let monthEnd = "config.monthEnd"
        static let charts = "config.charts"
        static let advice = "config.advice"
        static let appearance = "config.appearance"
        static let seedSample = "config.seedSample"
        static let clearData = "config.clearData"
        static let version = "config.version"
    }

    enum Calendar {
        static func day(_ day: Int) -> String { "calendar.day.\(day)" }
        static let monthLabel = "calendar.monthLabel"
        static let prevMonth = "calendar.prevMonth"
        static let nextMonth = "calendar.nextMonth"
    }
}
