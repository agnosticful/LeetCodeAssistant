//
//  Utility.swift
//  LeetCodeAssistant
//
//  Created by Ryo Togashi on 2019-09-22.
//  Copyright © 2019 Kohei Asai. All rights reserved.
//

import Foundation

extension String {
    func replaceHtmlTag() -> String {
        return replacingOccurrences(of: "<(￥\"[^\"]*\"|'[^']*'|[^'\">])*>", with: "", options: .regularExpression, range: self.range(of: self)).replacingOccurrences(of: "&quot;", with: "").replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "C&#39;s", with: "")
    }
    
    
}
