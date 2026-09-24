import Foundation

/// Role: Arena. Simulator-only parlor seed. Device never seeds. Guard is amc.demo.v1.
enum ArenaSeed {
    static func seated() -> Arena {
        let plates = ["Harriet", "Oswald", "Celia", "Bram"]
        let dares = [
            "Recite one couplet standing",
            "Bow to the nearest lamp",
            "Surrender a glove until Clear",
            "Hum eight bars of a waltz",
            "Stand still until the next land",
        ]
        let pack = Pack(
            title: "Wax parlor slips",
            dares: dares.map { Dare(line: $0) }
        )
        return Arena(
            names: plates.map { Name(plate: $0, charge: .idle) },
            lockedPack: pack,
            clearMarks: [],
            stackMarks: [],
            nights: [],
            hapticsOn: true,
            onboardingComplete: true
        )
    }

    static func charged(now: Date = Date(timeIntervalSince1970: 1_789_776_000), calendar: Calendar = utcCalendar()) -> Arena {
        var arena = seated()
        let nightKey = NightStamp.from(now, calendar: calendar).rawValue
        guard var pack = arena.lockedPack, pack.dares.count >= 2, arena.names.count >= 2 else {
            return arena
        }
        let firstDare = pack.dares[0]
        let secondDare = pack.dares[1]
        pack.nextIndex = 2
        arena.lockedPack = pack

        let first = Forfeit(
            nameID: arena.names[0].id,
            plate: arena.names[0].plate,
            dare: firstDare,
            nightKey: nightKey,
            pinnedAt: now
        )
        let second = Forfeit(
            nameID: arena.names[1].id,
            plate: arena.names[1].plate,
            dare: secondDare,
            nightKey: nightKey,
            pinnedAt: now
        )
        arena.names[0].charge = .charged(slips: [first])
        arena.names[1].charge = .charged(slips: [second])
        arena.nights = [NightLedger(key: nightKey, forfeits: [first, second])]
        return arena
    }

    static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
