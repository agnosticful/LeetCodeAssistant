import Foundation

class LeetCodeProblemCache {
    func loadAllUserLeetCodeProblems() -> [UserLeetCodeProblem]? {
        guard let data = try? Data(contentsOf: LeetCodeProblemCache.userLeetCodeProblemListPath) else {
            return nil
        }

        guard let problems = try? PropertyListDecoder().decode([CodableUserLeetCodeProblem].self, from: data) else {
            return nil
        }
        
        debugPrint("problem cache has been loaded")

        return problems
    }

    func saveAllUserLeetCodeProblems(problems: [UserLeetCodeProblem]) {
        let codableProblems = problems.map { CodableUserLeetCodeProblem.init(from: $0) }

        guard let data = try? PropertyListEncoder().encode(codableProblems) else {
            return
        }

        try? data.write(to: LeetCodeProblemCache.userLeetCodeProblemListPath, options: .noFileProtection)
        
        debugPrint("problem cache has been saved")
    }
    
    static let shared = LeetCodeProblemCache()
    
    private static let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    private static let userLeetCodeProblemListPath = cacheDirectory.appendingPathComponent("problems").appendingPathExtension("plist")
}

struct CodableLeetCodeProblem: LeetCodeProblem, Codable {
    var id: String
    var number: Int
    var difficulty: LeetCodeProblemDifficuly
    var title: String
    
    init(from noncodable: LeetCodeProblem) {
        id = noncodable.id
        number = noncodable.number
        difficulty = noncodable.difficulty
        title = noncodable.title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let difficultyString = try container.decode(String.self, forKey: .difficulty)

        id = try container.decode(String.self, forKey: .id)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        
        switch difficultyString {
        case "EASY":
            difficulty = .easy
        case "MEDIUM":
            difficulty = .medium
        case "HARD":
            difficulty = .hard
        default:
            difficulty = .hard

            assertionFailure()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var difficultyString: String!
        switch difficulty {
        case .easy:
            difficultyString = "EASY"
        case .medium:
            difficultyString = "MEDIUM"
        case .hard:
            difficultyString = "HARD"
        }
        
        try container.encode(id, forKey: .id)
        try container.encode(number, forKey: .number)
        try container.encode(difficultyString, forKey: .difficulty)
        try container.encode(title, forKey: .title)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case number = "number"
        case difficulty = "difficulty"
        case title = "title"
    }
}

struct CodableUserLeetCodeProblem: UserLeetCodeProblem, Codable {
    private var codableProblem: CodableLeetCodeProblem
    var problem: LeetCodeProblem { get { return codableProblem } }
    var status: UserLeetCodeProblemStatus
    
    init(from noncodable: UserLeetCodeProblem) {
        codableProblem = CodableLeetCodeProblem(from: noncodable.problem)
        status = noncodable.status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusString = try container.decode(String.self, forKey: .status)

        codableProblem = try container.decode(CodableLeetCodeProblem.self, forKey: .problem)
        
        switch statusString {
        case "NOT_ACCEPTED":
            status = .attempted
        case "ACCEPTED":
            status = .solved
        case "NULL":
            status = .unsolved
        default:
            status = .unsolved
            
            assertionFailure()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var statusString: String!
        switch status {
        case .attempted:
            statusString = "NOT_ACCEPTED"
        case .solved:
            statusString = "ACCEPTED"
        case .unsolved:
            statusString = "NULL"
        }

        try container.encode(codableProblem, forKey: .problem)
        try container.encode(statusString, forKey: .status)
    }
    
    private enum CodingKeys: String, CodingKey {
        case problem = "problem"
        case status = "status"
    }
}
