import XCTest
@testable import ArabicLearning

final class PracticeSheetRendererTests: XCTestCase {
    func testPracticeSheetProducesPDFData() throws {
        let curriculum = try CurriculumLoader.loadBundled()
        let letter = try XCTUnwrap(curriculum.letter(id: "baa"))
        let word = try XCTUnwrap(curriculum.wordsByID["bab"])

        let data = try PracticeSheetRenderer.render(letter: letter, word: word)

        XCTAssertGreaterThan(data.count, 1_000)
        XCTAssertEqual(String(decoding: data.prefix(4), as: UTF8.self), "%PDF")
    }
}
