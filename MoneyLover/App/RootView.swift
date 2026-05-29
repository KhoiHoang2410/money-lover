import SwiftUI
import SwiftData

/// The root tab shell. Injects the app-level Reduce-motion preference and runs first-launch
/// onboarding when no sources exist yet.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("appearance") private var appearance: AppearancePreference = .system
    @AppStorage("didOnboard") private var didOnboard = false
    @Query private var sources: [SourceRecord]
    @State private var selection: AppTab = .overview
    @State private var showOnboarding = false

    var body: some View {
        TabView(selection: $selection) {
            Tab(AppTab.overview.title, systemImage: AppTab.overview.symbol, value: AppTab.overview) {
                OverviewScreen()
            }
            Tab(AppTab.goals.title, systemImage: AppTab.goals.symbol, value: AppTab.goals) {
                GoalsScreen()
            }
            Tab(AppTab.calendar.title, systemImage: AppTab.calendar.symbol, value: AppTab.calendar) {
                CalendarScreen()
            }
            Tab(AppTab.input.title, systemImage: AppTab.input.symbol, value: AppTab.input) {
                InputScreen()
            }
            Tab(AppTab.config.title, systemImage: AppTab.config.symbol, value: AppTab.config) {
                ConfigScreen()
            }
        }
        .environment(\.reduceMotionPreference, reduceMotion)
        .preferredColorScheme(appearance.colorScheme)
        .sheet(isPresented: $showOnboarding) {
            didOnboard = true
        } content: {
            OnboardingScreen()
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["SEED_SAMPLE_DATA"] == "1" {
                SampleData.seed(into: context)
            }
            #endif
            if !didOnboard && sources.isEmpty {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
