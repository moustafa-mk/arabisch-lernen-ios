import XCTest
@testable import ArabicLearning

final class ReviewSchedulerTests: XCTestCase {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testUnsuccessfulRecallReturnsInTenMinutes() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let result = ReviewScheduler.update(
            exposureCount: 0,
            successfulRecalls: 0,
            cueCount: 0,
            wasCorrect: false,
            usedCue: true,
            now: now,
            calendar: utcCalendar
        )

        XCTAssertEqual(result.exposureCount, 1)
        XCTAssertEqual(result.successfulRecalls, 0)
        XCTAssertEqual(result.cueCount, 1)
        XCTAssertEqual(result.mastery, 0)
        XCTAssertEqual(result.nextReviewAt.timeIntervalSince(now), 600, accuracy: 0.1)
    }

    func testIndependentSuccessExpandsInterval() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let result = ReviewScheduler.update(
            exposureCount: 2,
            successfulRecalls: 2,
            cueCount: 0,
            wasCorrect: true,
            usedCue: false,
            now: now,
            calendar: utcCalendar
        )

        XCTAssertEqual(result.successfulRecalls, 3)
        XCTAssertEqual(result.mastery, 1)
        XCTAssertEqual(result.nextReviewAt.timeIntervalSince(now), 7 * 86_400, accuracy: 0.1)
    }

    func testCueLimitsMasteryAndSchedulesTomorrow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let result = ReviewScheduler.update(
            exposureCount: 1,
            successfulRecalls: 1,
            cueCount: 0,
            wasCorrect: true,
            usedCue: true,
            now: now,
            calendar: utcCalendar
        )

        XCTAssertLessThan(result.mastery, 1)
        XCTAssertEqual(result.nextReviewAt.timeIntervalSince(now), 86_400, accuracy: 0.1)
    }
}
