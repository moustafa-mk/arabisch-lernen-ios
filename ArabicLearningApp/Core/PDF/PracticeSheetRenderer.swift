import CoreText
import Foundation
import UIKit

enum PracticeSheetError: LocalizedError {
    case invalidPageBounds
    case emptyWorkbook
    case missingLetter
    case missingFocusWord(letterName: String)
    case missingArabicFont
    case missingHandwritingProfile(letterName: String, formLabel: String)
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
        case .missingArabicFont:
            return "Die arabische Schrift für das Übungsblatt fehlt."
        case let .missingHandwritingProfile(letterName, formLabel):
            return "Die Schreiblinie für \(letterName) \(formLabel) ist nicht vollständig."
        case .writeFailed:
            return "Das Übungsblatt konnte nicht gespeichert werden."
        }
    }
}

enum PracticeSheetRenderer {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
    private static let pageMargin: CGFloat = 34
    static let practiceRowHeight: CGFloat = 58

    private enum Palette {
        static let ink = UIColor(red: 0.16, green: 0.14, blue: 0.13, alpha: 1)
        static let muted = UIColor(red: 0.42, green: 0.39, blue: 0.36, alpha: 1)
        static let terracotta = UIColor(red: 0.62, green: 0.34, blue: 0.25, alpha: 1)
        static let tealSoft = UIColor(red: 0.91, green: 0.95, blue: 0.94, alpha: 1)
        static let warmWhite = UIColor(red: 1.00, green: 0.98, blue: 0.95, alpha: 1)
        static let border = UIColor(red: 0.70, green: 0.65, blue: 0.61, alpha: 1)
        static let guide = UIColor(red: 0.58, green: 0.56, blue: 0.54, alpha: 1)
        static let trace = UIColor(red: 0.74, green: 0.71, blue: 0.68, alpha: 1)
    }

    private struct Sheet {
        let letter: LetterContent
        let word: WordContent?
        let pageNumber: Int?
        let pageCount: Int?
    }

    private struct Fonts {
        let title = UIFont.systemFont(ofSize: 22, weight: .bold)
        let subtitle = UIFont.systemFont(ofSize: 11.5)
        let section = UIFont.systemFont(ofSize: 14, weight: .bold)
        let body = UIFont.systemFont(ofSize: 11.5)
        let small = UIFont.systemFont(ofSize: 9.5)
        let arabicHero: UIFont
        let arabicForm: UIFont
        let arabicPractice: UIFont
        let arabicWord: UIFont
        let arabicWordPractice: UIFont

        init() throws {
            arabicHero = try WorksheetTypography.arabicFont(ofSize: 58)
            arabicForm = try WorksheetTypography.arabicFont(ofSize: 27)
            arabicPractice = try WorksheetTypography.arabicFont(ofSize: 31)
            arabicWord = try WorksheetTypography.arabicFont(ofSize: 38)
            arabicWordPractice = try WorksheetTypography.arabicFont(ofSize: 30)
        }
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

    static func practiceFormKinds(for letter: LetterContent) -> [LetterFormKind] {
        let available = letter.forms.labelledForms.map(\.kind)
        if available == [.isolated, .final] {
            return [.isolated, .isolated, .final, .final]
        }
        if available.count >= 4 {
            return Array(available.prefix(4))
        }
        guard !available.isEmpty else {
            return []
        }

        var result: [LetterFormKind] = []
        while result.count < 4 {
            result.append(contentsOf: available)
        }
        return Array(result.prefix(4))
    }

    static func practiceGlyphBounds(
        letter: LetterContent,
        formKind: LetterFormKind
    ) throws -> CGRect {
        guard
            let glyph = letter.forms.glyph(for: formKind),
            let profile = ArabicHandwritingProfiles.profile(
                letterID: letter.id,
                formKind: formKind
            )
        else {
            throw PracticeSheetError.missingHandwritingProfile(
                letterName: letter.nameGerman,
                formLabel: formKind.label
            )
        }

        let font = try WorksheetTypography.arabicFont(ofSize: 31)
        let line = makeArabicLine(glyph, font: font, color: Palette.ink)
        let glyphBounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        let baseline = practiceBaselineOffset(for: profile)
        return CGRect(
            x: glyphBounds.minX,
            y: baseline - glyphBounds.maxY,
            width: glyphBounds.width,
            height: glyphBounds.height
        )
    }

    private static func render(_ sheets: [Sheet]) throws -> Data {
        guard pageBounds.width > 0, pageBounds.height > 0 else {
            throw PracticeSheetError.invalidPageBounds
        }
        guard !sheets.isEmpty else {
            throw PracticeSheetError.emptyWorkbook
        }

        let fonts = try Fonts()
        try validateHandwritingProfiles(in: sheets)

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            for sheet in sheets {
                context.beginPage()
                drawPage(sheet, fonts: fonts, context: context)
            }
        }
    }

