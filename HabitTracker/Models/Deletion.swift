//
//  Deletion.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 27/11/24.
//

import Foundation
import GRDB

struct Deletion: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var eventID: Int64
    var eventName: String
    var dateDeleted: Date
    var hourDeleted: Int
    var deleteFuture: Bool
}
