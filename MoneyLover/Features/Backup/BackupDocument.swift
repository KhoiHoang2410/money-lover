import SwiftUI
import UniformTypeIdentifiers

/// A JSON document wrapping a `DataBackup`'s encoded bytes, for `.fileExporter`/`.fileImporter`.
/// JSON (`public.json`, the `.json` extension) is natively understood by the iOS Files app and
/// every device, so the exported file opens, syncs, and re-imports without a custom UTI.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileContents: data)
    }
}
