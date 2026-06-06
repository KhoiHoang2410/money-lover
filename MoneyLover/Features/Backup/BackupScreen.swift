import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Backup & restore (Config → Backup): export every Source, Transaction, Envelope, Goal, and Rate to
/// a `.json` file the iOS Files app understands, and re-import one to replace the current data.
struct BackupScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: BackupStore?
    @State private var document: BackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var confirmingImport = false
    @State private var showingResult = false

    var body: some View {
        Group {
            if let store {
                content(store)
            } else {
                ProgressView()
                    .task {
                        guard store == nil else { return }
                        store = BackupStore(repo: BackupRepository(context: context))
                    }
            }
        }
        .navigationTitle("Backup")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ store: BackupStore) -> some View {
        List {
            Section {
                Button("Export data…", systemImage: "square.and.arrow.up") {
                    document = store.makeDocument()
                    exporting = document != nil
                    showingResult = document == nil // encoding failed → surface the error now
                }
                .accessibilityIdentifier(A11y.Backup.export)
            } footer: {
                Text("Saves a JSON file with all your accounts, transactions, envelopes, goals, and rates. Keep it in Files or iCloud Drive as a backup.")
            }

            Section {
                Button("Import data…", systemImage: "square.and.arrow.down") {
                    confirmingImport = true
                }
                .accessibilityIdentifier(A11y.Backup.importData)
            } footer: {
                Text("Restores from a previously exported file. This replaces all current data.")
            }
        }
        .fileExporter(
            isPresented: $exporting,
            document: document,
            contentType: .json,
            defaultFilename: store.exportFilename
        ) { result in
            store.reportExport(result)
            document = nil
            showingResult = true
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            store.importBackup(result)
            showingResult = true
        }
        .confirmationDialog(
            "Replace all data with the imported file?",
            isPresented: $confirmingImport,
            titleVisibility: .visible
        ) {
            Button("Choose file…") { importing = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current accounts, transactions, envelopes, goals, and rates will be replaced.")
        }
        .alert("Backup", isPresented: $showingResult) {
            Button("OK") { store.resultMessage = nil }
        } message: {
            Text(store.resultMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        BackupScreen()
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
