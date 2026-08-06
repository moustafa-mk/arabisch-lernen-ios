import SwiftUI

struct RootView: View {
    @ObservedObject var appStore: AppStore

    @AppStorage(PreferenceKey.onboardingComplete) private var onboardingComplete = false
    @AppStorage(PreferenceKey.backgroundStyle) private var backgroundStyle = 0
    @Environment(\.colorScheme) private var colorScheme
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background(style: backgroundStyle, colorScheme: colorScheme)
                    .ignoresSafeArea()

                if let curriculum = appStore.curriculum {
                    if onboardingComplete {
                        HomeView(
                            curriculum: curriculum,
                            speechService: appStore.speechService,
                            openSettings: { showsSettings = true }
                        )
                    } else {
                        OnboardingView(
                            speechService: appStore.speechService,
                            openSettings: { showsSettings = true },
                            completeOnboarding: { onboardingComplete = true }
                        )
                    }
                } else if let loadingError = appStore.loadingError {
                    ContentUnavailableView {
                        Label("Lerninhalte nicht verfügbar", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(loadingError)
                    } actions: {
                        Button("Erneut versuchen") {
                            appStore.retryLoadingCurriculum()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                    .accessibilityIdentifier("curriculum-error")
                } else {
                    ProgressView("Lerninhalte werden vorbereitet …")
                        .accessibilityIdentifier("curriculum-loading")
                }
            }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
        .task {
            appStore.loadCurriculumIfNeeded()
        }
    }
}
