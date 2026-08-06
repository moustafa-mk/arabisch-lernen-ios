import Foundation
import SwiftData

struct ReviewUpdate: Equatable {
    let exposureCount: Int
    let successfulRecalls: Int
    let cueCount: Int
    let mastery: Double
    let nextReviewAt: Date
}

struct ProgressAttempt {
    let skillID: String
    let wasCorrect: Bool
    let usedCue: Bool
}

enum ReviewScheduler {
    static func update(
        exposureCount: Int,
        successfulRecalls: Int,
        cueCount: Int,
        wasCorrect: Bool,
        usedCue: Bool,
        now: Date,
        calendar: Calendar = .current
    ) -> ReviewUpdate {
        let newExposureCount = exposureCount + 1
        let newSuccessfulRecalls = successfulRecalls + (wasCorrect ? 1 : 0)
        let newCueCount = cueCount + (usedCue ? 1 : 0)

        let rawMastery = (
            Double(newSuccessfulRecalls) - Double(newCueCount) * 0.35
        ) / Double(newExposureCount)
        let mastery = min(max(rawMastery, 0), 1)

        let dayInterval: Int
        if !wasCorrect {
            dayInterval = 0
        } else if usedCue {
            dayInterval = 1
        } else {
            switch newSuccessfulRecalls {
            case 0...1:
                dayInterval = 1
            case 2:
                dayInterval = 3
            case 3:
                dayInterval = 7
            default:
                dayInterval = 14
            }
        }

        let nextReviewAt: Date
        if dayInterval == 0 {
            nextReviewAt = calendar.date(byAdding: .minute, value: 10, to: now) ?? now
        } else {
            nextReviewAt = calendar.date(byAdding: .day, value: dayInterval, to: now) ?? now
        }

        return ReviewUpdate(
            exposureCount: newExposureCount,
            successfulRecalls: newSuccessfulRecalls,
            cueCount: newCueCount,
            mastery: mastery,
            nextReviewAt: nextReviewAt
        )
    }
}

enum ProgressRepository {
    @MainActor
    @discardableResult
    static func record(
        skillID: String,
        wasCorrect: Bool,
        usedCue: Bool,
        now: Date = .now,
        context: ModelContext
    ) throws -> SkillProgress {
        let progress = try update(
            skillID: skillID,
            wasCorrect: wasCorrect,
            usedCue: usedCue,
            now: now,
            context: context
        )
        try context.save()
        return progress
    }

    @MainActor
    static func recordBatch(
        _ attempts: [ProgressAttempt],
        now: Date = .now,
        context: ModelContext
    ) throws {
        do {
            for attempt in attempts {
                _ = try update(
                    skillID: attempt.skillID,
                    wasCorrect: attempt.wasCorrect,
                    usedCue: attempt.usedCue,
                    now: now,
                    context: context
                )
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    @MainActor
    private static func update(
        skillID: String,
        wasCorrect: Bool,
        usedCue: Bool,
        now: Date,
        context: ModelContext
    ) throws -> SkillProgress {
        let existing = try context.fetch(FetchDescriptor<SkillProgress>())
            .first { $0.skillID == skillID }
        let progress = existing ?? SkillProgress(skillID: skillID)
        if existing == nil {
            context.insert(progress)
        }

        let update = ReviewScheduler.update(
            exposureCount: progress.exposureCount,
            successfulRecalls: progress.successfulRecalls,
            cueCount: progress.cueCount,
            wasCorrect: wasCorrect,
            usedCue: usedCue,
            now: now
        )
        progress.exposureCount = update.exposureCount
        progress.successfulRecalls = update.successfulRecalls
        progress.cueCount = update.cueCount
        progress.mastery = update.mastery
        progress.lastPracticedAt = now
        progress.nextReviewAt = update.nextReviewAt
        return progress
    }
}
