import Foundation

struct Curriculum: Codable, Sendable {
    let version: Int
    let pilotOrder: [String]
    let letters: [LetterContent]
    let words: [WordContent]

    var lettersByID: [String: LetterContent] {
        Dictionary(uniqueKeysWithValues: letters.map { ($0.id, $0) })
    }

    var wordsByID: [String: WordContent] {
        Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
    }

    func letter(id: String) -> LetterContent? {
        lettersByID[id]
    }

    func firstWord(focusingOn letterID: String) -> WordContent? {
        words.first { $0.focusLetterIDs.contains(letterID) }
    }
}

struct LetterContent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let glyph: String
    let nameGerman: String
    let nameArabic: String
    let transliteration: String
    let phoneme: String
    let phonemeSpeechText: String
    let joinsFollowing: Bool
    let forms: LetterForms
    let confusableIDs: [String]
    let memoryHintGerman: String
    let strokePaths: [StrokePath]
}

struct LetterForms: Codable, Hashable, Sendable {
    let isolated: String
    let initial: String?
    let medial: String?
    let final: String?

    var labelledForms: [LabelledLetterForm] {
        var result = [LabelledLetterForm(label: "Allein", glyph: isolated)]
        if let initial {
            result.append(LabelledLetterForm(label: "Am Anfang", glyph: initial))
        }
        if let medial {
            result.append(LabelledLetterForm(label: "In der Mitte", glyph: medial))
        }
        if let final {
            result.append(LabelledLetterForm(label: "Am Ende", glyph: final))
        }
        return result
    }
}

struct LabelledLetterForm: Identifiable, Hashable, Sendable {
    let label: String
    let glyph: String

    var id: String { label }
}

struct StrokePath: Codable, Hashable, Sendable {
    let points: [StrokePoint]
}

struct StrokePoint: Codable, Hashable, Sendable {
    let x: Double
    let y: Double
}

struct WordContent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let arabicVowelized: String
    let arabicUnvowelized: String
    let german: String
    let msaTransliteration: String
    let msaSpeechText: String
    let syrianText: String
    let syrianTransliteration: String
    let bridgeNoteGerman: String
    let letterIDs: [String]
    let focusLetterIDs: [String]
}
