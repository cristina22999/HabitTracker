//
//  UserRepository.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 30/10/24.
//

import Foundation
import GRDB

class UserRepository {
    static func createUser(username: String, password: String) throws {
        try DatabaseManager.shared.dbQueue.write { db in
            let user = User(username: username, password: password)
            try user.insert(db)
        }
    }
    
    static func fetchUser(username: String, password: String) throws -> User? {
        try DatabaseManager.shared.dbQueue.read { db in
            try User.filter(Column("username") == username && Column("password") == password).fetchOne(db)
        }
    }
}
