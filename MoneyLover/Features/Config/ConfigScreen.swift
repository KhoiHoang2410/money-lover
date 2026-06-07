import SwiftUI

/// The Config tab: a hub routing to every settings sub-page via `navigationDestination(for:)`.
struct ConfigScreen: View {
    @Environment(\.modelContext) private var context
    @State private var onboarding = false
    @State private var confirmingDeleteAll = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Money") {
                    NavigationLink(value: ConfigRoute.sources) {
                        Label("Sources & balances", systemImage: "building.columns.fill")
                    }
                    .accessibilityIdentifier(A11y.Config.sources)
                    NavigationLink(value: ConfigRoute.reconcile) {
                        Label("Update balances", systemImage: "checkmark.circle.badge.questionmark")
                    }
                    .accessibilityIdentifier(A11y.Config.reconcile)
                    NavigationLink(value: ConfigRoute.holdings) {
                        Label("Holdings (gold & stock)", systemImage: "chart.pie.fill")
                    }
                    .accessibilityIdentifier(A11y.Config.holdings)
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
                    .accessibilityIdentifier(A11y.Config.appearance)
                    Button {
                        onboarding = true
                    } label: {
                        Label("Set up balances", systemImage: "wallet.bifold.fill")
                    }
                    NavigationLink(value: ConfigRoute.backup) {
                        Label("Backup & restore", systemImage: "arrow.up.arrow.down.circle.fill")
                    }
                    .accessibilityIdentifier(A11y.Config.backup)
                }

                Section {
                    Button(role: .destructive) {
                        confirmingDeleteAll = true
                    } label: {
                        Label("Delete all data", systemImage: "trash.fill")
                    }
                    .accessibilityIdentifier(A11y.Config.deleteAll)
                } footer: {
                    Text("Permanently erases every account, transaction, envelope, goal, and saved rate. This can’t be undone.")
                }

                #if DEBUG
                if debugToolsEnabled {
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
                case .holdings: HoldingsScreen()
                case .envelopes: EnvelopesScreen()
                case .reconcile: ReconcileScreen()
                case .monthEnd: MonthEndScreen()
                case .rates: RatesScreen()
                case .advice: AdviceScreen()
                case .appearance: AppearanceScreen()
                case .backup: BackupScreen()
                }
            }
            .navigationDestination(for: ChartsDestination.self) { _ in
                ChartsScreen()
            }
            .sheet(isPresented: $onboarding) {
                OnboardingScreen()
            }
            .sheet(isPresented: $confirmingDeleteAll) {
                DeleteAllDataSheet(onConfirm: deleteAllData)
            }
            .alert("Couldn’t delete data", isPresented: .constant(deleteError != nil)) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    #if DEBUG
    /// The sample-data Debug tools are dev-only. They show only when running in the Simulator or
    /// under a UI test (`UITEST=1`) — never on a build installed on a physical device, where this
    /// stays `false`. (The whole section is already compiled out of Release builds entirely.)
    private var debugToolsEnabled: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
        #endif
    }
    #endif

    private func deleteAllData() {
        do {
            try DataReset.eraseAll(into: context)
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

#Preview {
    ConfigScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
