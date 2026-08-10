import XCTest
@testable import ArabicLearning

final class AlphabetProgressPolicyTests: XCTestCase {
    func testFinishingLessonAdvancesToNextLetterWithoutRequiringMastery() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = [
            "baa": AlphabetLetterProgress(
                exposureCount: 1,
                mastery: 0,
                nextReviewAt: now.addingTimeInterval(-60)
            )
        ]

        XCTAssertEqual(
            AlphabetProgressPolicy.completedCount(
                alphabetOrder: ["baa", "taa", "thaa"],
                progressByID: progress
            ),
            1
        )
        XCTAssertEqual(
            AlphabetProgressPolicy.recommendedLetterID(
                alphabetOrder: ["baa", "taa", "thaa"],
                progressByID: progress,
                now: now
            ),
            "taa"
        )
    }

    func testDueReviewIsRecommendedAfterAllLettersWereIntroduced() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = [
            "baa": AlphabetLetterProgress(
                exposureCount: 1,
                mastery: 0,
                nextReviewAt: now.addingTimeInterval(-60)
            ),
            "taa": AlphabetLetterProgress(
                exposureCount: 1,
                mastery: 1,
                nextReviewAt: now.addingTimeInterval(86_400)
            )
        ]

        XCTAssertEqual(
            AlphabetProgressPolicy.recommendedLetterID(
                alphabetOrder: ["baa", "taa"],
                progressByID: progress,
                now: now
            ),
            "baa"
        )
    }
}
