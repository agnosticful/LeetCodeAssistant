import Foundation

class LeetCodeProblemRepository {
    var sessionToken: String?
    
    func signIn(username: String, password: String, completion: @escaping (String?, Error?) -> Void) {
        getCsrfToken { (csrfToken, _) in
            guard let csrfToken = csrfToken else {
                return completion(nil, LeetCodeAPIConnectionError.networkAbort);
            }
            
            guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                return completion(nil, LeetCodeSigninError.unencodableEmailOrPassword);
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
                return completion(nil, LeetCodeAPIConnectionError.networkAbort)
            }
            
            var request = URLRequest(url: URL(string: "https://leetcode.com/api/problems/all/")!)
            
            request.allHTTPHeaderFields = [
                "referer": "https://leetcode.com/problemset/all/",
                "cookie": "csrftoken=\(csrfToken);LEETCODE_SESSION=\(self.sessionToken!)"
            ]
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    return completion(nil, LeetCodeProblemAPIError.inappropriateResponse)
                }
                
                guard let json = try? JSONDecoder().decode(LeetCodeAPIAllJSON.self, from: data) else {
                    return completion(nil, LeetCodeProblemAPIError.inappropriateJSON)
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
                    return completion(nil, LeetCodeSubmissionAPIError.inappropriateResponse)
                }

                guard let json = try? JSONDecoder().decode(LeetCodeSubmissionAPIJSON.self, from: data) else {
                    return completion(nil, LeetCodeSubmissionAPIError.inappropriateJSON)
                }
                
                completion(json.submissions, nil)
            }.resume()
        }
    }
    
    func getSubmittedCode(of submission: LeetCodeSubmission, completion: @escaping (LeetCodeSubmissionCode?, Error?) -> Void) {
        getCsrfToken { (csrfToken, error) in
            guard let csrfToken = csrfToken else {
                return completion(nil, LeetCodeAPIConnectionError.networkAbort)
            }

            var request = URLRequest(url: URL(string: "https://leetcode.com/submissions/detail/\(submission.id)/")!)
            request.allHTTPHeaderFields = [
                "referer": "https://leetcode.com/problems/",
                "cookie": "csrftoken=\(csrfToken);LEETCODE_SESSION=\(self.sessionToken!)",
            ]

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    return completion(nil, LeetCodeSubmissionAPIError.inappropriateResponse)
                }

                guard let body = String(data: data, encoding: .utf8) else {
                    return completion(nil, LeetCodeSubmissionAPIError.inappropriateJSON)
                }
                
                let regexForCode = try! NSRegularExpression(pattern: "',\\n *submissionCode: '(.+)',\\n *editCodeUrl: *'\\/problems\\/")
                let firstMathInHTML = regexForCode.firstMatch(in: body, options: [], range: NSRange(location: 0, length: body.utf16.count))
                var code = String(body[Range(firstMathInHTML!.range(at: 1), in: body)!])
                
                let regexForEncodedCharactor = try! NSRegularExpression(pattern: "\\\\u[0-9A-F]{4}")
                let encodedCharactorMatches = regexForEncodedCharactor.matches(in: code, options: [], range: NSRange(location: 0, length: code.utf16.count))
                
                var offset = 0
                
                for match in encodedCharactorMatches {
                    let range = code.index(code.startIndex, offsetBy: match.range.location + offset)..<code.index(code.startIndex, offsetBy: match.range.location + match.range.length + offset)
                    let hexPart = code[code.index(range.lowerBound, offsetBy: 2)..<range.upperBound]
                    let decodedCharacter = Unicode.Scalar(UInt16(hexPart, radix: 16)!)!

                    code = code.replacingCharacters(in: range, with: String(decodedCharacter))
                    
                    offset -= 5
                }

                completion(code, nil)
            }.resume()
        }
    }
    
    
    func getProblemDescription(id: String, completion: @escaping (LeetCodeProblemDescription?, Error?) -> Void) {
        
        getCsrfToken { (csrfToken, error) in
            guard let csrfToken = csrfToken else {
                return completion(nil, LeetCodeAPIConnectionError.networkAbort)
            }
            var request = URLRequest(url: URL(string: "https://leetcode.com/graphql")!)

            request.allHTTPHeaderFields = [
                "content-type": "application/json",
                "x-csrftoken": csrfToken,
            ]
            request.httpMethod = "POST"
            request.httpBody = "{\"query\":\"{  question(titleSlug: \\\"\(id)\\\")\\n    {\\n    content\\n    }\\n}\"}".data(using: .utf8)
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    return completion(nil, LeetCodeProblemDescriptionAPIError.inappropriateResponse)
                }
                
                guard let leetCodeDetailAPIAllJSON = try? JSONDecoder().decode(LeetCodeDetailAPIAllJSON.self, from: data) else {
                    return completion(nil, LeetCodeProblemDescriptionAPIError.inappropriateJSON)
                }
                
                completion(leetCodeDetailAPIAllJSON.content, nil)
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
    
    static let shared = LeetCodeProblemRepository()
}

