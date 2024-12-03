//
//  Event.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 05/11/24.
//

import Foundation
import GRDB

struct Event: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var eventName: String
    var eventDate: Date
    var eventHour: Int
    var eventMinute: Int
    var eventLength: Int = 60
    var allDay: Bool = false
    var categoryID: Int64 = 2
    var done: Bool = false
    var repeatFrequency: Int = 0
}
