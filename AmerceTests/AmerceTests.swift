import XCTest
@testable import Amerce

final class AmerceTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: AmerceApp.self), "AmerceApp")
    }

    func test_nightStampUsesStartOfDay() {
        let calendar = ArenaSeed.utcCalendar()
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 9
        parts.day = 19
        parts.hour = 23
        parts.minute = 40
        let date = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        XCTAssertEqual(NightStamp.from(date, calendar: calendar).rawValue, 20260919)
        XCTAssertEqual(NightStamp.from(date, calendar: calendar).startOfDay(calendar: calendar), calendar.startOfDay(for: date))
    }

    @MainActor
    func test_nightHeadingNeverPrintsStorageKey() {
        let calendar = ArenaSeed.utcCalendar()
        let heading = ParlorFigures.nightHeading(20260920, calendar: calendar)
        XCTAssertFalse(heading.contains("20260920"))
        XCTAssertTrue(heading.contains("Sep"))
        XCTAssertEqual(ParlorFigures.spokenDare("Surrender a glove until Clear"), "Surrender a glove")
        XCTAssertEqual(ParlorFigures.landed(2), "2 landed")
        XCTAssertEqual(ParlorFigures.unusedDares(3), "3 unused dares")
    }
}
