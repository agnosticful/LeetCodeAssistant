import Foundation

protocol LeetCodeProblem {
    var id: String { get }
    var number: Int { get }
    var difficulty: LeetCodeProblemDifficuly { get }
    var title: String { get }
}

enum LeetCodeProblemDifficuly {
    case easy
    case medium
    case hard
}

protocol UserLeetCodeProblem {
    var problem: LeetCodeProblem { get }
    var status: UserLeetCodeProblemStatus { get }
}

enum UserLeetCodeProblemStatus {
    case solved
    case attempted
    case unsolved
}
