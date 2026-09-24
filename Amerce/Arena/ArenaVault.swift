import Foundation

/// Role: Arena. Versioned UserDefaults key plus the atomic file projection. Views never touch this.
enum ArenaKey {
    static let document = "amc.document.v1"
    static let backup = "amc.document.v1.backup"
    static let demo = "amc.demo.v1"
}

enum ArenaWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

protocol ArenaPersisting: Sendable {
    func load() async -> (arena: Arena, warning: ArenaWarning?)
    func note(_ arena: Arena) async
    func save(_ arena: Arena) async throws
    func flush() async throws
    func resetAllData() async throws
    func hasDemoSeed() async -> Bool
    func markDemoSeed() async
}

/// Role: Arena. One seam. Memory on the Arena is source of truth; disk and UserDefaults are a projection.
actor ArenaVault: ArenaPersisting {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: Arena?
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Amerce", isDirectory: true)
    }

    func load() async -> (arena: Arena, warning: ArenaWarning?) {
        prepareDirectory()
        if let arena = decode(defaults().data(forKey: ArenaKey.document)) {
            latest = arena
            return (arena, nil)
        }
        if let arena = decodeFile(fileURL()) {
            latest = arena
            return (arena, nil)
        }
        if let arena = decode(defaults().data(forKey: ArenaKey.backup)) {
            latest = arena
            return (arena, .recoveredFromBackup)
        }
        if let arena = decodeFile(backupURL()) {
            latest = arena
            return (arena, .recoveredFromBackup)
        }
        if hasAnyPayload() {
            latest = .empty
            return (.empty, .startedEmpty)
        }
        latest = .empty
        return (.empty, nil)
    }

    func note(_ arena: Arena) async {
        latest = arena
        scheduleFlush()
    }

    func save(_ arena: Arena) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = arena
        try persist(arena)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if let latest {
            try persist(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        lastWriteError = nil
        let defaults = defaults()
        defaults.removeObject(forKey: ArenaKey.document)
        defaults.removeObject(forKey: ArenaKey.backup)
        defaults.synchronize()
        if fileManager.fileExists(atPath: fileURL().path) {
            try fileManager.removeItem(at: fileURL())
        }
        if fileManager.fileExists(atPath: backupURL().path) {
            try fileManager.removeItem(at: backupURL())
        }
    }

    func hasDemoSeed() async -> Bool {
        defaults().object(forKey: ArenaKey.demo) != nil
    }

    func markDemoSeed() async {
        defaults().set(true, forKey: ArenaKey.demo)
        defaults().synchronize()
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persist(_ arena: Arena) throws {
        prepareDirectory()
        let data = try ArenaCodec.encode(arena)
        let defaults = defaults()
        if let previous = defaults.data(forKey: ArenaKey.document) {
            defaults.set(previous, forKey: ArenaKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL().path) {
            try? fileManager.removeItem(at: backupURL())
            try? fileManager.copyItem(at: fileURL(), to: backupURL())
        }
        try data.write(to: fileURL(), options: .atomic)
        defaults.set(data, forKey: ArenaKey.document)
        defaults.synchronize()
        lastWriteError = nil
    }

    private func decode(_ data: Data?) -> Arena? {
        guard let data else { return nil }
        return try? ArenaCodec.decode(data)
    }

    private func decodeFile(_ url: URL) -> Arena? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? ArenaCodec.decode(data)
    }

    private func hasAnyPayload() -> Bool {
        defaults().data(forKey: ArenaKey.document) != nil
            || defaults().data(forKey: ArenaKey.backup) != nil
            || fileManager.fileExists(atPath: fileURL().path)
            || fileManager.fileExists(atPath: backupURL().path)
    }

    private func fileURL() -> URL {
        directory.appendingPathComponent("arena.json")
    }

    private func backupURL() -> URL {
        directory.appendingPathComponent("arena.json.backup")
    }

    private func defaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
