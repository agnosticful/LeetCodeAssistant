import Foundation

struct LeetCodeProblem {
    var id: String
    var number: Int
    var difficulty: LeetCodeProblemDifficuly
    var title: String
}

enum LeetCodeProblemDifficuly {
    case easy
    case medium
    case hard
}

struct UserLeetCodeProblem {
    var problem: LeetCodeProblem
    var status: UserLeetCodeProblemStatus
}

enum UserLeetCodeProblemStatus {
    case solved
    case attempted
    case unsolved
}
