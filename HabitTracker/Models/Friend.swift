//
//  Friend.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 18/11/24.
//

import Foundation
import GRDB


struct Friend: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var name: String
    var frequency: Int
    var birthday: Date?
    var lastCall: Date?
    var onBirthday: Bool = false
    
    static let databaseTableName = "friends"
}
