import XCTest
@testable import ArabicLearning

final class AccessibilityPreferenceTests: XCTestCase {
    func testCalmModeDisablesInstructionalAnimation() {
        XCTAssertFalse(
            AccessibilityPreferenceResolver.allowsInstructionalAnimation(
                calmMode: true,
                systemReduceMotion: false
            )
        )
    }

    func testSystemReduceMotionDisablesInstructionalAnimation() {
        XCTAssertFalse(
            AccessibilityPreferenceResolver.allowsInstructionalAnimation(
                calmMode: false,
                systemReduceMotion: true
            )
        )
    }

    func testAnimationRunsOnlyWhenBothPreferencesAllowIt() {
        XCTAssertTrue(
            AccessibilityPreferenceResolver.allowsInstructionalAnimation(
                calmMode: false,
                systemReduceMotion: false
            )
        )
    }
}
