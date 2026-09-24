import Foundation

/// Role: Pack. One locked dare pack. Each Spin consumes the next unused Dare; a spent pack refuses Spin until a new lock.
struct Pack: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var title: String
    var dares: [Dare]
    var nextIndex: Int

    init(id: UUID = UUID(), title: String, dares: [Dare], nextIndex: Int = 0) {
        self.id = id
        self.title = title
        self.dares = dares
        self.nextIndex = nextIndex
    }

    var isSpent: Bool { nextIndex >= dares.count }
    var unusedCount: Int { max(0, dares.count - nextIndex) }
    var consumedCount: Int { min(nextIndex, dares.count) }

    func nextDare() -> Dare? {
        guard nextIndex < dares.count else { return nil }
        return dares[nextIndex]
    }
}

/// Role: Pack. One line the wheel can pin. Identity is stable; the line is the spoken forfeit.
struct Dare: Identifiable, Hashable, Sendable, Equatable, Codable {
    var id: UUID
    var line: String

    init(id: UUID = UUID(), line: String) {
        self.id = id
        self.line = line
    }
}
