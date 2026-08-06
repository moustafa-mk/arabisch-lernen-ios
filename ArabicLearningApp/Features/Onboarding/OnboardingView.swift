import SwiftUI

struct OnboardingView: View {
    @ObservedObject var speechService: SystemSpeechService
    let openSettings: () -> Void
    let completeOnboarding: () -> Void

    @AppStorage(PreferenceKey.extraSpacing) private var extraSpacing = false
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false

    private let introduction = "Du sprichst schon etwas Syrisch-Arabisch. Das nutzen wir als Brücke zur arabischen Hochsprache."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Willkommen")
                        .font(.title2.bold())
                    Spacer()
                    Button(action: openSettings) {
                        Image(systemName: "textformat.size")
                    }
                    .minimumAccessibleTarget()
                    .accessibilityLabel("Lesbarkeit anpassen")
                }

                VStack(spacing: 12) {
                    ArabicGlyphView(
                        "أَهْلًا وَسَهْلًا",
                        accessibilityName: "Ahlan wa sahlan",
                        baseSize: 48
                    )
                    Button {
                        speechService.speak("أَهْلًا وَسَهْلًا", locale: .msa)
                    } label: {
                        Label("Anhören", systemImage: "speaker.wave.2")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("welcome-audio")
                }
                .appCard()

                VStack(alignment: .leading, spacing: extraSpacing ? 18 : 12) {
                    Text("Arabisch lesen und schreiben – Schritt für Schritt.")
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    GermanInstruction(introduction)
                    .font(.title3)

                    Label("Kurze, klare Lernschritte", systemImage: "list.bullet.rectangle")
                    Label("Schreiben mit Finger, Pencil oder Papier", systemImage: "pencil.and.scribble")
                    Label("Ohne Zeitdruck und verlorene Serien", systemImage: "timer")
                }

                SpeechMessageView(speechService: speechService)
                InstructionSpeechButton(text: introduction, speechService: speechService)

                Button("Lernen beginnen", action: completeOnboarding)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("start-learning")

                Button("Lesbarkeit und Fokus anpassen", action: openSettings)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding()
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .task {
            if readInstructions {
                speechService.speak(introduction, locale: .german)
            }
        }
    }
}
