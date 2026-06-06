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
        // Invest (Buy/Sell of a Holding), ADR-0010.
        static let tradeDirection = "txn.tradeDirection"
        static let holding = "txn.holding"
        static let quantity = "txn.quantity"
        static let unitPrice = "txn.unitPrice"
        static let date = "txn.date"
        static let delete = "txn.delete"
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

    enum Source {
        static let add = "source.add"
        static let openingBalance = "source.openingBalance"
    }

    enum Holding {
        static let add = "holding.add"
        static let assetType = "holding.assetType"
        static let quantity = "holding.quantity"
        static let unit = "holding.unit"
        static let stockPicker = "holding.stockPicker"
        static let save = "holding.save"
        /// The live VND value on a holding row, keyed by name.
        static func value(_ name: String) -> String { "holding.value.\(name)" }
    }

    enum Config {
        static let sources = "config.sources"
        static let holdings = "config.holdings"
        static let envelopes = "config.envelopes"
        static let rates = "config.rates"
        static let monthEnd = "config.monthEnd"
        static let charts = "config.charts"
        static let advice = "config.advice"
        static let appearance = "config.appearance"
        static let confirmDelete = "config.confirmDelete"
        static let seedSample = "config.seedSample"
        static let clearData = "config.clearData"
        static let version = "config.version"
    }

    enum Calendar {
        static func day(_ day: Int) -> String { "calendar.day.\(day)" }
        static let monthLabel = "calendar.monthLabel"
        static let prevMonth = "calendar.prevMonth"
        static let nextMonth = "calendar.nextMonth"
        /// The floating add button on the Calendar (feat 1).
        static let addTransaction = "calendar.addTransaction"
        /// A transaction row in the day detail, keyed by its note (tap to edit, swipe to delete).
        static func txn(_ note: String) -> String { "calendar.txn.\(note)" }
    }

    enum Envelope {
        /// The remaining amount on an envelope row, keyed by name — lets a test assert spending
        /// reduced the right envelope's remaining.
        static func remaining(_ name: String) -> String { "envelope.remaining.\(name)" }
    }

    enum Starter {
        static let browse = "starter.browse"
        static let selectAll = "starter.selectAll"
        static let add = "starter.add"
        /// A starter envelope row in the picker, keyed by name.
        static func row(_ name: String) -> String { "starter.row.\(name)" }
    }
}
