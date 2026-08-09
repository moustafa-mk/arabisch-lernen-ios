import SwiftData
import SwiftUI

struct HomeView: View {
    let curriculum: Curriculum
    @ObservedObject var speechService: SystemSpeechService
    let openSettings: () -> Void

    @Query private var progressRecords: [SkillProgress]
    @AppStorage(PreferenceKey.calmMode) private var calmMode = false
    @State private var presentedLetter: LetterContent?

    private var progressByID: [String: SkillProgress] {
        Dictionary(
            uniqueKeysWithValues: progressRecords
                .filter { curriculum.pilotOrder.contains($0.skillID) }
                .map { ($0.skillID, $0) }
        )
    }

    private var recommendedLetter: LetterContent {
        let dueID = curriculum.pilotOrder.first {
            guard let progress = progressByID[$0] else {
                return false
            }
            return progress.nextReviewAt <= .now
        }
        let nextLearningID = curriculum.pilotOrder.first {
            (progressByID[$0]?.mastery ?? 0) < 0.75
        }
        let nextID = dueID ?? nextLearningID ?? curriculum.pilotOrder[0]
        return curriculum.letter(id: nextID) ?? curriculum.letters[0]
    }

    private var completedCount: Int {
        curriculum.pilotOrder.filter {
            (progressByID[$0]?.mastery ?? 0) >= 0.75
        }.count
    }

    private var dueCount: Int {
        progressRecords.filter {
            curriculum.pilotOrder.contains($0.skillID) && $0.nextReviewAt <= .now
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
                        Text("Pilotfortschritt")
                            .font(.headline)
                        Spacer()
                        Text("\(completedCount) von \(curriculum.pilotOrder.count)")
                            .foregroundStyle(.secondary)
                    }
                    AppProgressView(
                        value: Double(completedCount) / Double(curriculum.pilotOrder.count)
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
                        Text(dueCount > 0 ? "Wiederholen" : "Weiterlernen")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("start-lesson")
                }
                .appCard()

                if !calmMode {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pilotbuchstaben")
                            .font(.headline)
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 64), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(curriculum.pilotOrder, id: \.self) { letterID in
                                if let letter = curriculum.letter(id: letterID) {
                                    let mastered = (progressByID[letterID]?.mastery ?? 0) >= 0.75
                                    VStack(spacing: 4) {
                                        Text(letter.glyph)
                                            .font(.system(size: 34, weight: .medium))
                                            .foregroundStyle(AppColor.ink)
                                        Image(systemName: mastered ? "checkmark.circle.fill" : "circle")
                                            .font(.caption)
                                            .foregroundStyle(mastered ? AppColor.teal : AppColor.muted)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 72)
                                    .background(
                                        AppColor.warmWhite,
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(letter.nameGerman)
                                    .accessibilityValue(mastered ? "Sicher" : "Noch zu lernen")
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
