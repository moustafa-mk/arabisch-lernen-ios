enum LiteracyScaffoldPolicy {
    static func showsTransliterationByDefault(
        preferenceEnabled: Bool,
        successfulRecalls: Int
    ) -> Bool {
        preferenceEnabled && successfulRecalls < 2
    }

    static func showsDiacriticsByDefault(successfulRecalls: Int) -> Bool {
        successfulRecalls < 4
    }
}
