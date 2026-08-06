import Foundation
import SwiftData

@Model
final class SkillProgress {
    @Attribute(.unique) var skillID: String
    var exposureCount: Int
    var successfulRecalls: Int
    var cueCount: Int
    var mastery: Double
    var lastPracticedAt: Date?
    var nextReviewAt: Date

    init(
        skillID: String,
        exposureCount: Int = 0,
        successfulRecalls: Int = 0,
        cueCount: Int = 0,
        mastery: Double = 0,
        lastPracticedAt: Date? = nil,
        nextReviewAt: Date = .now
    ) {
        self.skillID = skillID
        self.exposureCount = exposureCount
        self.successfulRecalls = successfulRecalls
        self.cueCount = cueCount
        self.mastery = mastery
        self.lastPracticedAt = lastPracticedAt
        self.nextReviewAt = nextReviewAt
    }
}
