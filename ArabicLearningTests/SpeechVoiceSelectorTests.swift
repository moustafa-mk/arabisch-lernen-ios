import XCTest
@testable import ArabicLearning

final class SpeechVoiceSelectorTests: XCTestCase {
    func testPrefersConfiguredMSAVoice() {
        let result = SpeechVoiceSelector.bestLanguageCode(
            availableLanguageCodes: ["en-US", "ar-EG", "ar-SA"],
            locale: .msa
        )

        XCTAssertEqual(result, "ar-SA")
    }

    func testFallsBackOnlyWithinTheRequestedLanguage() {
        let result = SpeechVoiceSelector.bestLanguageCode(
            availableLanguageCodes: ["en-US", "fr-FR", "ar-MA"],
            locale: .msa
        )

        XCTAssertEqual(result, "ar-MA")
    }

    func testDoesNotSubstituteAnUnrelatedLanguage() {
        let result = SpeechVoiceSelector.bestLanguageCode(
            availableLanguageCodes: ["en-US", "fr-FR"],
            locale: .german
        )

        XCTAssertNil(result)
    }
}
