import Foundation

/// Role: Forfeit. Night history keyed as YYYYMMDD Int. Open Charge is not stored here; this is the ledger of pins.
struct NightLedger: Identifiable, Hashable, Sendable, Equatable, Codable {
    var key: Int
    var forfeits: [Forfeit]

    var id: Int { key }
}
