import UIKit

enum WorksheetTypography {
    static let arabicFontName = "NotoNaskhArabic-Regular"

    static func arabicFont(ofSize size: CGFloat) throws -> UIFont {
        guard let font = UIFont(name: arabicFontName, size: size) else {
            throw PracticeSheetError.missingArabicFont
        }
        return font
    }
}
