import Foundation
import Observation

/// Role: Arena. Owns the in-memory fold. Views call methods; they never touch UserDefaults or FileManager.
@MainActor
@Observable
final class ArenaStore {
    private(set) var arena: Arena
    private(set) var warning: ArenaWarning?
    private(set) var lastWriteError: String?
    private(set) var lastPin: PinFold?
    private(set) var lastClear: ClearFold?

    private let vault: any ArenaPersisting
    private let calendar: Calendar

    init(vault: any ArenaPersisting, calendar: Calendar = .current) {
        self.vault = vault
        self.calendar = calendar
        self.arena = .empty
    }

    var canPin: Bool { arena.canPin }

    func load() async {
        let loaded = await vault.load()
        arena = loaded.arena
        warning = loaded.warning
        lastWriteError = nil
    }

    func install(_ arena: Arena, warning: ArenaWarning? = nil, writeError: String? = nil) {
        self.arena = arena
        self.warning = warning
        lastWriteError = writeError
        lastPin = nil
        lastClear = nil
    }

    func seat(_ plate: String) throws {
        arena = try ArenaFold.seat(plate, onto: arena)
        persistSoon()
    }

    func unseat(_ id: UUID) throws {
        arena = try ArenaFold.unseat(id, from: arena)
        persistSoon()
    }

    func lockPack(_ pack: Pack) throws {
        arena = try ArenaFold.lockPack(pack, onto: arena)
        persistSoon()
    }

    func pinForfeit(
        pick: (Int) -> Int = { count in
            guard count > 0 else { return 0 }
            return Int.random(in: 0 ..< count)
        },
        extraTurns: Int = Int.random(in: WheelTurn.extraTurnBounds),
        now: Date = Date()
    ) throws -> PinFold {
        let fold = try ArenaFold.pinForfeit(
            on: arena,
            pick: pick,
            extraTurns: extraTurns,
            now: now,
            calendar: calendar
        )
        arena = fold.arena
        lastPin = fold
        persistSoon()
        return fold
    }

    func clearForfeit(nameID: UUID, now: Date = Date()) throws -> ClearFold {
        let fold = try ArenaFold.clearForfeit(
            nameID: nameID,
            on: arena,
            now: now,
            calendar: calendar
        )
        arena = fold.arena
        lastClear = fold
        persistSoon()
        return fold
    }

    func markOnboardingComplete() {
        arena.onboardingComplete = true
        persistSoon()
    }

    func reopenOnboarding() {
        arena.onboardingComplete = false
        persistSoon()
    }

    func setHaptics(_ on: Bool) {
        arena.hapticsOn = on
        persistSoon()
    }

    func flush() async {
        do {
            try await vault.save(arena)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func resetAllData() async {
        do {
            try await vault.resetAllData()
        } catch {
            lastWriteError = String(describing: error)
        }
        arena = .empty
        warning = nil
        lastPin = nil
        lastClear = nil
    }

    func seedDemoIfNeeded() async {
        #if targetEnvironment(simulator)
        if await vault.hasDemoSeed() { return }
        arena = ArenaSeed.charged()
        do {
            try await vault.save(arena)
            await vault.markDemoSeed()
        } catch {
            lastWriteError = String(describing: error)
        }
        #endif
    }

    private func persistSoon() {
        let snapshot = arena
        Task { await vault.note(snapshot) }
    }
}
