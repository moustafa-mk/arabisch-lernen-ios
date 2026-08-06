import XCTest
@testable import ArabicLearning

final class CurriculumTests: XCTestCase {
    func testBundledCurriculumIsValidAndComplete() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        XCTAssertEqual(curriculum.version, 1)
        XCTAssertEqual(curriculum.letters.count, 8)
        XCTAssertEqual(curriculum.words.count, 5)
        XCTAssertEqual(
            curriculum.pilotOrder,
            ["baa", "taa", "thaa", "alif", "dal", "raa", "waw", "nun"]
        )
        XCTAssertTrue(CurriculumValidator.validate(curriculum).isEmpty)
    }

    func testEveryPilotLetterHasAWordAndValidContrastGroup() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        for letterID in curriculum.pilotOrder {
            let letter = try XCTUnwrap(curriculum.letter(id: letterID))
            XCTAssertNotNil(curriculum.firstWord(focusingOn: letterID))
            XCTAssertTrue(letter.confusableIDs.contains(letterID))
            XCTAssertGreaterThanOrEqual(letter.confusableIDs.count, 3)
        }
    }

    func testInvalidJSONSurfacesAnExplicitError() {
        let data = Data(#"{"version":1}"#.utf8)

        XCTAssertThrowsError(try CurriculumLoader.decodeAndValidate(data)) { error in
            guard case CurriculumLoadingError.invalidJSON = error else {
                return XCTFail("Expected invalidJSON, got \(error)")
            }
        }
    }
}
