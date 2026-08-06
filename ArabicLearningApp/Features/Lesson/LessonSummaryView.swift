import SwiftData
import SwiftUI

struct LessonSummaryView: View {
    let letter: LetterContent
    let word: WordContent
    @ObservedObject var speechService: SystemSpeechService
    let wasCorrect: Bool
    let usedCue: Bool
    let practicedWriting: Bool
    let progress: Double
    let onClose: () -> Void
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var didRecord = false
    @State private var isSaving = false
    @State private var persistenceError: String?
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false

    private var instruction: String {
        "Einheit geschafft. Heute hast du \(letter.nameGerman) erkannt, gehört und geschrieben."
    }

    var body: some View {
        LessonShell(
            title: "Einheit geschafft",
            progress: progress,
            onClose: onClose
        ) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 72))
                        .foregroundStyle(AppColor.teal)
                        .accessibilityHidden(true)
                    Text("Heute hast du \(letter.glyph) erkannt, gehört und geschrieben.")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Form und Laut von \(letter.nameGerman)", systemImage: "eye")
                    Label(
                        practicedWriting ? "Schreiben wurde geübt" : "Schreiben kommt erneut",
                        systemImage: "pencil"
                    )
                    Label("Wort \(word.arabicVowelized) · \(word.german)", systemImage: "textformat")
                }
                .appCard()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Beim nächsten Mal")
                        .font(.headline)
                    Text(
                        usedCue
                            ? "Die Aufgabe beginnt wieder mit einer hilfreichen Auswahl."
                            : "Du rufst den Buchstaben mit weniger Hilfen ab."
                    )
                }
                .appCard()

                Label(
                    "Deine Wiederholung wartet, bis du bereit bist.",
                    systemImage: "clock"
                )
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.tealSoft, in: RoundedRectangle(cornerRadius: 14))

                InstructionSpeechButton(text: instruction, speechService: speechService)
                SpeechMessageView(speechService: speechService)

                if let persistenceError {
                    Label(persistenceError, systemImage: "exclamationmark.triangle")
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            AppColor.terracottaSoft,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityIdentifier("progress-save-error")
                }

                if persistenceError == nil {
                    Button("Für heute beenden", action: onFinish)
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!didRecord || isSaving)
                        .accessibilityIdentifier("finish-lesson")
                } else {
                    Button("Speichern erneut versuchen") {
                        saveProgress()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSaving)

                    Button("Ohne Speichern beenden", action: onFinish)
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .task {
            saveProgress()
            if readInstructions {
                speechService.speak(instruction, locale: .german)
            }
        }
    }

    @MainActor
    private func saveProgress() {
        guard !isSaving, !didRecord else {
            return
        }
        isSaving = true
        persistenceError = nil
        do {
            try ProgressRepository.recordBatch(
                [
                    ProgressAttempt(
                        skillID: letter.id,
                        wasCorrect: wasCorrect,
                        usedCue: usedCue
                    ),
                    ProgressAttempt(
                        skillID: "word:\(word.id)",
                        wasCorrect: wasCorrect,
                        usedCue: usedCue
                    )
                ],
                context: modelContext
            )
            didRecord = true
        } catch {
            didRecord = false
            persistenceError = "Der Fortschritt konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
        isSaving = false
    }
}
