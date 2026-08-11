import Foundation

enum ArabicBodyPlacement: String, Codable, Hashable, Sendable {
    case onBaseline
    case descender
    case crossing
}

struct ArabicFormBaselineProfile: Equatable, Hashable, Sendable {
    let bodyPlacement: ArabicBodyPlacement
    let hasDotsBelow: Bool

    static let onBaseline = ArabicFormBaselineProfile(
        bodyPlacement: .onBaseline,
        hasDotsBelow: false
    )
    static let onBaselineWithDotsBelow = ArabicFormBaselineProfile(
        bodyPlacement: .onBaseline,
        hasDotsBelow: true
    )
    static let descender = ArabicFormBaselineProfile(
        bodyPlacement: .descender,
        hasDotsBelow: false
    )
    static let descenderWithDotsBelow = ArabicFormBaselineProfile(
        bodyPlacement: .descender,
        hasDotsBelow: true
    )
    static let crossing = ArabicFormBaselineProfile(
        bodyPlacement: .crossing,
        hasDotsBelow: false
    )
}

enum ArabicHandwritingProfiles {
    private typealias FormProfiles = [LetterFormKind: ArabicFormBaselineProfile]

    private static let allOnBaseline = allForms(.onBaseline)
    private static let allOnBaselineWithDotsBelow = allForms(.onBaselineWithDotsBelow)

    private static let profiles: [String: FormProfiles] = [
        "alif": nonJoining(.onBaseline, .onBaseline),
        "baa": allOnBaselineWithDotsBelow,
        "taa": allOnBaseline,
        "thaa": allOnBaseline,
        "jim": joining(.descenderWithDotsBelow, .onBaselineWithDotsBelow),
        "haa": joining(.descender, .onBaseline),
        "khaa": joining(.descender, .onBaseline),
        "dal": nonJoining(.onBaseline, .onBaseline),
        "dhal": nonJoining(.onBaseline, .onBaseline),
        "raa": nonJoining(.descender, .descender),
        "zay": nonJoining(.descender, .descender),
        "sin": allOnBaseline,
        "shin": allOnBaseline,
        "saad": allOnBaseline,
        "daad": allOnBaseline,
        "ttaa": allOnBaseline,
        "zzaa": allOnBaseline,
        "ayn": joining(.descender, .onBaseline),
        "ghayn": joining(.descender, .onBaseline),
        "faa": allOnBaseline,
        "qaf": joining(.descender, .onBaseline),
        "kaf": allOnBaseline,
        "lam": joining(.descender, .onBaseline),
        "mim": joining(.descender, .onBaseline),
        "nun": joining(.descender, .onBaseline),
        "hah": [
            .isolated: .onBaseline,
            .initial: .onBaseline,
            .medial: .crossing,
            .final: .onBaseline
        ],
        "waw": nonJoining(.descender, .descender),
        "yaa": joining(.descenderWithDotsBelow, .onBaselineWithDotsBelow)
    ]

    static func profile(
        letterID: String,
        formKind: LetterFormKind
    ) -> ArabicFormBaselineProfile? {
        profiles[letterID]?[formKind]
    }

    static func missingProfiles(for letter: LetterContent) -> [LetterFormKind] {
        letter.forms.labelledForms.compactMap { form in
            profile(letterID: letter.id, formKind: form.kind) == nil ? form.kind : nil
        }
    }

    private static func allForms(
        _ profile: ArabicFormBaselineProfile
    ) -> FormProfiles {
        Dictionary(uniqueKeysWithValues: LetterFormKind.allCases.map { ($0, profile) })
    }

    private static func joining(
        _ isolatedAndFinal: ArabicFormBaselineProfile,
        _ initialAndMedial: ArabicFormBaselineProfile
    ) -> FormProfiles {
        [
            .isolated: isolatedAndFinal,
            .initial: initialAndMedial,
            .medial: initialAndMedial,
            .final: isolatedAndFinal
        ]
    }

    private static func nonJoining(
        _ isolated: ArabicFormBaselineProfile,
        _ final: ArabicFormBaselineProfile
    ) -> FormProfiles {
        [
            .isolated: isolated,
            .final: final
        ]
    }
}
