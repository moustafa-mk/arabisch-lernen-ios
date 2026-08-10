import Foundation
import UIKit

enum PracticeSheetError: LocalizedError {
    case invalidPageBounds
    case emptyWorkbook
    case missingLetter
    case missingFocusWord(letterName: String)
    case writeFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidPageBounds:
            return "Das Übungsblatt konnte nicht angelegt werden."
        case .emptyWorkbook:
            return "Das Hausaufgabenheft benötigt mindestens eine Lektion."
        case .missingLetter:
            return "Ein Buchstabe für das Hausaufgabenheft fehlt."
        case let .missingFocusWord(letterName):
            return "Für \(letterName) fehlt ein Beispielwort im Hausaufgabenheft."
        case .writeFailed:
            return "Das Übungsblatt konnte nicht gespeichert werden."
        }
    }
}

enum PracticeSheetRenderer {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)

    private struct Sheet {
        let letter: LetterContent
        let word: WordContent?
        let pageNumber: Int?
        let pageCount: Int?
    }

    static func render(letter: LetterContent, word: WordContent?) throws -> Data {
        try render([
            Sheet(letter: letter, word: word, pageNumber: nil, pageCount: nil)
        ])
    }

    static func renderWorkbook(curriculum: Curriculum) throws -> Data {
        guard !curriculum.alphabetOrder.isEmpty else {
            throw PracticeSheetError.emptyWorkbook
        }

        let pageCount = curriculum.alphabetOrder.count
        let sheets = try curriculum.alphabetOrder.enumerated().map { index, letterID in
            guard let letter = curriculum.letter(id: letterID) else {
                throw PracticeSheetError.missingLetter
            }
            guard let word = curriculum.firstWord(focusingOn: letterID) else {
                throw PracticeSheetError.missingFocusWord(letterName: letter.nameGerman)
            }
            return Sheet(
                letter: letter,
                word: word,
                pageNumber: index + 1,
                pageCount: pageCount
            )
        }
        return try render(sheets)
    }

    private static func render(_ sheets: [Sheet]) throws -> Data {
        guard pageBounds.width > 0, pageBounds.height > 0 else {
            throw PracticeSheetError.invalidPageBounds
        }
        guard !sheets.isEmpty else {
            throw PracticeSheetError.emptyWorkbook
        }

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            for sheet in sheets {
                context.beginPage()
                drawPage(sheet, context: context)
            }
        }
    }

    private static func drawPage(_ sheet: Sheet, context: UIGraphicsPDFRendererContext) {
        let title = "Arabisch schreiben: \(sheet.letter.nameGerman)"
        title.draw(
            in: CGRect(x: 48, y: 42, width: 499, height: 42),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
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
                sheet.letter.glyph.draw(
                    in: CGRect(x: x, y: y, width: 84, height: 96),
                    withAttributes: glyphAttributes
                )
            }
        }

        if let word = sheet.word {
            let wordTitle = "Im Wort: \(word.german)"
            wordTitle.draw(
                in: CGRect(x: 48, y: 704, width: 220, height: 30),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
            )
            word.arabicVowelized.draw(
                in: CGRect(x: 300, y: 680, width: 247, height: 70),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 44),
                    .foregroundColor: UIColor.black,
                    .writingDirection: [NSWritingDirection.rightToLeft.rawValue]
                ]
            )
        }

        if let pageNumber = sheet.pageNumber, let pageCount = sheet.pageCount {
            let pageLabel = "Hausaufgabe \(pageNumber) von \(pageCount)"
            pageLabel.draw(
                in: CGRect(x: 347, y: 798, width: 200, height: 18),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: rightAlignedParagraphStyle
                ]
            )
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
        return try write(data, to: url)
    }

    static func writeTemporaryWorkbook(curriculum: Curriculum) throws -> URL {
        let data = try renderWorkbook(curriculum: curriculum)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Arabisch-Alphabet-Hausaufgaben.pdf")
        return try write(data, to: url)
    }

    private static func write(_ data: Data, to url: URL) throws -> URL {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PracticeSheetError.writeFailed(underlying: error)
        }
        return url
    }

    private static var rightAlignedParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        return style
    }
}
