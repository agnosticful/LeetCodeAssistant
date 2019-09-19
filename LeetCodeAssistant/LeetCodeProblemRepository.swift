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
    
    static let shared = LeetCodeProblemRepository()
}

enum LeetCodeSigninError: Error {
    case wrongEmailOrPassword
}
