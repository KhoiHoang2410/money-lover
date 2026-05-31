import SwiftUI

/// The Config tab: a hub routing to every settings sub-page via `navigationDestination(for:)`.
struct ConfigScreen: View {
    @Environment(\.modelContext) private var context
    @State private var onboarding = false

    var body: some View {
        NavigationStack {
            List {
                Section("Money") {
                    NavigationLink(value: ConfigRoute.sources) {
                        Label("Sources & balances", systemImage: "building.columns.fill")
                    }
                    .accessibilityIdentifier(A11y.Config.sources)
                    NavigationLink(value: ConfigRoute.envelopes) {
                        Label("Envelopes & template", systemImage: "tray.full.fill")
                    }
                    .accessibilityIdentifier(A11y.Config.envelopes)
                    NavigationLink(value: ConfigRoute.rates) {
                        Label("Rates & prices", systemImage: "dollarsign.arrow.circlepath")
                    }
                    .accessibilityIdentifier(A11y.Config.rates)
                    NavigationLink(value: ConfigRoute.monthEnd) {
                        Label("Run month-end sweep", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .accessibilityIdentifier(A11y.Config.monthEnd)
                }

                Section("Insights") {
                    NavigationLink(value: ChartsDestination.charts) {
                        Label("Charts & trends", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink(value: ConfigRoute.advice) {
                        Label("Advice", systemImage: "lightbulb.fill")
                    }
                }

                Section("App") {
                    NavigationLink(value: ConfigRoute.appearance) {
                        Label("Appearance", systemImage: "paintpalette.fill")
                    }
                    Button {
                        onboarding = true
                    } label: {
                        Label("Set up balances", systemImage: "wallet.bifold.fill")
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Button("Seed sample data", systemImage: "wand.and.stars") {
                        SampleData.seed(into: context)
                    }
                    .accessibilityIdentifier(A11y.Config.seedSample)
                    Button("Clear all data", systemImage: "trash", role: .destructive) {
                        SampleData.clear(into: context)
                    }
                    .accessibilityIdentifier(A11y.Config.clearData)
                }
                #endif

                Section {
                    Text(AppInfo.displayString())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                        .accessibilityIdentifier(A11y.Config.version)
                }
            }
            .navigationTitle("Config")
            .navigationDestination(for: ConfigRoute.self) { route in
                switch route {
                case .sources: SourcesScreen()
                case .envelopes: EnvelopesScreen()
                case .monthEnd: MonthEndScreen()
                case .rates: RatesScreen()
                case .advice: AdviceScreen()
                case .appearance: AppearanceScreen()
                }
            }
            .navigationDestination(for: ChartsDestination.self) { _ in
                ChartsScreen()
            }
            .sheet(isPresented: $onboarding) {
                OnboardingScreen()
            }
        }
    }
}

#Preview {
    ConfigScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
