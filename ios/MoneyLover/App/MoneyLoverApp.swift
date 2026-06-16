import SwiftUI
import SwiftData

@main
struct MoneyLoverApp: App {
    let container: ModelContainer

    init() {
        do {
            // When hosted by a unit-test bundle, use an in-memory store so the
            // app never touches disk — avoids noisy CoreData EROFS diagnostics in
            // CI. Unit tests build their own containers; this is just the host app.
            let isUnitTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            let config = ModelConfiguration(isStoredInMemoryOnly: isUnitTesting)
            container = try ModelContainer(for: Schema(AppSchema.models), configurations: config)
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
