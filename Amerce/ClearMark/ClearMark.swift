import Foundation

/// Role: ClearMark. Written when a Name peels one Forfeit. The last Clear on that Name folds Charged back to Idle.
struct ClearMark: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var nameID: UUID
    var forfeitID: UUID
    var nightKey: Int
    var at: Date

    init(
        id: UUID = UUID(),
        nameID: UUID,
        forfeitID: UUID,
        nightKey: Int,
        at: Date
    ) {
        self.id = id
        self.nameID = nameID
        self.forfeitID = forfeitID
        self.nightKey = nightKey
        self.at = at
    }
}
