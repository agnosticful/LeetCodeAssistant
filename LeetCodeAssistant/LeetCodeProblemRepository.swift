import Foundation

class LeetCodeProblemRepository {
    func getAllProblems(completion: ([UserLeetCodeProblem]?, Error?) -> Void) {
        // TODO: replace with actual implementation that calls Web API

        completion([
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "two-sum", number: 1, difficulty: .easy, title: "Two Sum"),
                status: .solved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "add-two-numbers", number: 2, difficulty: .medium, title: "Add Two Numbers"),
                status: .unsolved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "longest-substring-without-repeating-characters", number: 3, difficulty: .medium, title: "Longest Substring Without Repeating Characters"),
                status: .unsolved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "median-of-two-sorted-arrays", number: 4, difficulty: .hard, title: "Median of Two Sorted Arrays "),
                status: .unsolved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "longest-palindromic-substring", number: 5, difficulty: .medium, title: "Longest Palindromic Substring    "),
                status: .unsolved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "zigzag-conversion", number: 6, difficulty: .medium, title: "ZigZag Conversion"),
                status: .unsolved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "reverse-integer", number: 7, difficulty: .easy, title: "Reverse Integer"),
                status: .solved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "string-to-integer-atoi", number: 8, difficulty: .medium, title: "String to Integer (atoi)"),
                status: .unsolved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "palindrome-number", number: 9, difficulty: .easy, title: "Palindrome Number"),
                status: .solved
            ),
            UserLeetCodeProblem(
                problem: LeetCodeProblem(id: "regular-expression-matching", number: 10, difficulty: .hard, title: "Regular Expression Matching"),
                status: .unsolved
            ),
        ], nil)
    }
}
