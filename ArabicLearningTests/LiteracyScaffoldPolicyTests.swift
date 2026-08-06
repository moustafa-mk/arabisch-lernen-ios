import XCTest
@testable import ArabicLearning

final class LiteracyScaffoldPolicyTests: XCTestCase {
    func testTransliterationFadesAfterTwoSuccessfulRecalls() {
        XCTAssertTrue(
            LiteracyScaffoldPolicy.showsTransliterationByDefault(
                preferenceEnabled: true,
                successfulRecalls: 1
            )
        )
        XCTAssertFalse(
            LiteracyScaffoldPolicy.showsTransliterationByDefault(
                preferenceEnabled: true,
                successfulRecalls: 2
            )
        )
    }

    func testTransliterationPreferenceCanHideTheInitialScaffold() {
        XCTAssertFalse(
            LiteracyScaffoldPolicy.showsTransliterationByDefault(
                preferenceEnabled: false,
                successfulRecalls: 0
            )
        )
    }

    func testDiacriticsFadeLaterThanTransliteration() {
        XCTAssertTrue(
            LiteracyScaffoldPolicy.showsDiacriticsByDefault(successfulRecalls: 3)
        )
        XCTAssertFalse(
            LiteracyScaffoldPolicy.showsDiacriticsByDefault(successfulRecalls: 4)
        )
    }
}
