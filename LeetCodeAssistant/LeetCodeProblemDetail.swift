//
//  LeetCodeProblemDetail.swift
//  LeetCodeAssistant
//
//  Created by Ryo Togashi on 2019-09-23.
//  Copyright © 2019 Kohei Asai. All rights reserved.
//

import Foundation


protocol LeetCodeProblemDetail {
    var id: String { get }
    var title: String { get }
    var content: String { get }
    var isPaidOnly: bool { get }
    var likes: Int { get }
    var dislikes: Int { get }
    var isLiked: bool { get }
    var similarQuestions: String { get }
    var stats: String { get }
}
