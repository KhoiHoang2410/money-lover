import Foundation
import SwiftData

/// Reads and writes `Envelope` values, enforcing a single Reserve.
@MainActor
final class EnvelopeRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() throws -> [Envelope] {
        let descriptor = FetchDescriptor<EnvelopeRecord>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func add(_ envelope: Envelope) throws {
        context.insert(EnvelopeRecord(domain: envelope))
        try context.save()
    }

    func update(_ envelope: Envelope) throws {
        let id = envelope.id
        let descriptor = FetchDescriptor<EnvelopeRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else {
            try add(envelope)
            return
        }
        record.update(from: envelope)
        try context.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<EnvelopeRecord>(predicate: #Predicate { $0.id == id })
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
        try context.save()
    }

    /// Adds the month-end sweep delta to the Reserve's carried amount.
    func sweepIntoReserve(delta: Money) throws {
        let descriptor = FetchDescriptor<EnvelopeRecord>(predicate: #Predicate { $0.isReserve })
        guard let reserve = try context.fetch(descriptor).first else { return }
        reserve.carriedMinorUnits += delta.minorUnits
        try context.save()
    }

    /// Marks one envelope as the Reserve and clears the flag on all others.
    func setReserve(id: UUID) throws {
        for record in try context.fetch(FetchDescriptor<EnvelopeRecord>()) {
            record.isReserve = (record.id == id)
        }
        try context.save()
    }
}
