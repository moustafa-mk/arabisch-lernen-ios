import SwiftUI

private enum LessonStep: Int {
    case discover
    case discriminate
    case write
    case word
    case summary

    var progress: Double {
        Double(rawValue + 1) / 5.0
    }
}

struct LessonFlowView: View {
    let curriculum: Curriculum
    let letter: LetterContent
    @ObservedObject var speechService: SystemSpeechService

    @Environment(\.dismiss) private var dismiss
    @State private var step = LessonStep.discover
    @State private var usedCue = false
    @State private var activitiesCorrect = true
    @State private var practicedWriting = false

    private var focusWord: WordContent {
        curriculum.firstWord(focusingOn: letter.id) ?? curriculum.words[0]
    }

    var body: some View {
        Group {
            switch step {
            case .discover:
                LetterDiscoveryView(
                    letter: letter,
                    speechService: speechService,
                    progress: step.progress,
                    onClose: { dismiss() },
                    onContinue: { step = .discriminate }
                )
            case .discriminate:
                LetterDiscriminationView(
                    curriculum: curriculum,
                    letter: letter,
                    speechService: speechService,
                    progress: step.progress,
                    onClose: { dismiss() }
                ) { neededCue in
                    usedCue = usedCue || neededCue
                    activitiesCorrect = activitiesCorrect && !neededCue
                    step = .write
                }
            case .write:
                WritingPracticeView(
                    letter: letter,
                    word: focusWord,
                    speechService: speechService,
                    progress: step.progress,
                    onClose: { dismiss() }
                ) { didPractice in
                    practicedWriting = didPractice
                    step = .word
                }
            case .word:
                WordBridgeView(
                    curriculum: curriculum,
                    word: focusWord,
                    speechService: speechService,
                    progress: step.progress,
                    onClose: { dismiss() }
                ) { wasCorrect, neededCue in
                    activitiesCorrect = activitiesCorrect && wasCorrect
                    usedCue = usedCue || neededCue
                    step = .summary
                }
            case .summary:
                LessonSummaryView(
                    letter: letter,
                    word: focusWord,
                    speechService: speechService,
                    wasCorrect: activitiesCorrect,
                    usedCue: usedCue,
                    practicedWriting: practicedWriting,
                    progress: step.progress,
                    onClose: { dismiss() },
                    onFinish: { dismiss() }
                )
            }
        }
        .interactiveDismissDisabled(step != .summary)
    }
}
