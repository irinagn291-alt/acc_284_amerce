import Foundation

/// Role: Arena. ReviewScreen launch argument. Read once, only after onboarding. Keys are not tabs.
enum ReviewStage: Equatable, Sendable {
    case today
    case log
    case goals
    case extra(String)

    static func parse(_ raw: String) -> ReviewStage? {
        switch raw {
        case "today":
            .today
        case "log":
            .log
        case "goals":
            .goals
        default:
            raw.isEmpty ? nil : .extra(raw)
        }
    }

    static func consume(
        arguments: [String],
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> ReviewStage? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return parse(arguments[next])
    }

    /// Live launch. Reads ProcessInfo once after onboarding so shots can open today|log|goals.
    static func consumeLive(onboardingComplete: Bool, consumed: inout Bool) -> ReviewStage? {
        consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboardingComplete: onboardingComplete,
            consumed: &consumed
        )
    }
}
