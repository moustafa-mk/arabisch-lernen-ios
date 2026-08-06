import AVFoundation
import Combine
import Foundation

enum SpeechLocale {
    case german
    case msa

    var preferredLanguageCodes: [String] {
        switch self {
        case .german:
            return ["de-DE", "de-AT", "de-CH"]
        case .msa:
            return ["ar-SA", "ar-001", "ar-AE", "ar-EG"]
        }
    }

    var unavailableMessage: String {
        switch self {
        case .german:
            return "Auf diesem Gerät ist keine deutsche Systemstimme verfügbar."
        case .msa:
            return "Auf diesem Gerät ist keine passende arabische Systemstimme verfügbar."
        }
    }
}

enum SpeechVoiceSelector {
    static func bestLanguageCode(
        availableLanguageCodes: [String],
        locale: SpeechLocale
    ) -> String? {
        for preferredCode in locale.preferredLanguageCodes
        where availableLanguageCodes.contains(preferredCode) {
            return preferredCode
        }

        let acceptedPrefixes = Set(
            locale.preferredLanguageCodes.compactMap {
                $0.split(separator: "-").first.map(String.init)
            }
        )
        return availableLanguageCodes.first { languageCode in
            guard let prefix = languageCode.split(separator: "-").first else {
                return false
            }
            return acceptedPrefixes.contains(String(prefix))
        }
    }
}

@MainActor
final class SystemSpeechService: ObservableObject {
    @Published private(set) var message: String?
    private let synthesizer = AVSpeechSynthesizer()

    @discardableResult
    func speak(_ text: String, locale: SpeechLocale) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            message = "Für diese Wiedergabe fehlt Text."
            return false
        }
        guard let voice = voice(for: locale) else {
            message = locale.unavailableMessage
            return false
        }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1
        synthesizer.speak(utterance)
        message = nil
        return true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func voice(for locale: SpeechLocale) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        guard let languageCode = SpeechVoiceSelector.bestLanguageCode(
            availableLanguageCodes: voices.map(\.language),
            locale: locale
        ) else {
            return nil
        }
        return voices.first { $0.language == languageCode }
    }
}