    private static func validateHandwritingProfiles(in sheets: [Sheet]) throws {
        for sheet in sheets {
            for form in sheet.letter.forms.labelledForms {
                guard ArabicHandwritingProfiles.profile(
                    letterID: sheet.letter.id,
                    formKind: form.kind
                ) != nil else {
                    throw PracticeSheetError.missingHandwritingProfile(
                        letterName: sheet.letter.nameGerman,
                        formLabel: form.label
                    )
                }
            }
        }
    }

    private static func drawPage(
        _ sheet: Sheet,
        fonts: Fonts,
        context: UIGraphicsPDFRendererContext
    ) {
        let cgContext = context.cgContext
        drawHeader(sheet, fonts: fonts, context: cgContext)
        drawOverview(sheet.letter, fonts: fonts, context: cgContext)
        drawFormCards(sheet.letter, fonts: fonts, context: cgContext)
        drawPracticeRows(sheet.letter, fonts: fonts, context: cgContext)
        drawWordPractice(sheet.word, letter: sheet.letter, fonts: fonts, context: cgContext)
        drawFooter(sheet, fonts: fonts)
    }

    private static func drawHeader(
        _ sheet: Sheet,
        fonts: Fonts,
        context: CGContext
    ) {
        drawText(
            "Arabisch schreiben: \(sheet.letter.nameGerman)",
            in: CGRect(x: pageMargin, y: 24, width: 330, height: 30),
            font: fonts.title,
            color: Palette.ink
        )
        drawText(
            "Buchstabe, Laut und Wort Schritt für Schritt üben",
            in: CGRect(x: pageMargin, y: 59, width: 350, height: 18),
            font: fonts.subtitle,
            color: Palette.ink
        )

        drawText(
            "Name:",
            in: CGRect(x: 386, y: 29, width: 42, height: 17),
            font: fonts.body,
            color: Palette.ink
        )
        drawText(
            "Datum:",
            in: CGRect(x: 386, y: 54, width: 46, height: 17),
            font: fonts.body,
            color: Palette.ink
        )
        drawLine(
            from: CGPoint(x: 432, y: 43),
            to: CGPoint(x: 561, y: 43),
            color: Palette.muted,
            context: context
        )
        drawLine(
            from: CGPoint(x: 432, y: 68),
            to: CGPoint(x: 561, y: 68),
            color: Palette.muted,
            context: context
        )
        drawLine(
            from: CGPoint(x: pageMargin, y: 86),
            to: CGPoint(x: pageBounds.width - pageMargin, y: 86),
            color: Palette.terracotta,
            width: 1.5,
            context: context
        )
    }

    private static func drawOverview(
        _ letter: LetterContent,
        fonts: Fonts,
        context: CGContext
    ) {
        let letterCard = CGRect(x: pageMargin, y: 100, width: 110, height: 88)
        fillRoundedRect(letterCard, radius: 12, color: Palette.warmWhite, context: context)
        strokeRoundedRect(letterCard, radius: 12, color: Palette.border, width: 1.5, context: context)

        let isolatedProfile = ArabicHandwritingProfiles.profile(
            letterID: letter.id,
            formKind: .isolated
        ) ?? .onBaseline
        drawArabic(
            letter.forms.isolated,
            centeredAtX: letterCard.midX,
            baselineY: overviewBaseline(for: isolatedProfile, in: letterCard),
            font: fonts.arabicHero,
            color: Palette.ink,
            context: context
        )

        let noteCard = CGRect(x: 156, y: 98, width: 405, height: 92)
        fillRoundedRect(noteCard, radius: 12, color: Palette.tealSoft, context: context)
        drawText(
            "\(letter.nameGerman) · Laut \(letter.phoneme)",
            in: CGRect(x: 168, y: 110, width: 380, height: 22),
            font: UIFont.systemFont(ofSize: 14, weight: .bold),
            color: Palette.ink
        )
        drawText(
            letter.memoryHintGerman,
            in: CGRect(x: 168, y: 138, width: 378, height: 42),
            font: fonts.body,
            color: Palette.ink
        )
    }

