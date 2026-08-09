import SwiftUI

struct LetterDiscriminationView: View {
    let curriculum: Curriculum
    let letter: LetterContent
    @ObservedObject var speechService: SystemSpeechService
    let progress: Double
    let onClose: () -> Void
    let onComplete: (Bool) -> Void

    @State private var selectedID: String?
    @State private var usedCue = false
    @State private var feedback: String?
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false

    private var instruction: String {
        "Tippe auf \(letter.nameGerman). Achte auf Form und Punkte."
    }

    private var candidates: [LetterContent] {
        letter.confusableIDs.compactMap(curriculum.letter(id:))
    }

    private var isCorrect: Bool {
        selectedID == letter.id
    }

    var body: some View {
        LessonShell(
            title: "Formen unterscheiden",
            progress: progress,
            onClose: onClose
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tippe auf „\(letter.nameGerman)“.")
                    .font(.title2.bold())

                GermanInstruction("Achte auf Form und Punkte. Du kannst den Laut jederzeit anhören.")
                    .foregroundStyle(.secondary)

                Button {
                    speechService.speak(letter.phonemeSpeechText, locale: .msa)
                } label: {
                    Label("\(letter.phoneme) anhören", systemImage: "speaker.wave.2")
                }
                .buttonStyle(SecondaryButtonStyle())

                SpeechMessageView(speechService: speechService)
                InstructionSpeechButton(text: instruction, speechService: speechService)

                ForEach(candidates) { candidate in
                    Button {
                        selectedID = candidate.id
                        if candidate.id == letter.id {
                            feedback = "Genau. \(letter.memoryHintGerman)"
                        } else {
                            usedCue = true
                            feedback = "Noch nicht. \(letter.memoryHintGerman)"
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(candidate.glyph)
                                .font(.system(size: 58, weight: .medium))
                                .foregroundStyle(AppColor.ink)
                                .environment(\.layoutDirection, .rightToLeft)
                            Spacer()
                            if selectedID == candidate.id {
                                Image(
                                    systemName: candidate.id == letter.id
                                        ? "checkmark.circle.fill"
                                        : "arrow.uturn.backward.circle.fill"
                                )
                                .foregroundStyle(
                                    candidate.id == letter.id ? AppColor.teal : AppColor.terracotta
                                )
                                .accessibilityHidden(true)
                            }
                        }
                        .frame(minHeight: 76)
                        .padding(.horizontal)
                        .background(
                            selectedID == candidate.id ? AppColor.tealSoft : AppColor.warmWhite,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    selectedID == candidate.id ? AppColor.teal : AppColor.divider,
                                    lineWidth: selectedID == candidate.id ? 3 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(candidate.nameGerman)
                    .accessibilityValue(
                        selectedID == candidate.id
                            ? (candidate.id == letter.id ? "Richtig gewählt" : "Bitte erneut versuchen")
                            : "Nicht gewählt"
                    )
                    .accessibilityIdentifier("candidate-\(candidate.id)")
                }

                if let feedback {
                    Label(
                        feedback,
                        systemImage: isCorrect ? "checkmark.circle" : "lightbulb"
                    )
                    .font(.headline)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isCorrect ? AppColor.tealSoft : AppColor.terracottaSoft,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .accessibilityIdentifier("discrimination-feedback")
                }

                Button("Weiter") {
                    onComplete(usedCue)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isCorrect)
                .accessibilityIdentifier("continue-to-writing")
            }
        }
        .task {
            if readInstructions {
                speechService.speak(instruction, locale: .german)
            }
        }
    }
}
