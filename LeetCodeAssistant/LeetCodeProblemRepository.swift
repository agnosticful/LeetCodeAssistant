import Foundation

class LeetCodeProblemRepository {
    var sessionToken: String?
    
    func signIn(username: String, password: String, completion: @escaping (String?, Error?) -> Void) {
        getCsrfToken { (csrfToken, _) in
            guard let csrfToken = csrfToken else {
                return
            }
            
            guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                return
            }
            
            var request = URLRequest(url: URL(string: "https://leetcode.com/accounts/login/")!)
            
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = [
                "content-type": "application/x-www-form-urlencoded; charset=utf-8",
                "referer": "https://leetcode.com/accounts/login/",
                "cookie": "csrftoken=\(csrfToken)"
            ]
            request.httpBody = "csrfmiddlewaretoken=\(csrfToken)&login=\(encodedUsername)&password=\(encodedPassword)&next=%2Fproblems".data(using: .utf8)
            
            let delegate = DelegateToHandle302 { (response) in
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as! [String: String], for: response.url!)
                let sessionCookie = cookies.first { $0.name == "LEETCODE_SESSION" }
                
                if let sessionCookie = sessionCookie {
                    self.sessionToken = sessionCookie.value
                    
                    completion(sessionCookie.value, nil)
                }
            }
            
            URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                .dataTask(with: request) { (data, response, error) in
                    completion(nil, LeetCodeSigninError.wrongEmailOrPassword)
                }
                .resume()
        }
    }
    
    func signOut() {
        sessionToken = nil
    }

    func getAllProblems(completion: @escaping ([UserLeetCodeProblem]?, Error?) -> Void) {
        getCsrfToken { (csrfToken, _) in
            guard let csrfToken = csrfToken else {
                return
            }
            
            var request = URLRequest(url: URL(string: "https://leetcode.com/api/problems/all/")!)
            
            request.allHTTPHeaderFields = [
                "referer": "https://leetcode.com/problemset/all/",
                "cookie": "csrftoken=\(csrfToken);LEETCODE_SESSION=\(self.sessionToken!)"
            ]
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    return completion(nil, nil)
                }
                
                guard let json = try? JSONDecoder().decode(LeetCodeAPIAllJSON.self, from: data) else {
                    return completion(nil, nil)
                }
                
                completion(json.problems, nil)
            }.resume()
        }
    }
    
    func getAllSubmissions(of problem: LeetCodeProblem, completion: @escaping ([LeetCodeSubmission]?, Error?) -> Void) {
        getCsrfToken { (csrfToken, error) in
            guard let csrfToken = csrfToken else {
                return completion(nil, LeetCodeAPIConnectionError.networkAbort)
            }

            var request = URLRequest(url: URL(string: "https://leetcode.com/graphql")!)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = [
                "content-type": "application/json; charset=utf-8",
                "referer": "https://leetcode.com/problems/\(problem.id)/submissions/",
                "cookie": "csrftoken=\(csrfToken);LEETCODE_SESSION=\(self.sessionToken!)",
                "x-csrftoken": csrfToken
            ]
            request.httpBody = "{\"operationName\":\"Submissions\",\"variables\":{\"offset\":0,\"limit\":50,\"lastKey\":null,\"questionSlug\":\"\(problem.id)\"},\"query\":\"query Submissions($offset: Int!, $limit: Int!, $lastKey: String, $questionSlug: String!) { submissionList(offset: $offset, limit: $limit, lastKey: $lastKey, questionSlug: $questionSlug) { lastKey hasNext submissions { id statusDisplay lang runtime timestamp url isPending memory __typename } __typename }}\"}".data(using: .utf8)

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    return completion(nil, LeetCodeSubmissionAPIError.noPreciseResponseReturned)
                }

                guard let json = try? JSONDecoder().decode(LeetCodeSubmissionAPIJSON.self, from: data) else {
                    return completion(nil, LeetCodeSubmissionAPIError.jsonDecodeFailed)
                }
                
                completion(json.submissions, nil)
            }.resume()
        }
    }