enum LeetCodeAPIConnectionError: Error {
    case networkAbort
}

enum LeetCodeSigninError: Error {
    case unencodableEmailOrPassword
    case wrongEmailOrPassword
}

enum LeetCodeProblemAPIError: Error {
    case inappropriateResponse
    case inappropriateJSON
}

enum LeetCodeSubmissionAPIError: Error {
    case inappropriateResponse
    case inappropriateJSON
}

enum LeetCodeProblemDescriptionAPIError: Error {
    case inappropriateResponse
    case inappropriateJSON
}

enum APILeetCodeSubmissionError: Error {
    case submittedAtDecodeFailure
}

fileprivate struct LeetCodeAPIAllJSON: Decodable {
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

fileprivate struct LeetCodeDetailAPIAllJSON: Decodable {
    let content: LeetCodeProblemDescription

    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       let questionContainer = try container.nestedContainer(keyedBy: QuestionCodingKeys.self, forKey: .data)
       let descriptionContent = try questionContainer.nestedContainer(keyedBy:  DescriptionCodingKeys.self, forKey: .question)
       let contentWithHtmlTag = try descriptionContent.decode(LeetCodeProblemDescription.self, forKey: .content)
       
       content = removeHtmlTag(contentWithHtmlTag)
    }

    private enum CodingKeys: String, CodingKey {
       case data = "data"
    }

    private enum QuestionCodingKeys: String, CodingKey {
       case question = "question"
    }

    private enum DescriptionCodingKeys: String, CodingKey {
       case content = "content"
    }
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
    var id: Int
    var status: LeetCodeSubmissionStatus
    var submittedAt: Date
    var usedLanguage: String
    var runtime: String
    var memoryUsage: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        let statusString = try container.decode(String.self, forKey: .statusString)
        let submissionTimestamp = try container.decode(String.self, forKey: .submissionTimestamp)

        id = Int(idString)!
        usedLanguage = sanitizeUsedLanguage(try container.decode(String.self, forKey: .usedLanguage))
        runtime = sanitizeRuntime(try container.decode(String.self, forKey: .runtimeDurationString))
        memoryUsage = sanitizeMemoryUsage(try container.decode(String.self, forKey: .usedMemoryString))
        
        switch statusString {
        case "Accepted":
            status = .accepted
        default:
            status = .failed
        }
        
        submittedAt = Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(Int(submissionTimestamp)!)))
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case statusString = "statusDisplay"
        case usedLanguage = "lang"
        case runtimeDurationString = "runtime"
        case usedMemoryString = "memory"
        case submissionTimestamp = "timestamp"
    }
}

fileprivate func sanitizeUsedLanguage(_ language: String) -> String {
    switch language {
    case "javascript":
        return "JavaScript"
    default:
        return language.capitalized
    }
}

fileprivate func sanitizeRuntime(_ runtime: String) -> String {
    return runtime == "N/A" ? "0 ms" : runtime
}

fileprivate func sanitizeMemoryUsage(_ memoryUsage: String) -> String {
    return memoryUsage == "N/A" ? "0 MB" : memoryUsage
}

fileprivate func removeHtmlTag(_ content: String) -> String {
    return content
        .replacingOccurrences(of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>", with: "", options: .regularExpression, range: content.range(of: content))
        .replacingOccurrences(of: "&quot;", with: "")
        .replacingOccurrences(of: "&nbsp;", with: "")
        .replacingOccurrences(of: "&#39;", with: "'")
}
