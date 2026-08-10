import Foundation

struct AlphabetLetterProgress: Equatable, Sendable {
    let exposureCount: Int
    let mastery: Double
    let nextReviewAt: Date
}

enum AlphabetProgressPolicy {
    static func hasCompletedLesson(_ progress: AlphabetLetterProgress?) -> Bool {
        (progress?.exposureCount ?? 0) > 0
    }

    static func completedCount(
        alphabetOrder: [String],
        progressByID: [String: AlphabetLetterProgress]
    ) -> Int {
        alphabetOrder.filter { hasCompletedLesson(progressByID[$0]) }.count
    }

    static func recommendedLetterID(
        alphabetOrder: [String],
        progressByID: [String: AlphabetLetterProgress],
        now: Date
    ) -> String? {
        let unpracticedID = alphabetOrder.first {
            !hasCompletedLesson(progressByID[$0])
        }
        if let unpracticedID {
            return unpracticedID
        }

        let dueID = alphabetOrder.first {
            guard let progress = progressByID[$0] else {
                return false
            }
            return progress.nextReviewAt <= now
        }
        if let dueID {
            return dueID
        }

        return alphabetOrder.first {
            (progressByID[$0]?.mastery ?? 0) < 0.75
        } ?? alphabetOrder.first
    }
}
