import Foundation

enum CurriculumLoadingError: LocalizedError {
    case resourceMissing
    case unreadableResource(underlying: Error)
    case invalidJSON(underlying: Error)
    case invalidContent([String])

    var errorDescription: String? {
        switch self {
        case .resourceMissing:
            return "Die lokalen Lerninhalte fehlen. Bitte installiere die App erneut."
        case .unreadableResource:
            return "Die lokalen Lerninhalte konnten nicht gelesen werden."
        case .invalidJSON:
            return "Die lokalen Lerninhalte haben ein ungültiges Format."
        case let .invalidContent(issues):
            return "Die lokalen Lerninhalte sind unvollständig: \(issues.joined(separator: " "))"
        }
    }
}

enum CurriculumLoader {
    static func loadBundled(bundle: Bundle = .main) throws -> Curriculum {
        guard let url = bundle.url(forResource: "Curriculum", withExtension: "json") else {
            throw CurriculumLoadingError.resourceMissing
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CurriculumLoadingError.unreadableResource(underlying: error)
        }

        return try decodeAndValidate(data)
    }

    static func decodeAndValidate(_ data: Data) throws -> Curriculum {
        let curriculum: Curriculum
        do {
            curriculum = try JSONDecoder().decode(Curriculum.self, from: data)
        } catch {
            throw CurriculumLoadingError.invalidJSON(underlying: error)
        }

        let issues = CurriculumValidator.validate(curriculum)
        guard issues.isEmpty else {
            throw CurriculumLoadingError.invalidContent(issues)
        }
        return curriculum
    }
}

enum CurriculumValidator {
    static func validate(_ curriculum: Curriculum) -> [String] {
        var issues: [String] = []
        guard curriculum.version > 0 else {
            return ["Die Inhaltsversion muss größer als 0 sein."]
        }

        let letterIDs = curriculum.letters.map(\.id)
        let uniqueLetterIDs = Set(letterIDs)
        if letterIDs.isEmpty {
            issues.append("Der Pilot benötigt mindestens einen Buchstaben.")
        }
        if uniqueLetterIDs.count != letterIDs.count {
            issues.append("Buchstaben-IDs müssen eindeutig sein.")
        }
        if Set(curriculum.pilotOrder) != uniqueLetterIDs {
            issues.append("Die Pilot-Reihenfolge muss jeden Buchstaben genau einmal enthalten.")
        }

        for letter in curriculum.letters {
            if letter.glyph.isEmpty || letter.nameGerman.isEmpty || letter.nameArabic.isEmpty {
                issues.append("Buchstabe \(letter.id) benötigt Zeichen und Namen.")
            }
            if letter.strokePaths.isEmpty || letter.strokePaths.contains(where: { $0.points.count < 2 }) {
                issues.append("Buchstabe \(letter.id) benötigt gültige Schreibpfade.")
            }
            if !letter.joinsFollowing && (letter.forms.initial != nil || letter.forms.medial != nil) {
                issues.append("Nicht verbindender Buchstabe \(letter.id) darf keine Anfangs- oder Mittelform haben.")
            }
            let unknownConfusables = Set(letter.confusableIDs).subtracting(uniqueLetterIDs)
            if !unknownConfusables.isEmpty {
                issues.append("Buchstabe \(letter.id) verweist auf unbekannte Kontrastbuchstaben.")
            }
            if !letter.confusableIDs.contains(letter.id) {
                issues.append("Kontrastgruppe für \(letter.id) muss den Zielbuchstaben enthalten.")
            }
        }

        let wordIDs = curriculum.words.map(\.id)
        if wordIDs.isEmpty {
            issues.append("Der Pilot benötigt mindestens ein Wort.")
        }
        if Set(wordIDs).count != wordIDs.count {
            issues.append("Wort-IDs müssen eindeutig sein.")
        }
        for word in curriculum.words {
            if word.arabicVowelized.isEmpty || word.german.isEmpty || word.msaSpeechText.isEmpty {
                issues.append("Wort \(word.id) benötigt arabischen und deutschen Inhalt.")
            }
            if !Set(word.letterIDs).isSubset(of: uniqueLetterIDs) {
                issues.append("Wort \(word.id) enthält unbekannte Buchstaben.")
            }
            if word.focusLetterIDs.isEmpty || !Set(word.focusLetterIDs).isSubset(of: Set(word.letterIDs)) {
                issues.append("Wort \(word.id) benötigt gültige Fokusbuchstaben.")
            }
        }

        let coveredLetters = Set(curriculum.words.flatMap(\.focusLetterIDs))
        if !uniqueLetterIDs.isSubset(of: coveredLetters) {
            issues.append("Jeder Pilotbuchstabe benötigt mindestens ein Fokuswort.")
        }
        return issues
    }
}
