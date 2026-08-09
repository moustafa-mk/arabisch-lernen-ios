import Foundation

struct PilotLetterProgress: Equatable, Sendable {
    let exposureCount: Int
    let mastery: Double
    let nextReviewAt: Date
}

enum PilotProgressPolicy {
    static func hasCompletedLesson(_ progress: PilotLetterProgress?) -> Bool {
        (progress?.exposureCount ?? 0) > 0
    }

    static func completedCount(
        pilotOrder: [String],
        progressByID: [String: PilotLetterProgress]
    ) -> Int {
        pilotOrder.filter { hasCompletedLesson(progressByID[$0]) }.count
    }

    static func recommendedLetterID(
        pilotOrder: [String],
        progressByID: [String: PilotLetterProgress],
        now: Date
    ) -> String? {
        let unpracticedID = pilotOrder.first {
            !hasCompletedLesson(progressByID[$0])
        }
        if let unpracticedID {
            return unpracticedID
        }

        let dueID = pilotOrder.first {
            guard let progress = progressByID[$0] else {
                return false
            }
            return progress.nextReviewAt <= now
        }
        if let dueID {
            return dueID
        }

        return pilotOrder.first {
            (progressByID[$0]?.mastery ?? 0) < 0.75
        } ?? pilotOrder.first
    }
}
