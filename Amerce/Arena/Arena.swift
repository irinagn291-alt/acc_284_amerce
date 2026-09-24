import Foundation

/// Role: Arena. SpinSet: the ordered seating the wheel folds over. Names stay on the pie after a land.
struct Cast: Equatable, Sendable {
    var names: [Name]

    var count: Int { names.count }
    var isBare: Bool { names.isEmpty }
}

/// Role: Arena. SpinResult: the landed Name, the pinned Forfeit, and the physical WheelTurn that got there.
struct WheelLand: Equatable, Sendable {
    var nameID: UUID
    var plate: String
    var forfeit: Forfeit
    var turn: WheelTurn
    var stacked: Bool
}

/// Role: Arena. Outcome of pinForfeit when the fold succeeds. Spent and Bare throw; they are refusals.
struct PinFold: Equatable, Sendable {
    var arena: Arena
    var land: WheelLand
    var stackMark: StackMark?
}

/// Role: Arena. Outcome of a Clear that peels one Forfeit.
struct ClearFold: Equatable, Sendable {
    var arena: Arena
    var mark: ClearMark
    var peeled: Forfeit
}

/// Role: Arena. Typed refusals. Clear on Idle, Spin on Spent, empty seating, and a spent or missing Pack.
enum ArenaFault: Error, Equatable, Sendable {
    case bare
    case spent
    case idleClear
    case blankPlate
    case unknownName
    case blankPack
    case badPick
}

/// Role: Arena. One document: seated Names, locked Pack, marks, night history. File and UserDefaults are a projection.
struct Arena: Equatable, Sendable {
    var names: [Name]
    var lockedPack: Pack?
    var clearMarks: [ClearMark]
    var stackMarks: [StackMark]
    var nights: [NightLedger]
    var hapticsOn: Bool
    var onboardingComplete: Bool

    static let empty = Arena(
        names: [],
        lockedPack: nil,
        clearMarks: [],
        stackMarks: [],
        nights: [],
        hapticsOn: true,
        onboardingComplete: false
    )

    var cast: Cast { Cast(names: names) }

    var openForfeits: [Forfeit] {
        names.flatMap(\.charge.slips)
    }

    var canPin: Bool {
        !names.isEmpty && lockedPack.map { !$0.isSpent } == true
    }

    func name(id: UUID) -> Name? {
        names.first { $0.id == id }
    }
}

/// Role: Arena. Pure folds. Views never write Charge; pinForfeit and clearForfeit are the only Charge writers.
enum ArenaFold {
    static func seat(_ plate: String, onto arena: Arena) throws -> Arena {
        let trimmed = plate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ArenaFault.blankPlate }
        var next = arena
        next.names.append(Name(plate: trimmed, charge: .idle))
        return next
    }

    static func unseat(_ id: UUID, from arena: Arena) throws -> Arena {
        guard arena.names.contains(where: { $0.id == id }) else { throw ArenaFault.unknownName }
        var next = arena
        next.names.removeAll { $0.id == id }
        return next
    }

    static func lockPack(_ pack: Pack, onto arena: Arena) throws -> Arena {
        let dares = pack.dares.map { Dare(id: $0.id, line: $0.line.trimmingCharacters(in: .whitespacesAndNewlines)) }
        let usable = dares.filter { !$0.line.isEmpty }
        guard !usable.isEmpty else { throw ArenaFault.blankPack }
        let title = pack.title.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = arena
        next.lockedPack = Pack(
            id: pack.id,
            title: title.isEmpty ? "Locked pack" : title,
            dares: usable,
            nextIndex: 0
        )
        return next
    }

    static func pinForfeit(
        on arena: Arena,
        pick: (Int) -> Int,
        extraTurns: Int,
        now: Date,
        calendar: Calendar,
        currentDegrees: Double = 0
    ) throws -> PinFold {
        let sliceCount = arena.names.count
        guard sliceCount > 0 else { throw ArenaFault.bare }
        guard var pack = arena.lockedPack, let dare = pack.nextDare() else {
            throw ArenaFault.spent
        }
        let index = pick(sliceCount)
        guard let turn = WheelTurn.make(
            nameIndex: index,
            sliceCount: sliceCount,
            extraTurns: extraTurns,
            currentDegrees: currentDegrees
        ) else {
            throw ArenaFault.badPick
        }
        var next = arena
        pack.nextIndex += 1
        next.lockedPack = pack

        var guest = next.names[index]
        let stacked = guest.charge.isCharged
        let nightKey = NightStamp.from(now, calendar: calendar).rawValue
        let forfeit = Forfeit(
            nameID: guest.id,
            plate: guest.plate,
            dare: dare,
            nightKey: nightKey,
            pinnedAt: now
        )
        var slips = guest.charge.slips
        slips.append(forfeit)
        guest.charge = .charged(slips: slips)
        next.names[index] = guest
        appendNight(forfeit, onto: &next, key: nightKey)

        var stackMark: StackMark?
        if stacked {
            let mark = StackMark(
                nameID: guest.id,
                forfeitID: forfeit.id,
                depth: slips.count,
                nightKey: nightKey,
                at: now
            )
            next.stackMarks.append(mark)
            stackMark = mark
        }

        let land = WheelLand(
            nameID: guest.id,
            plate: guest.plate,
            forfeit: forfeit,
            turn: turn,
            stacked: stacked
        )
        return PinFold(arena: next, land: land, stackMark: stackMark)
    }

    static func clearForfeit(
        nameID: UUID,
        on arena: Arena,
        now: Date,
        calendar: Calendar
    ) throws -> ClearFold {
        guard let index = arena.names.firstIndex(where: { $0.id == nameID }) else {
            throw ArenaFault.unknownName
        }
        var guest = arena.names[index]
        guard guest.charge.isCharged else { throw ArenaFault.idleClear }
        var slips = guest.charge.slips
        guard let peeled = slips.popLast() else { throw ArenaFault.idleClear }
        guest.charge = slips.isEmpty ? .idle : .charged(slips: slips)
        var next = arena
        next.names[index] = guest
        let nightKey = NightStamp.from(now, calendar: calendar).rawValue
        let mark = ClearMark(
            nameID: guest.id,
            forfeitID: peeled.id,
            nightKey: nightKey,
            at: now
        )
        next.clearMarks.append(mark)
        return ClearFold(arena: next, mark: mark, peeled: peeled)
    }

    private static func appendNight(_ forfeit: Forfeit, onto arena: inout Arena, key: Int) {
        if let index = arena.nights.firstIndex(where: { $0.key == key }) {
            arena.nights[index].forfeits.append(forfeit)
        } else {
            arena.nights.append(NightLedger(key: key, forfeits: [forfeit]))
            arena.nights.sort { $0.key < $1.key }
        }
    }
}