    private static func drawFormCards(
        _ letter: LetterContent,
        fonts: Fonts,
        context: CGContext
    ) {
        let forms = letter.forms.labelledForms
        let gap: CGFloat = 8
        let totalWidth = pageBounds.width - pageMargin * 2
        let cardWidth = (totalWidth - gap * CGFloat(forms.count - 1)) / CGFloat(forms.count)

        for (index, form) in forms.enumerated() {
            let rect = CGRect(
                x: pageMargin + CGFloat(index) * (cardWidth + gap),
                y: 200,
                width: cardWidth,
                height: 54
            )
            fillRoundedRect(rect, radius: 9, color: .white, context: context)
            strokeRoundedRect(rect, radius: 9, color: Palette.border, width: 0.8, context: context)

            let profile = ArabicHandwritingProfiles.profile(
                letterID: letter.id,
                formKind: form.kind
            ) ?? .onBaseline
            drawArabic(
                form.glyph,
                centeredAtX: rect.midX,
                baselineY: formCardBaseline(for: profile, in: rect),
                font: fonts.arabicForm,
                color: Palette.ink,
                context: context
            )
            drawText(
                form.label,
                in: CGRect(x: rect.minX + 4, y: rect.maxY - 17, width: rect.width - 8, height: 13),
                font: fonts.small,
                color: Palette.muted,
                alignment: .center
            )
        }
    }

    private static func drawPracticeRows(
        _ letter: LetterContent,
        fonts: Fonts,
        context: CGContext
    ) {
        drawText(
            "Formen nachfahren und frei schreiben",
            in: CGRect(x: pageMargin, y: 265, width: 350, height: 19),
            font: fonts.section,
            color: Palette.ink
        )

        let kinds = practiceFormKinds(for: letter)
        for (index, kind) in kinds.enumerated() {
            guard
                let glyph = letter.forms.glyph(for: kind),
                let profile = ArabicHandwritingProfiles.profile(
                    letterID: letter.id,
                    formKind: kind
                )
            else {
                continue
            }
            drawPracticeRow(
                glyph: glyph,
                kind: kind,
                profile: profile,
                top: 288 + CGFloat(index) * 66,
                arabicFont: fonts.arabicPractice,
                labelFont: fonts.small,
                context: context
            )
        }
    }

    private static func drawPracticeRow(
        glyph: String,
        kind: LetterFormKind,
        profile: ArabicFormBaselineProfile,
        top: CGFloat,
        arabicFont: UIFont,
        labelFont: UIFont,
        context: CGContext
    ) {
        let row = CGRect(
            x: pageMargin,
            y: top,
            width: pageBounds.width - pageMargin * 2,
            height: practiceRowHeight
        )
        fillRoundedRect(row, radius: 7, color: .white, context: context)
        strokeRoundedRect(row, radius: 7, color: Palette.border, width: 0.7, context: context)

        let labelWidth: CGFloat = 84
        drawText(
            kind.label,
            in: CGRect(x: row.minX + 7, y: row.minY + 20, width: labelWidth - 14, height: 18),
            font: labelFont,
            color: Palette.muted,
            alignment: .center
        )

        let writingMinX = row.minX + labelWidth
        let writingWidth = row.width - labelWidth
        let cellWidth = writingWidth / 6
        let baselineY = practiceBaseline(for: profile, rowTop: top)

        drawLine(
            from: CGPoint(x: writingMinX, y: baselineY),
            to: CGPoint(x: row.maxX, y: baselineY),
            color: Palette.guide,
            width: 0.65,
            context: context
        )

        for divider in 0..<6 {
            let x = writingMinX + CGFloat(divider) * cellWidth
            drawDashedLine(
                from: CGPoint(x: x, y: row.minY),
                to: CGPoint(x: x, y: row.maxY),
                color: Palette.border,
                context: context
            )
        }

        for traceIndex in 0..<2 {
            let centerX = row.maxX - cellWidth * (CGFloat(traceIndex) + 0.5)
            drawArabic(
                glyph,
                centeredAtX: centerX,
                baselineY: baselineY,
                font: arabicFont,
                color: Palette.trace,
                context: context
            )
        }
    }

    private static func drawWordPractice(
        _ word: WordContent?,
        letter: LetterContent,
        fonts: Fonts,
        context: CGContext
    ) {
        guard let word else {
            return
        }

        drawText(
            "\(letter.nameGerman) im Wort",
            in: CGRect(x: pageMargin, y: 555, width: 250, height: 20),
            font: fonts.section,
            color: Palette.ink
        )

        let noteRect = CGRect(x: pageMargin, y: 581, width: pageBounds.width - pageMargin * 2, height: 94)
        fillRoundedRect(noteRect, radius: 12, color: Palette.warmWhite, context: context)
        strokeRoundedRect(noteRect, radius: 12, color: Palette.border, width: 1.2, context: context)

        drawText(
            "\(word.msaTransliteration) · \(word.german)",
            in: CGRect(x: noteRect.minX + 12, y: noteRect.minY + 13, width: 255, height: 20),
            font: UIFont.systemFont(ofSize: 12, weight: .bold),
            color: Palette.ink
        )
        drawText(
            word.bridgeNoteGerman,
            in: CGRect(x: noteRect.minX + 12, y: noteRect.minY + 38, width: 285, height: 45),
            font: fonts.body,
            color: Palette.ink
        )
        drawArabic(
            word.arabicVowelized,
            centeredAtX: noteRect.maxX - 105,
            baselineY: noteRect.midY + 13,
            font: fonts.arabicWord,
            color: Palette.ink,
            context: context
        )

        let writingRect = CGRect(
            x: pageMargin,
            y: 685,
            width: pageBounds.width - pageMargin * 2,
            height: 68
        )
        fillRoundedRect(writingRect, radius: 8, color: .white, context: context)
        strokeRoundedRect(writingRect, radius: 8, color: Palette.border, width: 0.7, context: context)

        let baselineY = writingRect.minY + 42
        drawLine(
            from: CGPoint(x: writingRect.minX + 8, y: baselineY),
            to: CGPoint(x: writingRect.maxX - 8, y: baselineY),
            color: Palette.guide,
            width: 0.65,
            context: context
        )
        drawArabic(
            word.arabicUnvowelized,
            centeredAtX: writingRect.maxX - 82,
            baselineY: baselineY,
            font: fonts.arabicWordPractice,
            color: Palette.trace,
            context: context
        )
    }

