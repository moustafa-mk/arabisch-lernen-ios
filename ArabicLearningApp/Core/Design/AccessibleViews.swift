import SwiftUI

struct ArabicGlyphView: View {
    let glyph: String
    let accessibilityName: String
    var scale: Double = 1
    var baseSize: CGFloat = 88

    @ScaledMetric(relativeTo: .largeTitle) private var scaledSize: CGFloat = 88

    init(
        _ glyph: String,
        accessibilityName: String,
        scale: Double = 1,
        baseSize: CGFloat = 88
    ) {
        self.glyph = glyph
        self.accessibilityName = accessibilityName
        self.scale = scale
        self.baseSize = baseSize
        _scaledSize = ScaledMetric(wrappedValue: baseSize, relativeTo: .largeTitle)
    }

    var body: some View {
        Text(glyph)
            .font(.system(size: scaledSize * CGFloat(scale), weight: .medium))
            .environment(\.layoutDirection, .rightToLeft)
            .accessibilityLabel(accessibilityName)
    }
}

struct GermanInstruction: View {
    let text: String

    @AppStorage(PreferenceKey.extraSpacing) private var extraSpacing = false

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .lineSpacing(AccessibilityPreferenceResolver.effectiveLineSpacing(
                extraSpacing: extraSpacing
            ))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppProgressView: View {
    let value: Double

    var body: some View {
        ProgressView(value: min(max(value, 0), 1))
            .tint(AppColor.teal)
            .accessibilityLabel("Lernfortschritt")
            .accessibilityValue("\(Int(value * 100)) Prozent")
    }
}

struct SpeechMessageView: View {
    @ObservedObject var speechService: SystemSpeechService

    var body: some View {
        if let message = speechService.message {
            Label(message, systemImage: "speaker.slash")
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColor.terracottaSoft, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("speech-error")
        }
    }
}

struct InstructionSpeechButton: View {
    let text: String
    @ObservedObject var speechService: SystemSpeechService

    var body: some View {
        Button {
            speechService.speak(text, locale: .german)
        } label: {
            Label("Hinweis vorlesen", systemImage: "speaker.wave.2")
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}
