//
//  Int+Extensions.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 05/11/24.
//

import Foundation

extension Int {
    func ordinalSuffix() -> String {
        let suffix: String
        switch self % 10 {
        case 1: suffix = (self % 100 == 11) ? "th" : "st"
        case 2: suffix = (self % 100 == 12) ? "th" : "nd"
        case 3: suffix = (self % 100 == 13) ? "th" : "rd"
        default: suffix = "th"
        }
        return "\(self)\(suffix)"
    }
}
