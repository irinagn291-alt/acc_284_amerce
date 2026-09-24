import Foundation

/// Role: Arena. Locale numbers for slice counts, stack depth, night keys, and pack fill. Round only here.
@MainActor
enum ParlorFigures {
    static func count(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func nightKey(_ key: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: key)) ?? "0"
    }

    /// Spoken night for chrome. Never the YYYYMMDD storage key.
    static func nightHeading(_ key: Int, calendar: Calendar = .current) -> String {
        guard let date = NightStamp(rawValue: key).startOfDay(calendar: calendar) else {
            return nightTitle(key, calendar: calendar)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return formatter.string(from: date)
    }

    static func landed(_ value: Int) -> String {
        "\(count(value)) landed"
    }

    static func unusedDares(_ value: Int) -> String {
        "\(count(value)) unused dares"
    }

    /// Drop the Clear-button echo so a dare does not read as a state.
    static func spokenDare(_ line: String) -> String {
        let echo = " until Clear"
        guard line.hasSuffix(echo) else { return line }
        return String(line.dropLast(echo.count))
    }

    static func percent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func nightTitle(_ key: Int, calendar: Calendar = .current) -> String {
        guard let date = NightStamp(rawValue: key).startOfDay(calendar: calendar) else {
            return nightKey(key)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
