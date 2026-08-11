import CoreGraphics
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

    func testHomeworkWorkbookContainsOnePagePerAlphabetLetter() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        let data = try PracticeSheetRenderer.renderWorkbook(curriculum: curriculum)
        let provider = try XCTUnwrap(CGDataProvider(data: data as CFData))
        let document = try XCTUnwrap(CGPDFDocument(provider))

        XCTAssertGreaterThan(data.count, 20_000)
        XCTAssertEqual(String(decoding: data.prefix(4), as: UTF8.self), "%PDF")
        XCTAssertEqual(document.numberOfPages, curriculum.alphabetOrder.count)
    }

    func testEveryAvailableLetterFormHasAHandwritingProfile() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        for letter in curriculum.letters {
            XCTAssertEqual(
                ArabicHandwritingProfiles.missingProfiles(for: letter),
                [],
                "Missing handwriting profile for \(letter.id)"
            )
        }
    }

    func testJoiningAndNonJoiningLettersReceiveFourPracticeRows() throws {
        let curriculum = try CurriculumLoader.loadBundled()
        let baa = try XCTUnwrap(curriculum.letter(id: "baa"))
        let alif = try XCTUnwrap(curriculum.letter(id: "alif"))

        XCTAssertEqual(
            PracticeSheetRenderer.practiceFormKinds(for: baa),
            [.isolated, .initial, .medial, .final]
        )
        XCTAssertEqual(
            PracticeSheetRenderer.practiceFormKinds(for: alif),
            [.isolated, .isolated, .final, .final]
        )
    }

    func testRepresentativeFormsUseDifferentBaselineClasses() throws {
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "baa", formKind: .isolated),
            .onBaselineWithDotsBelow
        )
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "jim", formKind: .isolated),
            .descenderWithDotsBelow
        )
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "jim", formKind: .initial),
            .onBaselineWithDotsBelow
        )
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "raa", formKind: .isolated),
            .descender
        )
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "hah", formKind: .medial),
            .crossing
        )
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "yaa", formKind: .isolated),
            .descenderWithDotsBelow
        )
        XCTAssertEqual(
            ArabicHandwritingProfiles.profile(letterID: "yaa", formKind: .medial),
            .onBaselineWithDotsBelow
        )
    }

    func testEveryTracingGlyphFitsInsideItsPracticeRow() throws {
        let curriculum = try CurriculumLoader.loadBundled()

        for letter in curriculum.letters {
            for form in letter.forms.labelledForms {
                let bounds = try PracticeSheetRenderer.practiceGlyphBounds(
                    letter: letter,
                    formKind: form.kind
                )
                XCTAssertGreaterThanOrEqual(
                    bounds.minY,
                    0,
                    "\(letter.id) \(form.kind.rawValue) rises outside its row"
                )
                XCTAssertLessThanOrEqual(
                    bounds.maxY,
                    PracticeSheetRenderer.practiceRowHeight,
                    "\(letter.id) \(form.kind.rawValue) descends outside its row"
                )
            }
        }
    }
}
