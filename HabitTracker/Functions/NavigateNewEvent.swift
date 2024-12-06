//
//  NavigateNewEvent.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 27/11/24.
//

import SwiftUI
import Foundation
import GRDB

extension DatabaseManager {
    func addRepeatingEventsIfNeeded(for date: Date, db: Database) throws {
        print("Date: \(date)")
        
        // Fetch repeating events
        let repeatingEvents = try fetchRepeatingEvents(for: date, db: db)
        
        // Exclude deleted events
        let filteredEvents = try excludeDeletedEvents(from: repeatingEvents, for: date, db: db)
        
        // Check if the date is a multiple of the frequency
        let multiplesOfEvent = try isDateMultipleOfFrequency(filteredEvents, for: date)
        
        if !filteredEvents.isEmpty {
            // Schedule the matching events
            try scheduleMatchingEvents(filteredEvents, for: date, db: db)
        }
    }
    
    
    // Fetch repeating events from the database
    private func fetchRepeatingEvents(for date: Date, db: Database) throws -> [Event] {
        // Fetch all repeating events
        let allEvents = try Event
            .filter(Column("repeatFrequency") > 0 &&
                    Column("categoryID") != 1)
            .fetchAll(db)
        
        // Use a Set to ensure unique event names
        var uniqueEventNames: Set<String> = []
        var filteredEvents: [Event] = []
        
        for event in allEvents {
            if !uniqueEventNames.contains(event.eventName) {
                uniqueEventNames.insert(event.eventName)
                filteredEvents.append(event)
            } else {
                print("Skipping duplicate event with name: \(event.eventName)")
            }
        }
        print("\(filteredEvents.count) filtered events: \(filteredEvents)")
        
        return filteredEvents
    }
        
    // Exclude events that are marked in the deletion table
    private func excludeDeletedEvents(from events: [Event], for date: Date, db: Database) throws -> [Event] {
        let calendar = Calendar.current
        let targetDateFull = calendar.startOfDay(for: date)
        let targetDate = calendar.date(byAdding: .day, value: 1, to: targetDateFull)!
// Normalize the date to the start of the day, add 1
        
        // Debugging: Print the database path and table contents
        // print("Database path: \(dbQueue.path ?? "In-memory database")")
        
        // Check if the deletion table exists
        let tableExists = try db.tableExists("deletion")
        print("Does deletion table exist? \(tableExists)")
        
        if tableExists {
            let deletionsRows = try Row.fetchAll(db, sql: "SELECT * FROM deletion")
            print("Deletion table rows: \(deletionsRows)")
            
            let eventsRows = try Row.fetchAll(db, sql: "SELECT * FROM event")
            print("Event table rows: \(eventsRows)")
            
            print("All rows in the deletion table:")
            for row in deletionsRows {
                print("eventID: \(row["eventID"] ?? "nil"), eventName: \(row["eventName"] ?? "nil"), dateDeleted: \(row["dateDeleted"] ?? "nil")")
            }
        }
        
        // Filter the events to include only those NOT in the deletion table
        let survivingEvents = try events.filter { event in
            // Check if event is marked as deleted by comparing the first 10 characters of `dateDeleted`
            let deletionExists = try Row.fetchOne(
                db,
                sql: """
            SELECT 1 FROM deletion
            WHERE eventName = ? AND SUBSTR(dateDeleted, 1, 10) = SUBSTR(?, 1, 10)
            """,
                arguments: [event.eventName, targetDate]
            ) != nil
            
            if deletionExists {
                print("Excluding \(event.eventName) because it is marked as deleted for \(targetDate).")
            }
            return !deletionExists // Return only events that are not marked as deleted
        }
        
        print("Events that survived deletion: \(survivingEvents)")
        return survivingEvents
    }
    
    
    
    private func isDateMultipleOfFrequency(_ events: [Event], for date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Use a Set to track unique combinations of eventName, repeatFrequency, and eventHour
        var uniqueEventKeys: Set<String> = []
        var uniqueEvents: [Event] = []
        
        for event in events {
            // Create a unique key for each event
            let uniqueKey = "\(event.eventName)-\(event.repeatFrequency)-\(event.eventHour)"
            
            // Add only if the key is not already in the set
            if !uniqueEventKeys.contains(uniqueKey) {
                uniqueEventKeys.insert(uniqueKey)
                uniqueEvents.append(event)
            } else {
                print("Skipping duplicate event: \(event.eventName) with frequency \(event.repeatFrequency) and hour \(event.eventHour).")
            }
        }
        
        // Check for multiples of frequency
        for event in uniqueEvents {
            let startDate = calendar.startOfDay(for: event.eventDate)
            let differenceInDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? -1
            
            if differenceInDays >= 0 && differenceInDays % event.repeatFrequency == 0 {
                print("Date \(date) is a multiple of \(event.repeatFrequency) for event \(event.eventName).")
                return true
            }
        }
        
        print("Date \(date) is not a multiple of the frequency for any event.")
        return false
    }
    
    
    private func scheduleMatchingEvents(_ events: [Event], for date: Date, db: Database) throws {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        for event in events {
            let startDate = calendar.startOfDay(for: event.eventDate)
            let differenceInDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? -1
            
            // Skip scheduling if the target date is earlier than the event's start date
            if differenceInDays < 0 {
                print("Skipping \(event.eventName) because the target date \(targetDate) is earlier than the event's start date \(startDate).")
                continue
            }
            
            // Check if the event is in the deletion table for the input date
            let isDeleted = try Table("deletion")
                .filter(Column("eventName") == event.eventName &&
                        Column("dateDeleted") == targetDate)
                .fetchCount(db) > 0
            
            if isDeleted {
                print("Skipping \(event.eventName) because it is marked as deleted for \(targetDate).")
                continue
            }
            
            // Check if the event already exists in the events table
            let existingEventCount = try Event
                .filter(Column("eventDate") == targetDate &&
                        Column("eventName") == event.eventName &&
                        Column("eventHour") == event.eventHour)
                .fetchCount(db)
            
            if existingEventCount > 0 {
                print("Skipping \(event.eventName) because it already exists in events.")
                continue
            }
            
            // Insert the new event
            let newEvent = Event(
                id: nil,
                eventName: event.eventName,
                eventDate: targetDate,
                eventHour: event.eventHour,
                eventMinute: event.eventMinute,
                eventLength: event.eventLength,
                allDay: event.allDay,
                categoryID: event.categoryID,
                repeatFrequency: event.repeatFrequency
            )
            try newEvent.insert(db)
            
            print("Scheduled event: \(event.eventName) on \(targetDate) at hour \(event.eventHour).")
        }
    }

}
