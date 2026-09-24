import Foundation

/// Role: Pack. Derived pack heatmap on the Arena: fill is consumed/cap, balanceXY is the weight-average of name zones.
enum PackHeat: Sendable {
    struct Snapshot: Equatable, Sendable {
        var fill: Double
        var balanceX: Double
        var balanceY: Double
        var readiness: Double
    }

    static func clip(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    /// fill = Σvol / cap. Volume is consumed dares; capacity is the locked pack length.
    static func fill(volume: Double, capacity: Double) -> Double {
        guard capacity > 0 else { return 0 }
        return volume / capacity
    }

    /// balanceXY = weight-avg of zones around the wheel. Idle names weigh 0; stack depth is the zone weight.
    static func balanceXY(weights: [Double], radians: [Double]) -> (x: Double, y: Double) {
        let count = min(weights.count, radians.count)
        guard count > 0 else { return (0, 0) }
        var sumW = 0.0
        var sumX = 0.0
        var sumY = 0.0
        for index in 0 ..< count {
            let weight = weights[index]
            sumW += weight
            sumX += weight * cos(radians[index])
            sumY += weight * sin(radians[index])
        }
        guard sumW > 0 else { return (0, 0) }
        return (sumX / sumW, sumY / sumW)
    }

    /// readiness mixes clip(weight), clip(fill), and how close balance sits to the origin.
    static func readiness(weight: Double, fill: Double, balance: Double) -> Double {
        (clip(weight) + clip(fill) + clip(balance)) / 3
    }

    static func snapshot(for arena: Arena) -> Snapshot {
        let pack = arena.lockedPack
        let capacity = Double(pack?.dares.count ?? 0)
        let volume = Double(pack?.consumedCount ?? 0)
        let fillValue = fill(volume: volume, capacity: capacity)

        let sliceCount = arena.names.count
        let step = sliceCount > 0 ? (2 * Double.pi) / Double(sliceCount) : 0
        let weights = arena.names.map { Double($0.charge.depth) }
        let radians = arena.names.indices.map { (Double($0) + 0.5) * step }
        let xy = balanceXY(weights: weights, radians: radians)

        let totalWeight = weights.reduce(0, +)
        let weightClip = sliceCount > 0 ? totalWeight / Double(sliceCount) : 0
        let offset = hypot(xy.x, xy.y)
        let balance = 1 - min(1, offset)
        let ready = readiness(weight: weightClip, fill: fillValue, balance: balance)
        return Snapshot(fill: fillValue, balanceX: xy.x, balanceY: xy.y, readiness: ready)
    }
}
