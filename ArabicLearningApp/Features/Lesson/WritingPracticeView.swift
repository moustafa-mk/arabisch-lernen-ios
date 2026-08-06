import PencilKit
import SwiftUI

private enum WritingMode: String, CaseIterable, Identifiable {
    case screen
    case paper

    var id: String { rawValue }
    var title: String {
        switch self {
        case .screen:
            return "Auf Bildschirm"
        case .paper:
            return "Auf Papier"
        }
    }
}

struct WritingPracticeView: View {
    let letter: LetterContent
    let word: WordContent
    @ObservedObject var speechService: SystemSpeechService
    let progress: Double
    let onClose: () -> Void
    let onComplete: (Bool) -> Void

    @State private var mode = WritingMode.screen
    @State private var canvasView = PKCanvasView()
    @State private var showsGuide = true
    @State private var guideReplayID = 0
    @State private var paperCompleted = false
    @State private var pdfURL: URL?
    @State private var errorMessage: String?

    @AppStorage(PreferenceKey.calmMode) private var calmMode = false
    @AppStorage(PreferenceKey.readInstructions) private var readInstructions = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var allowsAnimation: Bool {
        AccessibilityPreferenceResolver.allowsInstructionalAnimation(
            calmMode: calmMode,
            systemReduceMotion: systemReduceMotion
        )
    }

    private var screenInstruction: String {
        "Schreibe \(letter.nameGerman) von rechts nach links. Die Bewegung wird gezeigt, aber deine Strichfolge wird nicht streng bewertet."
    }

    private var paperInstruction: String {
        "Übe mit Stift auf Papier. Erstelle und teile das Blatt und bestätige danach deine Übung."
    }

    var body: some View {
        LessonShell(
            title: "Schreiben",
            progress: progress,
            onClose: onClose
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Schreibmodus", selection: $mode) {
                    ForEach(WritingMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .screen {
                    screenPractice
                } else {
                    paperPractice
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            AppColor.terracottaSoft,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .accessibilityIdentifier("writing-error")
                }
            }
            .task {
                if readInstructions {
                    speechService.speak(screenInstruction, locale: .german)
                }
            }
            .onChange(of: mode) { _, newMode in
                if readInstructions {
                    speechService.speak(
                        newMode == .screen ? screenInstruction : paperInstruction,
                        locale: .german
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var screenPractice: some View {
        let instruction = VStack(alignment: .leading, spacing: 10) {
            Text("Schreibe \(letter.glyph) von rechts nach links.")
                .font(.title2.bold())
            GermanInstruction(
                "Die Bewegung wird gezeigt, aber deine Strichfolge wird nicht streng bewertet."
            )
            Toggle("Schreibweg anzeigen", isOn: $showsGuide)
            Label("Finger und Apple Pencil funktionieren beide.", systemImage: "pencil.tip")
                .font(.callout)
            InstructionSpeechButton(
                text: screenInstruction,
                speechService: speechService
            )
        }

        let canvas = ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColor.warmWhite)
            ArabicGlyphView(
                letter.glyph,
                accessibilityName: letter.nameGerman,
                baseSize: 150
            )
            .foregroundStyle(AppColor.ink.opacity(0.08))
            .accessibilityHidden(true)
            if showsGuide {
                LetterStrokeGuide(letter: letter, animate: allowsAnimation)
                    .padding(44)
                    .id(guideReplayID)
            }
            WritingCanvas(
                canvasView: canvasView,
                accessibilityLabel: "Schreibfläche für \(letter.nameGerman)"
            )
        }
        .frame(minHeight: horizontalSizeClass == .regular ? 390 : 300)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColor.divider, style: StrokeStyle(lineWidth: 1, dash: [7]))
        }

        if horizontalSizeClass == .regular {
            HStack(alignment: .top, spacing: 20) {
                instruction
                    .frame(maxWidth: 250, alignment: .leading)
                    .appCard()
                canvas
            }
        } else {
            instruction
            canvas
        }

        HStack {
            Button {
                canvasView.drawing = PKDrawing()
                errorMessage = nil
            } label: {
                Label("Löschen", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                guideReplayID += 1
            } label: {
                Label("Zeigen", systemImage: "play")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!showsGuide)
        }

        Button("Fertig") {
            guard !canvasView.drawing.strokes.isEmpty else {
                errorMessage = "Schreibe zuerst auf die Fläche oder wechsle zur Papierübung."
                return
            }
            onComplete(true)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("complete-screen-writing")
    }

    @ViewBuilder
    private var paperPractice: some View {
        Text("Mit Stift auf Papier üben")
            .font(.title2.bold())

        GermanInstruction(
            "Erstelle das Blatt, drucke oder teile es und setze danach die Bestätigung. Papierübung wird nicht automatisch bewertet."
        )
        InstructionSpeechButton(text: paperInstruction, speechService: speechService)
        SpeechMessageView(speechService: speechService)

        VStack(alignment: .leading, spacing: 12) {
            Label("Vier Schreibzeilen mit \(letter.glyph)", systemImage: "doc.text")
            Label("Beispielwort \(word.arabicVowelized)", systemImage: "textformat")
            Label("Keine Zeitvorgabe", systemImage: "timer")
        }
        .appCard()

        Button {
            do {
                pdfURL = try PracticeSheetRenderer.writeTemporarySheet(
                    letter: letter,
                    word: word
                )
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        } label: {
            Label("Übungsblatt erstellen", systemImage: "doc.badge.plus")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("create-practice-sheet")

        if let pdfURL {
            ShareLink(item: pdfURL) {
                Label("Drucken oder teilen", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("share-practice-sheet")
        }

        Toggle("Ich habe auf Papier geübt", isOn: $paperCompleted)
            .font(.headline)
            .padding(.vertical, 8)
            .accessibilityIdentifier("paper-practice-confirmation")

        Button("Fertig") {
            onComplete(paperCompleted)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!paperCompleted)
        .accessibilityIdentifier("complete-paper-writing")
    }
}
