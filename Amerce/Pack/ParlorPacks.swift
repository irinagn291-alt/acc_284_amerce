import Foundation

/// Role: Pack. Host-ready locked packs. Settings locks one. Spin consumes unused Dares in order.
enum ParlorPacks {
    static let wax = Pack(
        title: "Wax parlor slips",
        dares: [
            Dare(line: "Recite one couplet standing"),
            Dare(line: "Bow to the nearest lamp"),
            Dare(line: "Surrender a glove until Clear"),
            Dare(line: "Hum eight bars of a waltz"),
            Dare(line: "Stand still until the next land"),
        ]
    )

    static let lamp = Pack(
        title: "Lamp room",
        dares: [
            Dare(line: "Offer the next guest a seat"),
            Dare(line: "Speak only in questions until Clear"),
            Dare(line: "Trade places with the host"),
            Dare(line: "Hold a lamp pose for one land"),
            Dare(line: "Name three objects without pointing"),
            Dare(line: "Walk the room once, then sit"),
        ]
    )

    static let glove = Pack(
        title: "Glove table",
        dares: [
            Dare(line: "Lay a glove on the nearest table"),
            Dare(line: "Toast the landed name without a glass"),
            Dare(line: "Keep both heels together until Clear"),
            Dare(line: "Introduce two guests by plate"),
        ]
    )

    static let all: [Pack] = [wax, lamp, glove]

    static func matching(title: String) -> Pack? {
        all.first { $0.title == title }
    }
}
