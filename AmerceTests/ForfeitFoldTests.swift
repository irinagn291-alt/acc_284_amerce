import XCTest
@testable import Amerce

final class ForfeitFoldTests: XCTestCase {
    private var calendar: Calendar {
        ArenaSeed.utcCalendar()
    }

    private let now = Date(timeIntervalSince1970: 1_789_776_000)

    func test_architecture_idleToChargedStackThenLastClearToIdle() throws {
        var arena = try seatedArena()
        XCTAssertTrue(arena.names[0].charge.isIdle)

        let first = try ArenaFold.pinForfeit(on: arena, pick: { _ in 0 }, extraTurns: 6, now: now, calendar: calendar)
        arena = first.arena
        XCTAssertFalse(first.land.stacked)
        XCTAssertNil(first.stackMark)
        XCTAssertTrue(arena.names[0].charge.isCharged)
        XCTAssertEqual(arena.names[0].charge.depth, 1)
        XCTAssertEqual(arena.nights.first?.key, 20260919)
        XCTAssertEqual(arena.nights.first?.forfeits.map(\.dare.line), ["Recite one couplet standing"])

        let stacked = try ArenaFold.pinForfeit(on: arena, pick: { _ in 0 }, extraTurns: 5, now: now, calendar: calendar)
        arena = stacked.arena
        XCTAssertTrue(stacked.land.stacked)
        XCTAssertEqual(stacked.stackMark?.depth, 2)
        XCTAssertTrue(arena.names[0].charge.isCharged)
        XCTAssertEqual(arena.names[0].charge.depth, 2)

        let firstClear = try ArenaFold.clearForfeit(nameID: arena.names[0].id, on: arena, now: now, calendar: calendar)
        arena = firstClear.arena
        XCTAssertTrue(arena.names[0].charge.isCharged)
        XCTAssertEqual(arena.names[0].charge.depth, 1)

        let lastClear = try ArenaFold.clearForfeit(nameID: arena.names[0].id, on: arena, now: now, calendar: calendar)
        arena = lastClear.arena
        XCTAssertTrue(arena.names[0].charge.isIdle)
        XCTAssertEqual(arena.clearMarks.count, 2)
        XCTAssertEqual(arena.cast.count, 4)
    }

    func test_architecture_refuseClearOnIdleSpentSpinAndBare() throws {
        XCTAssertThrowsError(
            try ArenaFold.pinForfeit(on: .empty, pick: { _ in 0 }, extraTurns: 6, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? ArenaFault, .bare)
        }

        let arena = try seatedArena()
        let idleID = arena.names[0].id
        XCTAssertThrowsError(
            try ArenaFold.clearForfeit(nameID: idleID, on: arena, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? ArenaFault, .idleClear)
        }

        var spent = arena
        if var pack = spent.lockedPack {
            pack.nextIndex = pack.dares.count
            spent.lockedPack = pack
        }
        XCTAssertThrowsError(
            try ArenaFold.pinForfeit(on: spent, pick: { _ in 0 }, extraTurns: 6, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? ArenaFault, .spent)
        }
    }

    func test_pinForfeit_emptyPopulatedInvalid() throws {
        XCTAssertThrowsError(
            try ArenaFold.pinForfeit(on: .empty, pick: { _ in 0 }, extraTurns: 6, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? ArenaFault, .bare)
        }

        let arena = try seatedArena()
        let fold = try ArenaFold.pinForfeit(on: arena, pick: { _ in 1 }, extraTurns: 6, now: now, calendar: calendar)
        XCTAssertEqual(fold.land.plate, "Oswald")
        XCTAssertEqual(fold.land.turn.nameIndex, 1)
        XCTAssertEqual(fold.arena.lockedPack?.consumedCount, 1)
        XCTAssertTrue(fold.arena.canPin)

        XCTAssertThrowsError(
            try ArenaFold.pinForfeit(on: arena, pick: { _ in 9 }, extraTurns: 6, now: now, calendar: calendar)
        ) { error in
            XCTAssertEqual(error as? ArenaFault, .badPick)
        }
        XCTAssertThrowsError(try ArenaFold.seat("   ", onto: arena)) { error in
            XCTAssertEqual(error as? ArenaFault, .blankPlate)
        }
    }

    func test_nameStaysOnWheelAfterPin() throws {
        let arena = try seatedArena()
        let fold = try ArenaFold.pinForfeit(on: arena, pick: { _ in 2 }, extraTurns: 7, now: now, calendar: calendar)
        XCTAssertEqual(fold.arena.names.map(\.plate), arena.names.map(\.plate))
        XCTAssertEqual(fold.arena.cast.count, 4)
        XCTAssertEqual(fold.land.turn.sliceCount, 4)
    }

    private func seatedArena() throws -> Arena {
        var arena = try ArenaFold.seat("Harriet", onto: .empty)
        arena = try ArenaFold.seat("Oswald", onto: arena)
        arena = try ArenaFold.seat("Celia", onto: arena)
        arena = try ArenaFold.seat("Bram", onto: arena)
        return try ArenaFold.lockPack(
            Pack(
                title: "Wax parlor slips",
                dares: [
                    Dare(line: "Recite one couplet standing"),
                    Dare(line: "Bow to the nearest lamp"),
                    Dare(line: "Surrender a glove until Clear"),
                    Dare(line: "Hum eight bars of a waltz"),
                    Dare(line: "Stand still until the next land"),
                ]
            ),
            onto: arena
        )
    }
}
