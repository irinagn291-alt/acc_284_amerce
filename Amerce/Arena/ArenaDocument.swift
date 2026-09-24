import Foundation

/// Role: Arena. Codable envelope for the one Arena document. Domain types never decode this JSON themselves.
struct ArenaDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var names: [Name]
    var lockedPack: Pack?
    var clearMarks: [ClearMark]
    var stackMarks: [StackMark]
    var nights: [NightLedger]
    var hapticsOn: Bool
    var onboardingComplete: Bool
}

enum ArenaCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ arena: Arena) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: arena))
    }

    static func decode(_ data: Data) throws -> Arena {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return arena(from: try decoder.decode(ArenaDocument.self, from: data))
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func document(from arena: Arena) -> ArenaDocument {
        ArenaDocument(
            schemaVersion: currentSchema,
            names: arena.names,
            lockedPack: arena.lockedPack,
            clearMarks: arena.clearMarks,
            stackMarks: arena.stackMarks,
            nights: arena.nights,
            hapticsOn: arena.hapticsOn,
            onboardingComplete: arena.onboardingComplete
        )
    }

    static func arena(from document: ArenaDocument) -> Arena {
        Arena(
            names: document.names,
            lockedPack: document.lockedPack,
            clearMarks: document.clearMarks,
            stackMarks: document.stackMarks,
            nights: document.nights,
            hapticsOn: document.hapticsOn,
            onboardingComplete: document.onboardingComplete
        )
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
