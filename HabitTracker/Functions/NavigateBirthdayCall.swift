//
//  NavigateBirthdayCall.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 07/12/24.
//

import SwiftUI
import GRDB

extension DatabaseManager {
    func addBirthdayCallIfNeeded(for date: Date, db: Database) throws {
        let userCalendar = Calendar.current
        let userTimeZone = TimeZone.current
        var calendarWithTimeZone = Calendar(identifier: userCalendar.identifier)
        calendarWithTimeZone.timeZone = userTimeZone

        let today = calendarWithTimeZone.startOfDay(for: date)

        // Fetch friends with a birthday that matches the given date
        let monthDayToday = calendarWithTimeZone.dateComponents([.month, .day], from: today)
        let friendsWithBirthdays = try Friend
            .fetchAll(db)
            .filter { friend in
                guard let birthday = friend.birthday else { return false }
                let birthdayMonthDay = calendarWithTimeZone.dateComponents([.month, .day], from: birthday)
                return birthdayMonthDay == monthDayToday
            }

        for friend in friendsWithBirthdays {
            // Check if a birthday call is already scheduled for this friend on this date
            let existingCall = try Event
                .filter(
                    Column("categoryID") == 1 &&
                    Column("eventName") == "\(friend.name)'s Birthday" &&
                    Column("eventDate") == today &&
                    Column("allDay") == true
                )
                .fetchOne(db)

            if existingCall == nil {
                // Schedule an all-day call event for the friend's birthday
                let birthdayCallEvent = Event(
                    id: nil,
                    eventName: "\(friend.name)'s Birthday",
                    eventDate: today,
                    eventHour: 0,
                    eventMinute: 0,
                    eventLength: 30,
                    allDay: true,
                    categoryID: 1,
                    repeatFrequency: 0
                )
                try birthdayCallEvent.insert(db)
                print("Scheduled an all-day birthday call for \(friend.name) on \(today).")
            } else {
                print("Birthday call for \(friend.name) on \(today) already exists. Skipping.")
            }
        }
    }
}
