import Foundation

protocol LeetCodeSubmission {
    var id: Int { get }
    var status: LeetCodeSubmissionStatus { get }
    var submittedAt: Date { get }
    var usedLanguage: String { get }
    var runtime: String { get }
    var memoryUsage: String { get }
}

enum LeetCodeSubmissionStatus {
    case accepted
    case failed
}
