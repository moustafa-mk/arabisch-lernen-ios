import SwiftData
import SwiftUI

struct WordBridgeView: View {
    let curriculum: Curriculum
    let word: WordContent
    @ObservedObject var speechService: SystemSpeechService
    let progress: Double
    let onClose: () -> Void
    let onComplete: (Bool, Bool) -> Void

    @Query private var progressRecords: [SkillProgress]
    @AppStorage(PreferenceKey.showTransliteration) private var transliterationStartsVisible = true
    @AppStorage(PreferenceKey.arabicScale) private var arabicScale = 1.0
    @State private var showDiacritics = true
    @State private var transliterationRequested = false
    @State private var bridgeExpanded = false
    @State private var selectedIndices: [Int] = []
    @State private var feedback: String?
    @State private var usedCue = false
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false
    @ScaledMetric(relativeTo: .largeTitle) private var assembledBaseSize: CGFloat = 52

    private var instruction: String {
        "Lies \(word.german) auf Arabisch und setze das Wort von rechts nach links zusammen."
    }

    private var displayedWord: String {
        showDiacritics ? word.arabicVowelized : word.arabicUnvowelized
    }

    private var successfulRecalls: Int {
        progressRecords.first { $0.skillID == "word:\(word.id)" }?.successfulRecalls ?? 0
    }

    private var showsTransliteration: Bool {
        transliterationRequested || LiteracyScaffoldPolicy.showsTransliterationByDefault(
            preferenceEnabled: transliterationStartsVisible,
            successfulRecalls: successfulRecalls
        )
    }

    private var selectedLetterIDs: [String] {
        selectedIndices.map { word.letterIDs[$0] }
    }

    private var assembledGlyphs: String {
        selectedLetterIDs.compactMap { curriculum.letter(id: $0)?.glyph }.joined()
    }

    private var isCorrect: Bool {
        selectedLetterIDs == word.letterIDs
    }

    private var tileIndices: [Int] {
        let indices = Array(word.letterIDs.indices)
        guard indices.count > 1, let first = indices.first else {
            return indices
        }
        return Array(indices.dropFirst()) + [first]
    }

    var body: some View {
        LessonShell(
            title: "Bekanntes Wort",
            progress: progress,
            onClose: onClose
        ) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 10) {
                    ArabicGlyphView(
                        displayedWord,
                        accessibilityName: "\(word.german), \(word.msaTransliteration)",
                        scale: arabicScale,
                        baseSize: 64
                    )
                    Text(word.german)
                        .font(.title3.bold())
                    if showsTransliteration {
                        Text(word.msaTransliteration)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Umschrift \(word.msaTransliteration)")
                    } else {
                        Button("Umschrift als Hilfe anzeigen") {
                            transliterationRequested = true
                        }
                        .font(.callout)
                    }
                    Button {
                        speechService.speak(word.msaSpeechText, locale: .msa)
                    } label: {
                        Label("MSA anhören", systemImage: "speaker.wave.2")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .appCard()

                SpeechMessageView(speechService: speechService)
                InstructionSpeechButton(text: instruction, speechService: speechService)

                Picker("Vokalzeichen", selection: $showDiacritics) {
                    Text("Mit Vokalzeichen").tag(true)
                    Text("Ohne Vokalzeichen").tag(false)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Deine syrische Sprachbrücke")
                        .font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Syrisch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(word.syrianText)
                                .font(.title2)
                                .environment(\.layoutDirection, .rightToLeft)
                            if showsTransliteration {
                                Text(word.syrianTransliteration)
                                    .font(.callout)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.left.and.right")
                            .accessibilityHidden(true)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Hochsprache")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(word.arabicVowelized)
                                .font(.title2)
                                .environment(\.layoutDirection, .rightToLeft)
                            if showsTransliteration {
                                Text(word.msaTransliteration)
                                    .font(.callout)
                            }
                        }
                    }

                    DisclosureGroup(
                        "Was bleibt gleich, was ändert sich?",
                        isExpanded: $bridgeExpanded
                    ) {
                        GermanInstruction(word.bridgeNoteGerman)
                            .padding(.top, 8)
                    }
                }
                .appCard()

                Text("Setze das Wort zusammen.")
                    .font(.title2.bold())

                VStack(spacing: 8) {
                    Text(assembledGlyphs.isEmpty ? "…" : assembledGlyphs)
                        .font(.system(
                            size: assembledBaseSize * CGFloat(arabicScale),
                            weight: .medium
                        ))
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: .infinity, minHeight: 76)
                        .accessibilityLabel(
                            assembledGlyphs.isEmpty ? "Noch kein Buchstabe gewählt" : assembledGlyphs
                        )

                    HStack {
                        ForEach(tileIndices, id: \.self) { index in
                            let letterID = word.letterIDs[index]
                            if let letter = curriculum.letter(id: letterID) {
                                Button {
                                    guard !selectedIndices.contains(index) else {
                                        return
                                    }
                                    selectedIndices.append(index)
                                    feedback = nil
                                } label: {
                                    Text(letter.glyph)
                                        .font(.system(size: 36, weight: .medium))
                                        .frame(maxWidth: .infinity, minHeight: 58)
                                }
                                .buttonStyle(.bordered)
                                .disabled(selectedIndices.contains(index))
                                .accessibilityLabel(letter.nameGerman)
                                .accessibilityIdentifier("word-tile-\(index)")
                            }
                        }
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                }
                .appCard()

                HStack {
                    Button {
                        selectedIndices = []
                        feedback = nil
                    } label: {
                        Label("Neu", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        selectedIndices = Array(word.letterIDs.indices)
                        feedback = "Die Lösung ist sichtbar. Lies sie noch einmal von rechts nach links."
                        usedCue = true
                    } label: {
                        Label("Lösung zeigen", systemImage: "lightbulb")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if let feedback {
                    Label(feedback, systemImage: usedCue ? "lightbulb" : "checkmark.circle")
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.terracottaSoft, in: RoundedRectangle(cornerRadius: 12))
                }

                Button(isCorrect ? "Weiter" : "Prüfen") {
                    if isCorrect {
                        onComplete(!usedCue, usedCue)
                    } else {
                        feedback = "Die Reihenfolge passt noch nicht. Beginne rechts mit dem ersten Buchstaben des Wortes."
                        usedCue = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedIndices.count != word.letterIDs.count)
                .accessibilityIdentifier("complete-word-bridge")
            }
        }
        .task {
            showDiacritics = LiteracyScaffoldPolicy.showsDiacriticsByDefault(
                successfulRecalls: successfulRecalls
            )
            if readInstructions {
                speechService.speak(instruction, locale: .german)
            }
        }
    }
}
