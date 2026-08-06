import SwiftUI

struct LetterDiscoveryView: View {
    let letter: LetterContent
    @ObservedObject var speechService: SystemSpeechService
    let progress: Double
    let onClose: () -> Void
    let onContinue: () -> Void

    @AppStorage(PreferenceKey.arabicScale) private var arabicScale = 1.0
    @AppStorage(PreferenceKey.calmMode) private var calmMode = false
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var formBaseSize: CGFloat = 44

    private var instruction: String {
        "\(letter.nameGerman). Ein Buchstabe, mehrere Formen. \(letter.memoryHintGerman)"
    }

    private var allowsAnimation: Bool {
        AccessibilityPreferenceResolver.allowsInstructionalAnimation(
            calmMode: calmMode,
            systemReduceMotion: systemReduceMotion
        )
    }

    var body: some View {
        LessonShell(
            title: "Buchstabe entdecken",
            progress: progress,
            onClose: onClose
        ) {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    ArabicGlyphView(
                        letter.glyph,
                        accessibilityName: letter.nameGerman,
                        scale: arabicScale,
                        baseSize: 112
                    )
                    .foregroundStyle(AppColor.ink.opacity(0.16))

                    LetterStrokeGuide(letter: letter, animate: allowsAnimation)
                        .frame(width: 190, height: 190)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .appCard()

                Text("\(letter.nameGerman): ein Buchstabe, mehrere Formen")
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button {
                        speechService.speak(letter.nameArabic, locale: .msa)
                    } label: {
                        Label("Name anhören", systemImage: "speaker.wave.2")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        speechService.speak(letter.phonemeSpeechText, locale: .msa)
                    } label: {
                        Label("Laut \(letter.phoneme)", systemImage: "waveform")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                SpeechMessageView(speechService: speechService)
                InstructionSpeechButton(text: instruction, speechService: speechService)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(letter.forms.labelledForms) { form in
                        VStack(spacing: 6) {
                            Text(form.glyph)
                                .font(.system(
                                    size: formBaseSize * CGFloat(arabicScale),
                                    weight: .medium
                                ))
                                .environment(\.layoutDirection, .rightToLeft)
                            Text(form.label)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, minHeight: 104)
                        .appCard()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(letter.nameGerman), \(form.label)")
                    }
                }

                GermanInstruction(letter.memoryHintGerman)
                    .font(.headline)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.tealSoft, in: RoundedRectangle(cornerRadius: 14))

                if !letter.joinsFollowing {
                    Label(
                        "Hier stoppt die Verbindung. Der nächste Buchstabe beginnt neu.",
                        systemImage: "link.badge.plus"
                    )
                    .font(.callout)
                }

                Button("Formen unterscheiden", action: onContinue)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("continue-to-discrimination")
            }
        }
        .task {
            if readInstructions {
                speechService.speak(
                    instruction,
                    locale: .german
                )
            }
        }
    }
}
