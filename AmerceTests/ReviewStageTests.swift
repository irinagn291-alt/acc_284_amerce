import XCTest
@testable import Amerce

final class ReviewStageTests: XCTestCase {
    func test_parseTodayLogGoalsAndExtraSlugs() {
        XCTAssertEqual(ReviewStage.parse("today"), .today)
        XCTAssertEqual(ReviewStage.parse("log"), .log)
        XCTAssertEqual(ReviewStage.parse("goals"), .goals)
        XCTAssertEqual(ReviewStage.parse("history"), .extra("history"))
        XCTAssertEqual(ReviewStage.parse("pack"), .extra("pack"))
        XCTAssertNil(ReviewStage.parse(""))
    }

    func test_consumeReadsOnceAfterOnboarding() {
        var consumed = false
        let arguments = ["Amerce", "-ReviewScreen", "log"]
        let first = ReviewStage.consume(
            arguments: arguments,
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)
        let second = ReviewStage.consume(
            arguments: arguments,
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(second)
    }

    func test_consumeIgnoresHookBeforeOnboarding() {
        var consumed = false
        let stage = ReviewStage.consume(
            arguments: ["-ReviewScreen", "today"],
            onboardingComplete: false,
            consumed: &consumed
        )
        XCTAssertNil(stage)
        XCTAssertFalse(consumed)
    }

    func test_consumeLiveReadsProcessInfoAfterOnboarding() {
        var consumed = false
        XCTAssertNil(ReviewStage.consumeLive(onboardingComplete: false, consumed: &consumed))
        XCTAssertFalse(consumed)
        let live = ReviewStage.consumeLive(onboardingComplete: true, consumed: &consumed)
        XCTAssertTrue(consumed)
        if ProcessInfo.processInfo.arguments.contains("-ReviewScreen") {
            XCTAssertNotNil(live)
        } else {
            XCTAssertNil(live)
        }
    }

    func test_goalsAndTodayAreDifferentKeys() {
        var consumed = false
        XCTAssertEqual(
            ReviewStage.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
        consumed = false
        XCTAssertEqual(
            ReviewStage.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
    }

    func test_reviewKeysMapToDifferentSheets() {
        XCTAssertNil(ParlorSheet.from(stage: .today))
        XCTAssertEqual(ParlorSheet.from(stage: .log), .history)
        XCTAssertEqual(ParlorSheet.from(stage: .goals), .settings)
        XCTAssertEqual(ParlorSheet.from(stage: .extra("pack")), .pack)
        XCTAssertEqual(ParlorSheet.from(stage: .extra("history")), .history)
        XCTAssertEqual(ParlorSheet.from(stage: .extra("settings")), .settings)
        XCTAssertNil(ParlorSheet.from(stage: .extra("unknown")))
    }
}