func getProblemDetail(titleSlug: String, completion: @escaping (LeetCodeProblemDetail) -> Void) {
    
    getCsrfToken { (csrfToken, error) in
        guard let csrfToken = csrfToken else {
            return
        }
        var request = URLRequest(url: URL(string: "https://leetcode.com/graphql")!)

        request.allHTTPHeaderFields = [
            "content-type": "application/json",
            "x-csrftoken": csrfToken,
        ]
        
        request.httpMethod = "POST"
        
        request.httpBody = "{\"query\":\"{  question(titleSlug: \\\"\(titleSlug)\\\")\\n    {\\n    questionId\\n    title\\n    content\\n    likes\\n    dislikes\\n    similarQuestions\\n    stats\\n    }\\n}\"}".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            let jsonData = try! JSONDecoder().decode(LeetCodeDetailAPIAllJSON.self, from: data)
            
            completion(jsonData.data.question)
        }.resume()
    }
}
    
    
    private func getCsrfToken(completion: @escaping (String?, Error?) -> Void) {
        URLSession.shared.dataTask(with: URL(string: "https://leetcode.com/accounts/login/")!) { (data, response, error) in
            let response = response as! HTTPURLResponse
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as! [String: String], for: response.url!)
            let csrfTokenCookie = cookies.first { $0.name == "csrftoken" }

            guard let csrfToken = csrfTokenCookie?.value else {
                return completion(nil, nil)
            }
            
            completion(csrfToken, nil)
        }.resume()
    }
    
    private class DelegateToHandle302: NSObject, URLSessionTaskDelegate {
        var compl: (_ response: HTTPURLResponse) -> Void
        
        init(completion: @escaping (_ response: HTTPURLResponse) -> Void) {
            compl = completion
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            compl(response)
        }
    }
    
    private struct LeetCodeAPIAllJSON: Decodable {
        var problems: [APIUserLeetCodeProblem]
        
        private enum CodingKeys: String, CodingKey {
            case problems = "stat_status_pairs"
        }
        
        struct APIUserLeetCodeProblem: Decodable, UserLeetCodeProblem {
            var problem: LeetCodeProblem
            var status: UserLeetCodeProblemStatus
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let statContainer = try container.nestedContainer(keyedBy: StatCodingKeys.self, forKey: .stat)
                let difficultyContainer = try container.nestedContainer(keyedBy: DifficultyCodingKeys.self, forKey: .difficulty)
                
                let id = try statContainer.decode(String.self, forKey: .id)
                let number = try statContainer.decode(Int.self, forKey: .number)
                let difficultyInt = try difficultyContainer.decode(Int.self, forKey: .difficulty)
                let title = try statContainer.decode(String.self, forKey: .title)
                let statusString = try container.decode(String?.self, forKey: .status)
                
                var difficulty: LeetCodeProblemDifficuly!
                
                switch difficultyInt {
                case 1:
                    difficulty = .easy
                case 2:
                    difficulty = .medium
                case 3:
                    difficulty = .hard
                default:
                    assertionFailure()
                }
                
                problem = APILeetCodeProblem(id: id, number: number, difficulty: difficulty, title: title)
                
                var status: UserLeetCodeProblemStatus!
                
                switch statusString {
                case "ac":
                    status = .solved
                case "notac":
                    status = .attempted
                case nil:
                    status = .unsolved
                default:
                    assertionFailure()
                }
                
                self.status = status
            }
            
            private enum CodingKeys: String, CodingKey {
                case stat = "stat"
                case difficulty = "difficulty"
                case status = "status"
            }
            
            private enum StatCodingKeys: String, CodingKey {
                case id = "question__title_slug"
                case number = "frontend_question_id"
                case title = "question__title"
            }
            
            private enum DifficultyCodingKeys: String, CodingKey {
                case difficulty = "level"
            }
        }
        
        struct APILeetCodeProblem: LeetCodeProblem {
            var id: String
            var number: Int
            var difficulty: LeetCodeProblemDifficuly
            var title: String
        }
    }
    
    private struct LeetCodeDetailAPIAllJSON: Codable {
        let data: Data
        
        struct Data: Codable {
            let question: Question
            
            struct Question: LeetCodeProblemDetail, Codable {
                let questionId: String
                let title: String
                let content: String
                let likes: Int
                let dislikes: Int
                let similarQuestions: String
                let stats: String
                
            }
        }
    }
    
    static let shared = LeetCodeProblemRepository()
}

enum LeetCodeSigninError: Error {
    case wrongEmailOrPassword
}

enum LeetCodeAPIConnectionError: Error {
    case networkAbort
}

enum LeetCodeSubmissionAPIError: Error {
    case noPreciseResponseReturned
    case jsonDecodeFailed
}

fileprivate struct LeetCodeSubmissionAPIJSON: Decodable {
    var submissions: [APILeetCodeSubmission]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)
        let submissionListContainer = try dataContainer.nestedContainer(keyedBy: SubmissionListCodingKeys.self, forKey: .submissionList)

        submissions = try submissionListContainer.decode([APILeetCodeSubmission].self, forKey: .submissions)
    }

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
    
    private enum DataCodingKeys: String, CodingKey {
        case submissionList = "submissionList"
    }
    
    private enum SubmissionListCodingKeys: String, CodingKey {
        case submissions = "submissions"
    }
}

fileprivate struct APILeetCodeSubmission: LeetCodeSubmission, Decodable {
    var status: LeetCodeSubmissionStatus
    var submittedAt: Date
    var usedLanguage: String
    var runtime: String
    var memoryUsage: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusString = try container.decode(String.self, forKey: .statusString)
        let submissionTimestamp = try container.decode(String.self, forKey: .submissionTimestamp)

        usedLanguage = sanitizeUsedLanguage(try container.decode(String.self, forKey: .usedLanguage))
        runtime = sanitizeRuntime(try container.decode(String.self, forKey: .runtimeDurationString))
        memoryUsage = sanitizeMemoryUsage(try container.decode(String.self, forKey: .usedMemoryString))
        
        switch statusString {
        case "Accepted":
            status = .accepted
        default:
            status = .failed
        }

        guard let submissionTimestampInt = Int(submissionTimestamp) else {
            throw APILeetCodeSubmissionError.submittedAtDecodeFailure
        }
        
        submittedAt = Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(submissionTimestampInt)))
    }
    
    private enum CodingKeys: String, CodingKey {
        case statusString = "statusDisplay"
        case usedLanguage = "lang"
        case runtimeDurationString = "runtime"
        case usedMemoryString = "memory"
        case submissionTimestamp = "timestamp"
    }
    
    enum APILeetCodeSubmissionError: Error {
        case submittedAtDecodeFailure
    }
}

fileprivate func sanitizeUsedLanguage(_ language: String) -> String {
    if language == "javascript" {
        return "JavaScript"
    }
    
    return language.capitalized
}

fileprivate func sanitizeRuntime(_ runtime: String) -> String {
    if runtime == "N/A" {
        return "0 ms"
    }
    
    return runtime
}

fileprivate func sanitizeMemoryUsage(_ memoryUsage: String) -> String {
    if memoryUsage == "N/A" {
        return "0 MB"
    }
    
    return memoryUsage
}
