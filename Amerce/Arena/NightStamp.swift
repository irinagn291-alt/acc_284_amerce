import Foundation

/// Role: Arena. Day identity as YYYYMMDD Int from Calendar.startOfDay. Never a Date dictionary key.
struct NightStamp: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    var rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> NightStamp {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return NightStamp(rawValue: year * 10_000 + month * 100 + day)
    }

    func startOfDay(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = rawValue / 10_000
        parts.month = (rawValue / 100) % 100
        parts.day = rawValue % 100
        guard let built = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: built)
    }

    static func < (lhs: NightStamp, rhs: NightStamp) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
