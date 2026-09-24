import XCTest
@testable import Amerce

final class ArenaVaultTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar {
        ArenaSeed.utcCalendar()
    }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "amc.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTripReloadPreservesChargeAndNightKey() async throws {
        let vault = makeVault()
        let now = Date(timeIntervalSince1970: 1_789_776_000)
        var arena = ArenaSeed.seated()
        arena = try ArenaFold.pinForfeit(
            on: arena,
            pick: { _ in 0 },
            extraTurns: 6,
            now: now,
            calendar: calendar
        ).arena
        try await vault.save(arena)

        let loaded = await makeVault().load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.arena.names.map(\.plate), ["Harriet", "Oswald", "Celia", "Bram"])
        XCTAssertTrue(loaded.arena.names[0].charge.isCharged)
        XCTAssertEqual(loaded.arena.nights.first?.key, 20260919)
        XCTAssertEqual(loaded.arena.nights.first?.forfeits.map(\.plate), ["Harriet"])
        XCTAssertTrue(loaded.arena.onboardingComplete)
        XCTAssertNotNil(defaults.data(forKey: ArenaKey.document))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("arena.json").path))
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let vault = makeVault()
        try await vault.save(ArenaSeed.seated())
        if let good = defaults.data(forKey: ArenaKey.document) {
            defaults.set(good, forKey: ArenaKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: ArenaKey.document)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("arena.json"))

        let loaded = await makeVault().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.arena.names.map(\.plate), ["Harriet", "Oswald", "Celia", "Bram"])
    }

    func test_corruptWithoutBackupStartsEmpty() async throws {
        defaults.set(Data("nope".utf8), forKey: ArenaKey.document)
        let loaded = await makeVault().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.arena.names.isEmpty)
    }

    func test_resetAllDataClearsDocument() async throws {
        let vault = makeVault()
        try await vault.save(ArenaSeed.seated())
        try await vault.resetAllData()
        let loaded = await vault.load()
        XCTAssertTrue(loaded.arena.names.isEmpty)
        XCTAssertNil(defaults.data(forKey: ArenaKey.document))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("arena.json").path))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let data = try ArenaCodec.encode(ArenaSeed.seated())
        let decoded = try ArenaCodec.decode(data)
        XCTAssertEqual(decoded.names.count, 4)
        XCTAssertThrowsError(try ArenaCodec.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? ArenaCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try ArenaCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? ArenaCodec.Failure, .corrupt)
        }
    }

    @MainActor
    func test_storePinAndReloadThroughVault() async throws {
        let vault = makeVault()
        let store = ArenaStore(vault: vault, calendar: calendar)
        try store.seat("Harriet")
        try store.seat("Oswald")
        try store.lockPack(
            Pack(title: "Wax parlor slips", dares: [Dare(line: "Bow to the nearest lamp"), Dare(line: "Hum eight bars of a waltz")])
        )
        _ = try store.pinForfeit(pick: { _ in 0 }, extraTurns: 6, now: Date(timeIntervalSince1970: 1_789_776_000))
        await store.flush()

        let relaunched = ArenaStore(vault: makeVault(), calendar: calendar)
        await relaunched.load()
        XCTAssertTrue(relaunched.arena.names[0].charge.isCharged)
        XCTAssertEqual(relaunched.arena.names.map(\.plate), ["Harriet", "Oswald"])
        XCTAssertTrue(relaunched.canPin)
    }

    #if targetEnvironment(simulator)
    @MainActor
    func test_simulatorSeedWritesOnce() async {
        let vault = makeVault()
        let store = ArenaStore(vault: vault, calendar: calendar)
        await store.seedDemoIfNeeded()
        await store.seedDemoIfNeeded()
        XCTAssertEqual(store.arena.names.map(\.plate), ["Harriet", "Oswald", "Celia", "Bram"])
        XCTAssertEqual(store.arena.lockedPack?.title, "Wax parlor slips")
        XCTAssertEqual(store.arena.openForfeits.count, 2)
        XCTAssertEqual(store.arena.nights.first?.key, 20260919)
        XCTAssertTrue(store.arena.onboardingComplete)
        XCTAssertTrue(store.canPin)
        XCTAssertTrue(defaults.bool(forKey: ArenaKey.demo))
    }
    #endif

    @MainActor
    func test_storeEmptyPopulatedInvalidPin() async {
        let store = ArenaStore(vault: makeVault(), calendar: calendar)
        XCTAssertThrowsError(try store.pinForfeit(pick: { _ in 0 }, extraTurns: 6)) { error in
            XCTAssertEqual(error as? ArenaFault, .bare)
        }
        XCTAssertNoThrow(try store.seat("Harriet"))
        XCTAssertNoThrow(try store.seat("Oswald"))
        XCTAssertNoThrow(try store.lockPack(Pack(title: "Slips", dares: [Dare(line: "Bow to the nearest lamp"), Dare(line: "Hum eight bars of a waltz")])))
        XCTAssertNoThrow(try store.pinForfeit(pick: { _ in 0 }, extraTurns: 6))
        XCTAssertThrowsError(try store.pinForfeit(pick: { _ in 4 }, extraTurns: 6)) { error in
            XCTAssertEqual(error as? ArenaFault, .badPick)
        }
    }

    private func makeVault() -> ArenaVault {
        ArenaVault(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }
}
