import Foundation

/// Role: Arena. Pick the landed Name first, then rotate clockwise: 360/n per slice, +5-7 turns, centre, about 3.4s.
struct WheelTurn: Equatable, Sendable {
    static let durationSeconds: TimeInterval = 3.4
    static let extraTurnBounds = 5 ... 7

    var nameIndex: Int
    var sliceCount: Int
    var extraTurns: Int
    var landCenterDegrees: Double
    var clockwiseDegrees: Double
    var duration: TimeInterval
    var pulseTimes: [TimeInterval]
    var landAt: TimeInterval

    static func make(
        nameIndex: Int,
        sliceCount: Int,
        extraTurns: Int,
        currentDegrees: Double = 0
    ) -> WheelTurn? {
        guard extraTurnBounds.contains(extraTurns) else { return nil }
        guard sliceCount >= 1, nameIndex >= 0, nameIndex < sliceCount else { return nil }
        let step = 360.0 / Double(sliceCount)
        let center = (Double(nameIndex) + 0.5) * step
        let delta = clockwiseDistance(from: currentDegrees, to: center)
        let total = Double(extraTurns) * 360.0 + delta
        let duration = durationSeconds
        return WheelTurn(
            nameIndex: nameIndex,
            sliceCount: sliceCount,
            extraTurns: extraTurns,
            landCenterDegrees: center,
            clockwiseDegrees: total,
            duration: duration,
            pulseTimes: pulseSchedule(duration: duration),
            landAt: duration
        )
    }

    static func normalize(_ degrees: Double) -> Double {
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }

    static func clockwiseDistance(from: Double, to: Double) -> Double {
        var delta = normalize(to) - normalize(from)
        if delta < 0 { delta += 360 }
        return delta
    }

    /// Clockwise rotation that seats a slice centre under a 12 o'clock peg.
    static func pegRotation(landCenterDegrees: Double) -> Double {
        normalize(-landCenterDegrees)
    }

    /// Haptics ease into a landing climax. The last pulse fires before the peg seats.
    static func pulseSchedule(duration: TimeInterval) -> [TimeInterval] {
        [0.28, 0.47, 0.64, 0.78, 0.88, 0.95].map { $0 * duration }
    }
}
