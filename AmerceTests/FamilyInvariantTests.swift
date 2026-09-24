import XCTest
import SwiftUI
@testable import Amerce

final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_pickFirstThenRotateClockwiseOntoSliceCentre() throws {
        let sliceCount = 4
        let pick: (Int) -> Int = { _ in 2 }
        let nameIndex = pick(sliceCount)
        XCTAssertEqual(nameIndex, 2)

        let turn = try XCTUnwrap(WheelTurn.make(nameIndex: nameIndex, sliceCount: sliceCount, extraTurns: 6))
        XCTAssertEqual(turn.sliceCount, sliceCount)
        XCTAssertEqual(turn.landCenterDegrees, (Double(turn.nameIndex) + 0.5) * (360.0 / Double(sliceCount)), accuracy: 0.0001)
        XCTAssertEqual(turn.clockwiseDegrees, 6 * 360.0 + turn.landCenterDegrees, accuracy: 0.0001)
        XCTAssertGreaterThanOrEqual(turn.clockwiseDegrees, 5 * 360.0)
        XCTAssertLessThanOrEqual(turn.clockwiseDegrees, 7 * 360.0 + 360.0)
        XCTAssertEqual(turn.duration, 3.4)
        XCTAssertTrue(WheelTurn.extraTurnBounds.contains(turn.extraTurns))
        XCTAssertEqual(turn.pulseTimes, turn.pulseTimes.sorted())
        XCTAssertLessThan(turn.pulseTimes.last ?? 0, turn.landAt)
        XCTAssertEqual(turn.landAt, 3.4)
    }

    func test_familyInvariant_extraTurnsStayInFiveToSeven() {
        XCTAssertNil(WheelTurn.make(nameIndex: 0, sliceCount: 3, extraTurns: 4))
        XCTAssertNil(WheelTurn.make(nameIndex: 0, sliceCount: 3, extraTurns: 8))
        XCTAssertNotNil(WheelTurn.make(nameIndex: 0, sliceCount: 3, extraTurns: 5))
        XCTAssertNotNil(WheelTurn.make(nameIndex: 0, sliceCount: 3, extraTurns: 7))
        XCTAssertNil(WheelTurn.make(nameIndex: 0, sliceCount: 0, extraTurns: 6))
    }

    func test_familyInvariant_clockwiseDistanceNeverGoesBackwards() {
        XCTAssertEqual(WheelTurn.clockwiseDistance(from: 350, to: 10), 20, accuracy: 0.0001)
        XCTAssertEqual(WheelTurn.clockwiseDistance(from: 10, to: 10), 0, accuracy: 0.0001)
        XCTAssertGreaterThan(WheelTurn.clockwiseDistance(from: 10, to: 9), 300)
    }

    func test_familyInvariant_pegRotationSeatsCentreOnTwelveOClock() throws {
        let turn = try XCTUnwrap(WheelTurn.make(nameIndex: 0, sliceCount: 4, extraTurns: 6))
        XCTAssertEqual(turn.landCenterDegrees, 45, accuracy: 0.0001)
        let peg = WheelTurn.pegRotation(landCenterDegrees: turn.landCenterDegrees)
        XCTAssertEqual(peg, 315, accuracy: 0.0001)
        XCTAssertEqual(WheelTurn.normalize(turn.landCenterDegrees + peg), 0, accuracy: 0.0001)
    }

    func test_packHeat_fillBalanceXYAndReadiness() {
        // Desk pack_balance: fill=Σvol/cap; balanceXY=weight-avg of zones; readiness mixes clip(weight), clip(fill), balance.
        XCTAssertEqual(PackHeat.fill(volume: 2, capacity: 5), 0.4, accuracy: 0.0001)
        XCTAssertEqual(PackHeat.fill(volume: 0, capacity: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(PackHeat.clip(1.4), 1, accuracy: 0.0001)
        XCTAssertEqual(PackHeat.clip(-0.2), 0, accuracy: 0.0001)

        let xy = PackHeat.balanceXY(weights: [2, 0, 2, 0], radians: [0.25 * .pi, 0.75 * .pi, 1.25 * .pi, 1.75 * .pi])
        XCTAssertEqual(xy.x, 0, accuracy: 0.0001)
        XCTAssertEqual(xy.y, 0, accuracy: 0.0001)

        let ready = PackHeat.readiness(weight: 1.4, fill: 0.4, balance: 1)
        XCTAssertEqual(ready, (1 + 0.4 + 1) / 3, accuracy: 0.0001)

        let charged = ArenaSeed.charged()
        let heat = PackHeat.snapshot(for: charged)
        XCTAssertEqual(heat.fill, 2.0 / 5.0, accuracy: 0.0001)
        XCTAssertGreaterThan(heat.readiness, 0)
        XCTAssertLessThanOrEqual(heat.readiness, 1)
        let expected = PackHeat.balanceXY(
            weights: charged.names.map { Double($0.charge.depth) },
            radians: charged.names.indices.map { (Double($0) + 0.5) * (.pi / 2) }
        )
        XCTAssertEqual(heat.balanceX, expected.x, accuracy: 0.0001)
        XCTAssertEqual(heat.balanceY, expected.y, accuracy: 0.0001)
    }

    func test_componentContract_materialElevationNotStrokeFill() throws {
        XCTAssertEqual(ParlorInk.Spacing.card, 24)
        XCTAssertEqual(ParlorInk.Spacing.chip, 10)
        XCTAssertEqual(ParlorInk.Spacing.unit, 8)
        _ = ParlorInk.Spacing.material
        _ = ParlorInk.Spacing.thin

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let lift = try String(contentsOf: root.appendingPathComponent("Amerce/Arena/ParlorLift.swift"), encoding: .utf8)
        XCTAssertTrue(lift.contains(".background(.regularMaterial)"))
        XCTAssertTrue(lift.contains(".background(.thinMaterial)"))
        XCTAssertTrue(lift.contains("func parlorCard"))
        XCTAssertTrue(lift.contains("func parlorChip"))
        XCTAssertFalse(lift.contains(".stroke("))
        XCTAssertFalse(lift.contains("strokeBorder"))
        XCTAssertFalse(lift.contains("Color.surface"))

        let press = try String(contentsOf: root.appendingPathComponent("Amerce/Arena/ParlorPress.swift"), encoding: .utf8)
        XCTAssertTrue(press.contains(".regularMaterial"))
        XCTAssertTrue(press.contains(".thinMaterial"))
        XCTAssertFalse(press.contains(".stroke("))
        XCTAssertFalse(press.contains("strokeBorder"))

        let strip = try String(contentsOf: root.appendingPathComponent("Amerce/Pack/PackHeatStrip.swift"), encoding: .utf8)
        XCTAssertTrue(strip.contains("parlorCard"))
        XCTAssertFalse(strip.contains(".stroke("))

        let rail = try String(contentsOf: root.appendingPathComponent("Amerce/Forfeit/ForfeitRail.swift"), encoding: .utf8)
        XCTAssertTrue(rail.contains(".parlorCard()"))
        XCTAssertTrue(rail.contains(".parlorChip()"))
        XCTAssertFalse(rail.contains(".stroke("))
    }
}
