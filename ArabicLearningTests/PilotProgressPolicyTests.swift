import XCTest
@testable import ArabicLearning

final class PilotProgressPolicyTests: XCTestCase {
    func testFinishingLessonAdvancesToNextLetterWithoutRequiringMastery() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = [
            "baa": PilotLetterProgress(
                exposureCount: 1,
                mastery: 0,
                nextReviewAt: now.addingTimeInterval(-60)
            )
        ]

        XCTAssertEqual(
            PilotProgressPolicy.completedCount(
                pilotOrder: ["baa", "taa", "thaa"],
                progressByID: progress
            ),
            1
        )
        XCTAssertEqual(
            PilotProgressPolicy.recommendedLetterID(
                pilotOrder: ["baa", "taa", "thaa"],
                progressByID: progress,
                now: now
            ),
            "taa"
        )
    }

    func testDueReviewIsRecommendedAfterAllLettersWereIntroduced() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let progress = [
            "baa": PilotLetterProgress(
                exposureCount: 1,
                mastery: 0,
                nextReviewAt: now.addingTimeInterval(-60)
            ),
            "taa": PilotLetterProgress(
                exposureCount: 1,
                mastery: 1,
                nextReviewAt: now.addingTimeInterval(86_400)
            )
        ]

        XCTAssertEqual(
            PilotProgressPolicy.recommendedLetterID(
                pilotOrder: ["baa", "taa"],
                progressByID: progress,
                now: now
            ),
            "baa"
        )
    }
}
