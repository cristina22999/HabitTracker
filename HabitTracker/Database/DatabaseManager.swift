//
//  DatabaseManager.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 30/10/24.
//

import GRDB
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    var dbQueue: DatabaseQueue

    private init() {
        do {
            let fileManager = FileManager.default
            let folderURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = folderURL.appendingPathComponent("HabitTracker.sqlite")
            
            // Print the database path
                       print("Database path: \(dbURL.path)")
            
            dbQueue = try DatabaseQueue(path: dbURL.path)

            try resetDatabase() // Drop and recreate all tables
            try setupDatabase()
        } catch {
            fatalError("Database setup failed: \(error)")
        }
    }
    
    private func resetDatabase() throws {
        try dbQueue.write { db in
            // Disable foreign key constraints temporarily
            try db.execute(sql: "PRAGMA foreign_keys = OFF;")

            // Clear rows in dependent tables
            try db.execute(sql: "DELETE FROM event;")

            // Fetch all table names except SQLite system tables
            let tables = try Row.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")

            // Drop all tables
            for table in tables {
                if let tableName = table["name"] as? String {
                    try db.execute(sql: "DROP TABLE IF EXISTS \(tableName)")
                }
            }

            // Re-enable foreign key constraints
            try db.execute(sql: "PRAGMA foreign_keys = ON;")
        }
    }




    // MARK: - Database Setup
    private func setupDatabase() throws {
        try dbQueue.write { db in
            // Create user table
            try db.create(table: "user", ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("username", .text).unique().notNull()
                t.column("password", .text).notNull()
            }

            // Create eventCategory table
            try db.create(table: "eventCategory", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).unique().notNull()
                t.column("colorHex", .text).notNull()
            }

            // Insert default categories
            try insertDefaultCategories(db: db)

            // Create events table
            try db.create(table: "event", ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("eventName", .text).notNull()
                t.column("eventDate", .date).notNull()
                t.column("eventHour", .integer).notNull()
                t.column("eventMinute", .integer).notNull()
                t.column("allDay", .boolean).notNull()
                t.column("eventLength", .integer).notNull().defaults(to: 60)
                t.column("categoryID", .integer)
                        .notNull()
                        .defaults(to: 1)
                        .references("eventCategory", onDelete: .setDefault)
                t.column("done", .boolean).notNull()
                t.column("repeatFrequency", .integer).notNull().defaults(to: 0)
            }

            // Add missing column to event table (if necessary)
//            let columns = try db.columns(in: "event")
//            if !columns.contains(where: { $0.name == "deleted" }) {
//                try db.execute(sql: "ALTER TABLE event ADD COLUMN deleted BOOL DEFAULT FALSE")
//            }
            
            try db.create(table: "deletion", ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("eventID", .integer).notNull()
                t.column("eventName", .text).notNull()
                t.column("dateDeleted", .date).notNull()
                t.column("hourDeleted", .integer).notNull()
                t.column("deleteFuture", .boolean).notNull().defaults(to: false)
            }

            // Create friends table
            try db.create(table: "friends", ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("name", .text).notNull()
                t.column("frequency", .integer).notNull()
                t.column("birthday", .date)
                t.column("lastCall", .date)
                t.column("onBirthday", .boolean).notNull().defaults(to: false)
            }
            // Add missing column to event table (if necessary)
            let friendColumns = try db.columns(in: "friends")
            if !friendColumns.contains(where: { $0.name == "onBirthday" }) {
                try db.execute(sql: "ALTER TABLE event ADD COLUMN onBirthday BOOL DEFAULT FALSE")
            }
        }
    }

    // MARK: - Insert Default Categories
    private func insertDefaultCategories(db: Database) throws {
        let existingCount: Int = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM eventCategory") ?? 0
        if existingCount == 0 {
            let defaultCategories: [(id: Int, name: String, colorHex: String)] = [
                (1, "Call Friends", "#abc4ff"),
                (2, "Life", "#a8e6cf"),  // Light pastel peach
                (3, "Work", "#cdb4db"),  // Light pastel blue
                (4, "Personal Development", "#ffb36c")  // Light pastel green
            ]
            for category in defaultCategories {
                try db.execute(
                    sql: "INSERT INTO eventCategory (id, name, colorHex) VALUES (?, ?, ?)",
                    arguments: [category.id, category.name, category.colorHex]
                )
            }
        }
    }
    
    func fetchCategoryColor(for categoryID: Int64) throws -> String {
        return try dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT colorHex FROM eventCategory WHERE id = ?", arguments: [categoryID]) ?? "#0000FF" // Default blue color
        }
    }
    
    func fetchCategoryName(for categoryID: Int64) throws -> String {
            return try dbQueue.read { db in
                try String.fetchOne(
                    db,
                    sql: "SELECT name FROM eventCategory WHERE id = ?",
                    arguments: [categoryID]
                ) ?? "Uncategorized" // Default fallback if no category is found
            }
        }


    // MARK: - Friends Operations

    /// Adds a new friend to the database.
    func addFriend(name: String, frequency: Int, birthday: Date?) throws {
        try dbQueue.write { db in
            let friend = Friend(id: nil, name: name, frequency: frequency, birthday: birthday, lastCall: nil)
            try friend.insert(db)
        }
    }

    /// Fetches all friends from the database.
    func fetchFriends() throws -> [Friend] {
        try dbQueue.read { db in
            try Friend.fetchAll(db)
        }
    }

    /// Updates an existing friend.
    func updateFriend(friend: Friend) throws {
        try dbQueue.write { db in
            try friend.update(db)
        }
    }
    
    enum FriendError: Error {
            case deletionFailed(friendID: Int64)
        }

    /// Deletes a friend by their ID.
    func deleteFriend(friendID: Int64) throws {
        try dbQueue.write { db in
            let deleted = try Friend.deleteOne(db, key: friendID)
            if !deleted {
                throw FriendError.deletionFailed(friendID: friendID)
            }
        }
    }

    // MARK: - Event Operations

    /// Adds a new event to the database.
    func addEvent(eventName: String, eventDate: Date, eventHour: Int, eventMinute: Int, allDay: Bool, eventLength: Int, categoryID: Int64, done: Bool, repeatFrequency: Int, db: Database) throws {
        print("\(eventName), \(eventDate), \(eventHour), \(eventMinute), \(allDay), \(eventLength), \(categoryID), \(done), \(repeatFrequency)")

        // Get the current max ID
        let maxID: Int64 = try Event
            .select(sql: "MAX(id)")
            .fetchOne(db) ?? 0

        // Increment to generate a new ID
        let newID = maxID + 1

        // Create the new event with the generated ID
        let event = Event(
            id: newID,
            eventName: eventName,
            eventDate: eventDate,
            eventHour: eventHour,
            eventMinute: eventMinute,
            eventLength: eventLength,
            allDay: allDay,
            categoryID: categoryID,
            done: done,
            repeatFrequency: repeatFrequency
        )
        
        print("Event Insertion Debug: \(event)")

        // Insert the new event into the database
        try event.insert(db)
    }



    /// Fetches all events for a specific date.
    func fetchEvents(for date: Date, db: Database) throws -> [Event] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try Event
            .filter(Column("eventDate") >= startOfDay && Column("eventDate") < endOfDay)
            .order(Column("eventHour").asc, Column("eventMinute").asc)
            .fetchAll(db)
    }


    /// Updates an existing event.
    func updateEvent(event: Event) throws {
        try dbQueue.write { db in
            try event.update(db)
        }
    }
    
    enum EventError: Error {
            case deletionFailed(eventID: Int64)
        }

    func addEventToDeletion(eventID: Int64, eventName: String, date: Date, hour: Int, deleteFuture: Bool, db: Database) throws {
            
            // Get the current max ID
            let maxID: Int64 = try Event
                .select(sql: "MAX(id)")
                .fetchOne(db) ?? 0

            // Increment to generate a new ID
            let newID = maxID + 1
            
            // Create a Deletion instance
            let deletion = Deletion(
                id: newID,
                eventID: eventID,
                eventName: eventName,
                dateDeleted: date,
                hourDeleted: hour,
                deleteFuture: deleteFuture
            )

            print("Deletion Insertion Debug: \(deletion)")

            // Insert the deletion into the database
            do {
                try deletion.insert(db)
                print("Added event \(eventName) to deletion for date \(date).")

                // Fetch and print the current rows in the deletion table for verification
                let currentDeletions = try Deletion.fetchAll(db)
                print("Current rows in the deletion table:")
                for row in currentDeletions {
                    print("Row: \(row)")
                }
            
        }
    }

    func deleteFromEventTable(eventID: Int64, eventName: String, db: Database) throws {
        let deleted = try Event.deleteOne(db, key: eventID)
        if !deleted {
            throw EventError.deletionFailed(eventID: eventID)
        }
        print("Deleted event \(eventName) with ID \(eventID) from the events table.")
    }
    
    /// Deletes an event by its ID.
    func deleteEvent(eventID: Int64, eventName: String, date: Date, hour: Int, deleteFuture: Bool) throws {
        try dbQueue.write { db in
            do {
                // Add event to the deletion table
                try addEventToDeletion(eventID: eventID, eventName: eventName, date: date, hour: hour, deleteFuture: deleteFuture, db: db)
                print("Successfully added event \(eventName) to deletion.")
                
                // Delete the event from the events table
                try deleteFromEventTable(eventID: eventID, eventName: eventName, db: db)
                print("Successfully deleted event \(eventName) from events table.")
            } catch {
                print("Error during deleteEvent: \(error)")
                throw error // Re-throw the error to ensure proper handling upstream
            }
        }
    }


    
    func deleteAllFutureEvents(eventName: String, startDate: Date) throws {
        try dbQueue.write { db in
            // Fetch all events with the given name and dates after or equal to the start date
            let futureEvents = try Event
                .filter(Column("eventName") == eventName && Column("eventDate") >= startDate)
                .fetchAll(db)
            
            for event in futureEvents {
                var updatedEvent = event

                // Update the event in the database
                try updatedEvent.update(db)
                print("Marked event \(updatedEvent.eventName) on \(updatedEvent.eventDate) as deleted and future-deleted.")
            }
        }
    }

    // MARK: - Event Categories

    /// Adds a new event category to the database.
    func addCategory(name: String, colorHex: String) throws {
        try dbQueue.write { db in
            let category = EventCategory(id: nil, name: name, colorHex: colorHex)
            try category.insert(db)
        }
    }

    /// Fetches all event categories from the database.
    func fetchCategories() throws -> [EventCategory] {
        try dbQueue.read { db in
            try EventCategory.fetchAll(db)
        }
    }
    
    func updateCategoryColor(for categoryID: Int64, newColor: String) {
        do {
            try dbQueue.write { db in
                // Update the color in the Category table
                try db.execute(
                    sql: "UPDATE Category SET color = ? WHERE id = ?",
                    arguments: [newColor, categoryID]
                )

                // Update the categoryColor in the Event table
                try db.execute(
                    sql: "UPDATE Event SET categoryColor = ? WHERE categoryID = ?",
                    arguments: [newColor, categoryID]
                )
            }
            print("Category color updated successfully!")
        } catch {
            print("Error updating category color: \(error)")
        }
    }

}
