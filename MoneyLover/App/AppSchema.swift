import SwiftData

/// The full list of SwiftData models, used by the app container and previews.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        SourceRecord.self,
        TransactionRecord.self,
        EnvelopeRecord.self,
        RateRecord.self,
        GoalRecord.self,
        ContributionRecord.self
    ]
}
