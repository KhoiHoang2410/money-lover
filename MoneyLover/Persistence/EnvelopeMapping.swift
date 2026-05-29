import Foundation

/// Maps between `EnvelopeRecord` and the pure domain `Envelope`.
extension EnvelopeRecord {
    convenience init(domain e: Envelope) {
        self.init(
            id: e.id,
            name: e.name,
            iconName: e.iconName,
            allocationMinorUnits: e.allocation.minorUnits,
            carriedMinorUnits: e.carried.minorUnits,
            isReserve: e.isReserve
        )
    }

    func toDomain() -> Envelope {
        Envelope(
            id: id,
            name: name,
            iconName: iconName,
            allocation: Money(minorUnits: allocationMinorUnits, currency: .vnd),
            carried: Money(minorUnits: carriedMinorUnits, currency: .vnd),
            isReserve: isReserve
        )
    }

    func update(from e: Envelope) {
        name = e.name
        iconName = e.iconName
        allocationMinorUnits = e.allocation.minorUnits
        carriedMinorUnits = e.carried.minorUnits
        isReserve = e.isReserve
    }
}
