import Foundation
import UIKit

enum PracticeSheetError: LocalizedError {
    case invalidPageBounds
    case writeFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidPageBounds:
            return "Das Übungsblatt konnte nicht angelegt werden."
        case .writeFailed:
            return "Das Übungsblatt konnte nicht gespeichert werden."
        }
    }
}

enum PracticeSheetRenderer {
    static func render(letter: LetterContent, word: WordContent?) throws -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        guard pageBounds.width > 0, pageBounds.height > 0 else {
            throw PracticeSheetError.invalidPageBounds
        }

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            context.beginPage()

            let title = "Arabisch schreiben: \(letter.nameGerman)"
            title.draw(
                in: CGRect(x: 48, y: 42, width: 499, height: 42),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.label
                ]
            )

            let instruction = "Schreibe von rechts nach links. Die grauen Formen sind eine Hilfe; eine andere sinnvolle Strichfolge ist kein Fehler."
            instruction.draw(
                in: CGRect(x: 48, y: 88, width: 499, height: 58),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkGray
                ]
            )

            let glyphAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 76),
                .foregroundColor: UIColor(white: 0.72, alpha: 1)
            ]
            for row in 0..<4 {
                let y = 164 + CGFloat(row) * 132
                let lineRect = CGRect(x: 48, y: y + 98, width: 499, height: 1)
                UIColor(white: 0.82, alpha: 1).setFill()
                context.cgContext.fill(lineRect)

                for column in 0..<5 {
                    let x = 463 - CGFloat(column) * 102
                    letter.glyph.draw(
                        in: CGRect(x: x, y: y, width: 84, height: 96),
                        withAttributes: glyphAttributes
                    )
                }
            }

            if let word {
                let wordTitle = "Im Wort: \(word.german)"
                wordTitle.draw(
                    in: CGRect(x: 48, y: 704, width: 220, height: 30),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                        .foregroundColor: UIColor.label
                    ]
                )
                word.arabicVowelized.draw(
                    in: CGRect(x: 300, y: 680, width: 247, height: 70),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 44),
                        .foregroundColor: UIColor.label,
                        .writingDirection: [NSWritingDirection.rightToLeft.rawValue]
                    ]
                )
            }
        }
    }

    static func writeTemporarySheet(letter: LetterContent, word: WordContent?) throws -> URL {
        let data = try render(letter: letter, word: word)
        let safeID = letter.id.replacingOccurrences(
            of: "[^A-Za-z0-9_-]",
            with: "-",
            options: .regularExpression
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Arabisch-\(safeID)-Uebungsblatt.pdf")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PracticeSheetError.writeFailed(underlying: error)
        }
        return url
    }
}
