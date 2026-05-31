import SwiftUI
import SwiftData

/// The root tab shell. Injects the app-level Reduce-motion preference and runs first-launch
/// onboarding when no sources exist yet.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("appearance") private var appearance: AppearancePreference = .system
    @AppStorage("didOnboard") private var didOnboard = false
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
            let env = ProcessInfo.processInfo.environment
            // UI-test launch hook: a clean, deterministic store every run and onboarding skipped,
            // so automated flows start from the same known seed. Gated on env vars only the test
            // runner sets — never reached in a normal build.
            if env["UITEST"] == "1" {
                SampleData.clear(into: context)
                SampleData.seed(into: context)
                // Reset persisted UI preferences so each run starts from documented defaults
                // (amounts censored, onboarding done) — UserDefaults otherwise survives reinstall
                // on a simulator and leaks state between runs.
                let defaults = UserDefaults.standard
                defaults.set(true, forKey: "censorAmounts")
                defaults.set(false, forKey: "reduceMotion")
                didOnboard = true
                return
            }
            if env["SEED_SAMPLE_DATA"] == "1" {
                SampleData.seed(into: context)
            }
            #endif
            // Decide onboarding off a fresh count, not a captured `@Query` snapshot — the snapshot
            // does not reflect inserts made earlier in this same task tick (e.g. a seed), which
            // could otherwise show onboarding on top of populated data (BUG-002).
            if !didOnboard {
                let sourceCount = (try? context.fetchCount(FetchDescriptor<SourceRecord>())) ?? 0
                if sourceCount == 0 {
                    showOnboarding = true
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
