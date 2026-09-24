import Foundation

/// Role: Arena. In-process vault for fixtures and tests. Views never persist through this.
actor ArenaMemory: ArenaPersisting {
    private var arena: Arena
    private var demo: Bool

    init(arena: Arena = .empty, demoSeeded: Bool = false) {
        self.arena = arena
        self.demo = demoSeeded
    }

    func load() async -> (arena: Arena, warning: ArenaWarning?) {
        (arena, nil)
    }

    func note(_ arena: Arena) async {
        self.arena = arena
    }

    func save(_ arena: Arena) async throws {
        self.arena = arena
    }

    func flush() async throws {}

    func resetAllData() async throws {
        arena = .empty
    }

    func hasDemoSeed() async -> Bool {
        demo
    }

    func markDemoSeed() async {
        demo = true
    }
}