    private static func drawFooter(_ sheet: Sheet, fonts: Fonts) {
        drawText(
            "Ohne Zeitdruck · Bei Bedarf eine Pause machen",
            in: CGRect(x: pageMargin, y: 793, width: 270, height: 16),
            font: fonts.small,
            color: Palette.muted
        )

        let rightText: String
        if let pageNumber = sheet.pageNumber, let pageCount = sheet.pageCount {
            rightText = "Arabisch lernen · \(pageNumber) von \(pageCount)"
        } else {
            rightText = "Arabisch lernen · Alphabetübung"
        }
        drawText(
            rightText,
            in: CGRect(x: 330, y: 793, width: 231, height: 16),
            font: fonts.small,
            color: Palette.muted,
            alignment: .right
        )
    }

    static func practiceBaselineOffset(
        for profile: ArabicFormBaselineProfile
    ) -> CGFloat {
        switch (profile.bodyPlacement, profile.hasDotsBelow) {
        case (.onBaseline, false):
            return 43
        case (.onBaseline, true):
            return 37
        case (.descender, false):
            return 30
        case (.descender, true):
            return 25
        case (.crossing, _):
            return 34
        }
    }

    private static func practiceBaseline(
        for profile: ArabicFormBaselineProfile,
        rowTop: CGFloat
    ) -> CGFloat {
        rowTop + practiceBaselineOffset(for: profile)
    }

    private static func formCardBaseline(
        for profile: ArabicFormBaselineProfile,
        in rect: CGRect
    ) -> CGFloat {
        switch profile.bodyPlacement {
        case .onBaseline:
            return rect.minY + (profile.hasDotsBelow ? 25 : 29)
        case .descender:
            return rect.minY + (profile.hasDotsBelow ? 18 : 21)
        case .crossing:
            return rect.minY + 25
        }
    }

    private static func overviewBaseline(
        for profile: ArabicFormBaselineProfile,
        in rect: CGRect
    ) -> CGFloat {
        switch profile.bodyPlacement {
        case .onBaseline:
            return rect.minY + (profile.hasDotsBelow ? 50 : 59)
        case .descender:
            return rect.minY + (profile.hasDotsBelow ? 38 : 43)
        case .crossing:
            return rect.minY + 48
        }
    }

    private static func drawArabic(
        _ text: String,
        centeredAtX centerX: CGFloat,
        baselineY: CGFloat,
        font: UIFont,
        color: UIColor,
        context: CGContext
    ) {
        let line = makeArabicLine(text, font: font, color: color)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])

        context.saveGState()
        context.translateBy(x: centerX - bounds.midX, y: baselineY)
        context.scaleBy(x: 1, y: -1)
        context.textMatrix = .identity
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func makeArabicLine(
        _ text: String,
        font: UIFont,
        color: UIColor
    ) -> CTLine {
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .writingDirection: [NSWritingDirection.rightToLeft.rawValue]
            ]
        )
        return CTLineCreateWithAttributedString(attributedText)
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        text.draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style
            ]
        )
    }

    private static func fillRoundedRect(
        _ rect: CGRect,
        radius: CGFloat,
        color: UIColor,
        context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color.cgColor)
        context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
        context.fillPath()
        context.restoreGState()
    }

    private static func strokeRoundedRect(
        _ rect: CGRect,
        radius: CGFloat,
        color: UIColor,
        width: CGFloat,
        context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
        context.strokePath()
        context.restoreGState()
    }

    private static func drawLine(
        from start: CGPoint,
        to end: CGPoint,
        color: UIColor,
        width: CGFloat = 0.7,
        context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(width)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }

    private static func drawDashedLine(
        from start: CGPoint,
        to end: CGPoint,
        color: UIColor,
        context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [2, 2])
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
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
}
