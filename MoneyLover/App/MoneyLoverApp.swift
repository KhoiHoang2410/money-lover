import SwiftUI
import SwiftData

@main
struct MoneyLoverApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Schema(AppSchema.models))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
