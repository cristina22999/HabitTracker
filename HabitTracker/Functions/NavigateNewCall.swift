//
//  NavigateNewCall.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 30/11/24.
//

import SwiftUI
import GRDB

extension DatabaseManager {
    func addCallEventsIfNeeded(for date: Date, db: Database) throws {
        // Fetch all repeating call events
        let callEvents = try Event
            .filter(Column("categoryID") == 1 && Column("repeatFrequency") > 0)
            .fetchAll(db)

        let calendar = Calendar.current

        for callEvent in callEvents {
            guard let personName = extractPersonName(from: callEvent.eventName) else { continue }

            let callFrequency = callEvent.repeatFrequency
            let today = calendar.startOfDay(for: date)

            // Check for scheduled calls in the future
            let nextCallCheckDate = calendar.date(byAdding: .day, value: callFrequency * 4, to: today)!
            let futureCallsCount = try Event
                .filter(
                    Column("categoryID") == 1 &&
                    Column("eventName").like("Call \(personName)%") &&
                    Column("eventDate") >= today &&
                    Column("eventDate") <= nextCallCheckDate
                )
                .fetchCount(db)

            if futureCallsCount < 4 {
                // Fetch the last call date for this person
                let lastCallDate = try Event
                    .filter(Column("categoryID") == 1 && Column("eventName").like("Call \(personName)%"))
                    .order(Column("eventDate").desc)
                    .fetchOne(db)?.eventDate ?? today

                // Use CallScheduler to schedule the next 4 calls
                let scheduler = CallScheduler(db: db)
                let friend = try fetchFriend(named: personName, db: db)
                if let friend = friend {
                    let scheduledDates = scheduler.scheduleNextCalls(for: friend, from: lastCallDate, db: db)
                    print("Scheduled calls for \(personName) on the following dates: \(scheduledDates)")
                } else {
                    print("Error: Friend named \(personName) not found in the database.")
                }
            }
        }
    }


    private func extractPersonName(from eventName: String) -> String? {
        // Assuming event names follow the format "Call <Name>"
        guard eventName.hasPrefix("Call ") else { return nil }
        return String(eventName.dropFirst("Call ".count))
    }

    private func fetchFriend(named name: String, db: Database) throws -> Friend? {
        return try Friend
            .filter(Column("name") == name)
            .fetchOne(db)
    }
}
