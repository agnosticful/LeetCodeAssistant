import Foundation

struct LeetCodeSubmission {
    var status: LeetCodeSubmissionStatus
    var submittedAt: Date
    var usedLanguage: String
    var runtimeDuration: UnitDuration
    var usedMemoryInBytes: Int
    var code: String
}

enum LeetCodeSubmissionStatus {
    case accepted
    case failed
}
