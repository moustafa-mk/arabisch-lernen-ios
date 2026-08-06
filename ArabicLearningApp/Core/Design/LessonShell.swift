import SwiftUI

struct LessonShell<Content: View>: View {
    let title: String
    let progress: Double
    let onClose: () -> Void
    let content: Content

    @AppStorage(PreferenceKey.backgroundStyle) private var backgroundStyle = 0
    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        progress: Double,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.progress = progress
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColor.background(style: backgroundStyle, colorScheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.headline)
                        }
                        .minimumAccessibleTarget()
                        .accessibilityLabel("Lektion schließen")

                        Text(title)
                            .font(.headline)
                            .frame(maxWidth: .infinity)

                        Color.clear
                            .frame(width: 44, height: 44)
                            .accessibilityHidden(true)
                    }

                    AppProgressView(value: progress)
                    content
                }
                .padding()
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
