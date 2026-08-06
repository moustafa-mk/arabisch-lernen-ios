import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var curriculum: Curriculum?
    @Published private(set) var loadingError: String?

    let speechService = SystemSpeechService()

    func loadCurriculumIfNeeded() {
        guard curriculum == nil, loadingError == nil else {
            return
        }

        do {
            curriculum = try CurriculumLoader.loadBundled()
        } catch {
            loadingError = error.localizedDescription
        }
    }

    func retryLoadingCurriculum() {
        loadingError = nil
        loadCurriculumIfNeeded()
    }
}
