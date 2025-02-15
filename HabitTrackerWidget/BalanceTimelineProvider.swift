//
//  BalanceTimelineProvider.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 15/02/25.
//

import WidgetKit
import GRDB
import GRDBSQLite

struct BalanceTimelineEntry: TimelineEntry {
    let date: Date
    let dailyEvents: [Event]
    let weeklyEvents: [Event]
    let monthlyEvents: [Event]
}

class BalanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceTimelineEntry {
        BalanceTimelineEntry(
            date: Date(),
            dailyEvents: [],
            weeklyEvents: [],
            monthlyEvents: []
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BalanceTimelineEntry) -> Void) {
        let entry = BalanceTimelineEntry(
            date: Date(),
            dailyEvents: fetchDailyEvents(),
            weeklyEvents: fetchWeeklyEvents(),
            monthlyEvents: fetchMonthlyEvents()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceTimelineEntry>) -> Void) {
        let currentDate = Date()
        let entry = BalanceTimelineEntry(
            date: currentDate,
            dailyEvents: fetchDailyEvents(),
            weeklyEvents: fetchWeeklyEvents(),
            monthlyEvents: fetchMonthlyEvents()
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    // Helper functions to fetch events
    private func fetchDailyEvents() -> [Event] {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                let today = Calendar.current.startOfDay(for: Date())
                return try DatabaseManager.shared.fetchEvents(for: today, db: db)
            }
        } catch {
            print("Error fetching daily events: \(error)")
            return []
        }
    }
    
    private func fetchWeeklyEvents() -> [Event] {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
                
                var events: [Event] = []
                for dayOffset in 0..<7 {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        let dayEvents = try DatabaseManager.shared.fetchEvents(for: date, db: db)
                        events.append(contentsOf: dayEvents)
                    }
                }
                return events
            }
        } catch {
            print("Error fetching weekly events: \(error)")
            return []
        }
    }
    
    private func fetchMonthlyEvents() -> [Event] {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                
                return try Event
                    .filter(Column("eventDate") >= monthStart && Column("eventDate") < nextMonth)
                    .fetchAll(db)
            }
        } catch {
            print("Error fetching monthly events: \(error)")
            return []
        }
    }
}
