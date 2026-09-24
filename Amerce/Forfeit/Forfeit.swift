import Foundation

/// Role: Forfeit. One pinned dare on a Name. History keeps the slip for the night; Clear peels it from Charge.
struct Forfeit: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var nameID: UUID
    var plate: String
    var dare: Dare
    var nightKey: Int
    var pinnedAt: Date

    init(
        id: UUID = UUID(),
        nameID: UUID,
        plate: String,
        dare: Dare,
        nightKey: Int,
        pinnedAt: Date
    ) {
        self.id = id
        self.nameID = nameID
        self.plate = plate
        self.dare = dare
        self.nightKey = nightKey
        self.pinnedAt = pinnedAt
    }
}
