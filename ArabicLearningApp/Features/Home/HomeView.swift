import SwiftData
import SwiftUI

struct HomeView: View {
    let curriculum: Curriculum
    @ObservedObject var speechService: SystemSpeechService
    let openSettings: () -> Void

    @Query private var progressRecords: [SkillProgress]
    @AppStorage(PreferenceKey.calmMode) private var calmMode = false
    @State private var presentedLetter: LetterContent?
    @State private var homeworkPDFURL: URL?
    @State private var homeworkError: String?

    private var progressByID: [String: SkillProgress] {
        Dictionary(
            uniqueKeysWithValues: progressRecords
                .filter { curriculum.alphabetOrder.contains($0.skillID) }
                .map { ($0.skillID, $0) }
        )
    }

    private var alphabetProgressByID: [String: AlphabetLetterProgress] {
        progressByID.mapValues {
            AlphabetLetterProgress(
                exposureCount: $0.exposureCount,
                mastery: $0.mastery,
                nextReviewAt: $0.nextReviewAt
            )
        }
    }

    private var recommendedLetter: LetterContent {
        let nextID = AlphabetProgressPolicy.recommendedLetterID(
            alphabetOrder: curriculum.alphabetOrder,
            progressByID: alphabetProgressByID,
            now: .now
        ) ?? curriculum.alphabetOrder[0]
        return curriculum.letter(id: nextID) ?? curriculum.letters[0]
    }

    private var recommendedLessonIsReview: Bool {
        AlphabetProgressPolicy.hasCompletedLesson(alphabetProgressByID[recommendedLetter.id])
    }

    private var completedCount: Int {
        AlphabetProgressPolicy.completedCount(
            alphabetOrder: curriculum.alphabetOrder,
            progressByID: alphabetProgressByID
        )
    }

    private var dueCount: Int {
        progressRecords.filter {
            curriculum.alphabetOrder.contains($0.skillID) && $0.nextReviewAt <= .now
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heute")
                            .font(.largeTitle.bold())
                        Text("Eine kurze Einheit · ohne Zeitdruck")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: openSettings) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                    }
                    .minimumAccessibleTarget()
                    .accessibilityLabel("Einstellungen")
                    .accessibilityIdentifier("open-settings")
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Alphabetfortschritt")
                            .font(.headline)
                        Spacer()
                        Text("\(completedCount) von \(curriculum.alphabetOrder.count)")
                            .foregroundStyle(.secondary)
                    }
                    AppProgressView(
                        value: Double(completedCount) / Double(curriculum.alphabetOrder.count)
                    )
                    if dueCount > 0 {
                        Label(
                            "\(dueCount) \(dueCount == 1 ? "Buchstabe wartet" : "Buchstaben warten") auf Wiederholung",
                            systemImage: "arrow.clockwise"
                        )
                        .font(.callout)
                    }
                }
                .appCard()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Dein nächster Lernweg")
                        .font(.title2.bold())

                    HStack(spacing: 16) {
                        ArabicGlyphView(
                            recommendedLetter.glyph,
                            accessibilityName: recommendedLetter.nameGerman,
                            baseSize: 64
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendedLetter.nameGerman)
                                .font(.title3.bold())
                            Text("Form · Laut · Schreiben · Wort")
                                .foregroundStyle(.secondary)
                            Label("etwa 6 Minuten", systemImage: "clock")
                                .font(.callout)
                        }
                    }

                    Button {
                        presentedLetter = recommendedLetter
                    } label: {
                        Text(recommendedLessonIsReview ? "Wiederholen" : "Weiterlernen")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("start-lesson")
                }
                .appCard()

                VStack(alignment: .leading, spacing: 12) {
                    Label("Hausaufgabenheft", systemImage: "book.closed")
                        .font(.title2.bold())
                    Text(
                        "\(curriculum.alphabetOrder.count) druckbare Übungsseiten – eine für jeden Buchstaben."
                    )
                    .foregroundStyle(.secondary)

                    Button {
                        do {
                            homeworkPDFURL = try PracticeSheetRenderer.writeTemporaryWorkbook(
                                curriculum: curriculum
                            )
                            homeworkError = nil
                        } catch {
                            homeworkPDFURL = nil
                            homeworkError = error.localizedDescription
                        }
                    } label: {
                        Label("Hausaufgabenheft erstellen", systemImage: "doc.badge.plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("create-homework-workbook")

                    if let homeworkPDFURL {
                        ShareLink(item: homeworkPDFURL) {
                            Label("Drucken oder teilen", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("share-homework-workbook")
                    }

                    if let homeworkError {
                        Label(homeworkError, systemImage: "exclamationmark.triangle")
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                AppColor.terracottaSoft,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .accessibilityIdentifier("homework-workbook-error")
                    }
                }
                .appCard()

                if !calmMode {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Arabisches Alphabet")
                            .font(.headline)
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 64), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(curriculum.alphabetOrder, id: \.self) { letterID in
                                if let letter = curriculum.letter(id: letterID) {
                                    let completed = AlphabetProgressPolicy.hasCompletedLesson(
                                        alphabetProgressByID[letterID]
                                    )
                                    VStack(spacing: 4) {
                                        Text(letter.glyph)
                                            .font(.system(size: 34, weight: .medium))
                                            .foregroundStyle(AppColor.ink)
                                        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                                            .font(.caption)
                                            .foregroundStyle(completed ? AppColor.teal : AppColor.muted)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 72)
                                    .background(
                                        AppColor.warmWhite,
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(letter.nameGerman)
                                    .accessibilityValue(
                                        completed ? "Einheit abgeschlossen" : "Noch zu lernen"
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $presentedLetter) { letter in
            LessonFlowView(
                curriculum: curriculum,
                letter: letter,
                speechService: speechService
            )
        }
        .accessibilityIdentifier("home-screen")
    }
}
