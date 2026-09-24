import Foundation

/// Role: Arena. Sheets over the root wheel. ReviewScreen keys map here. They are not tabs.
enum ParlorSheet: String, Identifiable, Equatable, Sendable {
    case history
    case settings
    case pack

    var id: String { rawValue }

    static func from(stage: ReviewStage) -> ParlorSheet? {
        switch stage {
        case .today:
            nil
        case .log:
            .history
        case .goals:
            .settings
        case .extra(let slug):
            switch slug {
            case "history", "night":
                .history
            case "pack":
                .pack
            case "settings":
                .settings
            default:
                nil
            }
        }
    }
}
