import XCTest
@testable import ArabicLearning

final class CurriculumTests: XCTestCase {
    func testBundledCurriculumContainsCompleteAlphabet() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        XCTAssertEqual(curriculum.version, 2)
        XCTAssertEqual(curriculum.letters.count, 28)
        XCTAssertEqual(curriculum.words.count, 17)
        XCTAssertEqual(
            curriculum.alphabetOrder,
            [
                "alif", "baa", "taa", "thaa", "jim", "haa", "khaa",
                "dal", "dhal", "raa", "zay", "sin", "shin", "saad",
                "daad", "ttaa", "zzaa", "ayn", "ghayn", "faa", "qaf",
                "kaf", "lam", "mim", "nun", "hah", "waw", "yaa"
            ]
        )
        XCTAssertEqual(curriculum.letters.map(\.id), curriculum.alphabetOrder)
        XCTAssertTrue(CurriculumValidator.validate(curriculum).isEmpty)
    }

    func testEveryLetterHasAWordAndValidContrastGroup() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        for letterID in curriculum.alphabetOrder {
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
