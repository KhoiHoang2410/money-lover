import Foundation
import Observation

/// View state for Backup: encodes the whole store to a JSON document for export, and restores the
/// store from a chosen backup file. Restore replaces everything in one save, so all screens refresh.
@MainActor
@Observable
final class BackupStore {
    private let repo: BackupRepository
    /// A short result/error line shown after an export or import.
    var resultMessage: String?

    init(repo: BackupRepository) {
        self.repo = repo
    }

    /// The suggested filename for an exported backup (dated `yyyy-MM-dd`).
    var exportFilename: String {
        "MoneyLover-Backup-\(Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash)))"
    }

    /// Builds the JSON document for export, or nil (and reports) if encoding fails.
    func makeDocument() -> BackupDocument? {
        do {
            let backup = try repo.export()
            let data = try Self.encoder.encode(backup)
            return BackupDocument(data: data)
        } catch {
            resultMessage = "Couldn't prepare the backup: \(error.localizedDescription)"
            return nil
        }
    }

    func reportExport(_ result: Result<URL, Error>) {
        switch result {
        case .success: resultMessage = "Backup exported."
        case .failure(let error): resultMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    /// Reads, decodes, and restores from the picked file, replacing all current data.
    func importBackup(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            resultMessage = "Import failed: \(error.localizedDescription)"
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                let backup = try Self.decoder.decode(DataBackup.self, from: data)
                try repo.restore(backup)
                resultMessage = "Imported \(backup.sources.count) sources and \(backup.transactions.count) transactions."
            } catch {
                resultMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
