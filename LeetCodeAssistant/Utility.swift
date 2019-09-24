import Foundation

extension String {
    func removeHtmlTag() -> String {
        return replacingOccurrences(of: "<(￥\"[^\"]*\"|'[^']*'|[^'\">])*>", with: "", options: .regularExpression, range: self.range(of: self)).replacingOccurrences(of: "&quot;", with: "").replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "C&#39;s", with: "").replacingOccurrences(of: "&#39;", with: "")
    }
    
    
}

