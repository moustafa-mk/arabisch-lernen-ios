import Foundation

enum PreferenceKey {
    static let onboardingComplete = "onboardingComplete"
    static let calmMode = "calmMode"
    static let extraSpacing = "extraSpacing"
    static let readInstructions = "readInstructions"
    static let showTransliteration = "showTransliteration"
    static let arabicScale = "arabicScale"
    static let backgroundStyle = "backgroundStyle"
}

enum AccessibilityPreferenceResolver {
    static func allowsInstructionalAnimation(
        calmMode: Bool,
        systemReduceMotion: Bool
    ) -> Bool {
        !calmMode && !systemReduceMotion
    }

    static func effectiveLineSpacing(extraSpacing: Bool) -> CGFloat {
        extraSpacing ? 8 : 2
    }
}
