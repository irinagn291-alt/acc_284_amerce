import Foundation

/// Role: StackMark. Written when Spin lands on a Charged Name. Charge stays Charged; depth is the new stack size.
struct StackMark: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var nameID: UUID
    var forfeitID: UUID
    var depth: Int
    var nightKey: Int
    var at: Date

    init(
        id: UUID = UUID(),
        nameID: UUID,
        forfeitID: UUID,
        depth: Int,
        nightKey: Int,
        at: Date
    ) {
        self.id = id
        self.nameID = nameID
        self.forfeitID = forfeitID
        self.depth = depth
        self.nightKey = nightKey
        self.at = at
    }
}
