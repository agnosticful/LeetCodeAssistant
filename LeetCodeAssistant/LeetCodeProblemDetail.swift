import Foundation


protocol LeetCodeProblemDetail {
    var questionId: String { get }
    var title: String { get }
    var content: String { get }
    var likes: Int { get }
    var dislikes: Int { get }
    var similarQuestions: String { get }
    var stats: String { get }
}
