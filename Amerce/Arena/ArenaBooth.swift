import Foundation

/// Role: Arena. Live vault wiring. Views never build FileManager paths themselves.
@MainActor
enum ArenaBooth {
    static func live() -> ArenaStore {
        let directory: URL
        if let support = try? ArenaVault.applicationSupportDirectory() {
            directory = support
        } else {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("Amerce", isDirectory: true)
        }
        return ArenaStore(vault: ArenaVault(directory: directory))
    }

    static func previewCharged() -> ArenaStore {
        let arena = ArenaSeed.charged()
        let store = ArenaStore(vault: ArenaMemory(arena: arena, demoSeeded: true))
        store.install(arena)
        return store
    }

    static func previewEmpty() -> ArenaStore {
        let store = ArenaStore(vault: ArenaMemory(arena: .empty))
        store.install(.empty)
        return store
    }
}
