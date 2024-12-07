//
//  CallScheduler.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 19/11/24.
//

import Foundation
import GRDB

class CallScheduler {
    private let db: Database

        init(db: Database) {
            self.db = db
        }
    let dbManager = DatabaseManager.shared // Access the shared DatabaseManager instance

    /// Schedule the first 4 calls for a given friend or multiple friends.
    func scheduleCalls(for friends: [Friend], db: Database) -> [Int64: [Date]] {
        var friendSchedule: [Int64: [Date]] = [:]
        let today = Calendar.current.startOfDay(for: Date()) // Start of today

        for friend in friends {
            guard let id = friend.id else { continue }

            // Skip handling if the friend only wants birthday calls, handled separately
                    if friend.onBirthday { continue }

            // Schedule based on frequency
            friendSchedule[id] = scheduleNextCalls(for: friend, from: today, db: db)
        }

        return friendSchedule
    }

    /// Schedule the first 4 calls for a specific friend.
    func scheduleNextCalls(for friend: Friend, from startDate: Date, db: Database) -> [Date] {
        var scheduledDates: [Date] = []
        let frequency = friend.frequency
        var nextCallDate = Calendar.current.date(byAdding: .day, value: frequency, to: startDate) ?? startDate

        for _ in 1...4 {
            if let availableDate = findAvailableDate(startingFrom: nextCallDate, frequency: frequency, db: db) {
                addEvent(friendID: friend.id!, date: availableDate, name: "Call \(friend.name)", allDay: true, categoryID: 1, repeatFrequency: frequency, db: db)
                scheduledDates.append(availableDate)
                nextCallDate = Calendar.current.date(byAdding: .day, value: frequency, to: availableDate) ?? availableDate
            } else {
                // Fallback: Add the event even if no available date is found
                addEvent(friendID: friend.id!, date: nextCallDate, name: "Call \(friend.name)", allDay: true, categoryID: 1, repeatFrequency: frequency, db: db)
                scheduledDates.append(nextCallDate)
                nextCallDate = Calendar.current.date(byAdding: .day, value: frequency, to: nextCallDate) ?? nextCallDate
            }
        }

        return scheduledDates
    }

    private func findAvailableDate(startingFrom targetDate: Date, frequency: Int, db: Database) -> Date? {
        let calendar = Calendar.current
        var offsets: [Int] = [0] // Start with 0 (target date)

        // Generate offsets in the order: [0, -1, 1, -2, -3, -4, ...]
        for i in 1...frequency {
            offsets.append(-i)
            offsets.append(i)
        }

        for offset in offsets {
            let candidateDate = calendar.date(byAdding: .day, value: offset, to: targetDate) ?? targetDate
            if isDateAvailable(candidateDate, db: db) {
                return candidateDate
            }
        }

        return nil // No available date found
    }

    private func isDateAvailable(_ date: Date, db: Database) -> Bool {
        do {
            let events = try dbManager.fetchEvents(for: date, db: db)
            return !events.contains { $0.allDay } // Date is available if no allDay event exists
        } catch {
            print("Error checking availability for \(date): \(error)")
            return false
        }
    }

    private func addEvent(friendID: Int64, date: Date, name: String, allDay: Bool, categoryID: Int64, repeatFrequency: Int, db: Database) {
        do {
            try dbManager.addEvent(
                eventName: name,
                eventDate: date,
                eventHour: 0, // All-day event
                eventMinute: 0, // All-day event
                allDay: allDay,
                eventLength: 30, // Default length (30 mins)
                categoryID: categoryID,
                done: false,
                repeatFrequency: repeatFrequency,
                db: db
            )
            print("Scheduled event for \(name) on \(date)")
        } catch {
            print("Error scheduling event: \(error)")
        }
    }
}
