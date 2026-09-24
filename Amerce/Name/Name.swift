import Foundation

/// Role: Name. One seated guest on the Arena. Charge is Idle or Charged; the Name never leaves the wheel on a land.
struct Name: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var plate: String
    var charge: Charge

    init(id: UUID = UUID(), plate: String, charge: Charge = .idle) {
        self.id = id
        self.plate = plate
        self.charge = charge
    }
}

/// Role: Name. Forfeit ADT: Idle has no slips; Charged holds the open stack the next Clear peels.
enum Charge: Equatable, Sendable, Codable, Hashable {
    case idle
    case charged(slips: [Forfeit])

    var slips: [Forfeit] {
        switch self {
        case .idle:
            []
        case .charged(let slips):
            slips
        }
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isCharged: Bool { !isIdle }

    var depth: Int { slips.count }
}
