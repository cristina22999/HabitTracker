//
//  EventCategory.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 05/11/24.
//

import Foundation
import GRDB
import SwiftUI

struct EventCategory: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?  // Primary key from the database
    var name: String
    var colorHex: String
}
