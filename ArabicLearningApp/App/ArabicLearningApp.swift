import SwiftData
import SwiftUI

@main
struct ArabicLearningApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var appStore = AppStore()

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if isUITesting {
            UserDefaults.standard.removePersistentDomain(
                forName: Bundle.main.bundleIdentifier ?? "com.example.ArabicLearning"
            )
        }

        let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        do {
            modelContainer = try ModelContainer(
                for: SkillProgress.self,
                configurations: configuration
            )
        } catch {
            fatalError("The local learning database could not be created: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(appStore: appStore)
        }
        .modelContainer(modelContainer)
    }
}
