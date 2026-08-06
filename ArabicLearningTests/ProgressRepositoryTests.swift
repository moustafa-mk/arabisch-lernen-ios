import SwiftData
import XCTest
@testable import ArabicLearning

@MainActor
final class ProgressRepositoryTests: XCTestCase {
    func testRecordingPersistsOneSkillAndUpdatesItInPlace() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SkillProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let firstDate = Date(timeIntervalSince1970: 1_700_000_000)

        try ProgressRepository.record(
            skillID: "baa",
            wasCorrect: true,
            usedCue: false,
            now: firstDate,
            context: context
        )
        try ProgressRepository.record(
            skillID: "baa",
            wasCorrect: true,
            usedCue: true,
            now: firstDate.addingTimeInterval(120),
            context: context
        )

        let records = try context.fetch(FetchDescriptor<SkillProgress>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].skillID, "baa")
        XCTAssertEqual(records[0].exposureCount, 2)
        XCTAssertEqual(records[0].successfulRecalls, 2)
        XCTAssertEqual(records[0].cueCount, 1)
    }

    func testBatchRecordingPersistsLetterAndWordTogether() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SkillProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)

        try ProgressRepository.recordBatch(
            [
                ProgressAttempt(skillID: "baa", wasCorrect: true, usedCue: false),
                ProgressAttempt(skillID: "word:bab", wasCorrect: true, usedCue: false)
            ],
            now: Date(timeIntervalSince1970: 1_700_000_000),
            context: context
        )

        let records = try context.fetch(FetchDescriptor<SkillProgress>())
        XCTAssertEqual(Set(records.map(\.skillID)), Set(["baa", "word:bab"]))
        XCTAssertTrue(records.allSatisfy { $0.exposureCount == 1 })
    }
}
