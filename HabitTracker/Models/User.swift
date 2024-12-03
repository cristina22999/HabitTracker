//
//  User.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 30/10/24.
//

import GRDB

struct User: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var username: String
    var password: String
}
