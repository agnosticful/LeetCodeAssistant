import Foundation

class LeetCodeProblemRepository {
    var sessionToken: String?
    
    func signIn(username: String, password: String, completion: @escaping (String?, Error?) -> Void) {
        URLSession.shared.dataTask(with: URL(string: "https://leetcode.com/accounts/login/")!) { (data, response, error) in
            let response = response as! HTTPURLResponse
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as! [String: String], for: response.url!)
            let csrfTokenCookie = cookies.first { $0.name == "csrftoken" }

            guard let csrfToken = csrfTokenCookie?.value else {
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
        }.resume()
    }
    
    func signOut() {
        sessionToken = nil
    }
    

    
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
    
    class DelegateToHandle302: NSObject, URLSessionTaskDelegate {
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

enum LeetCodeSigninError: Error {
    case wrongEmailOrPassword
}
