//
//  MonthlyView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 23/11/24.
//

import SwiftUI

struct MonthlyView: View {
    @State private var currentMonthStartDate: Date
    @State private var daysInMonth: [Date] = []
    @State private var eventsByDate: [Date: [Event]] = [:]
    @State private var navigateToDayView = false
    @State private var selectedDate: Date?

    @StateObject private var databaseObserver: DatabaseObserver

    init(date: Date) {
        _databaseObserver = StateObject(wrappedValue: DatabaseObserver(dbQueue: DatabaseManager.shared.dbQueue))
        _currentMonthStartDate = State(initialValue: MonthlyView.startOfMonth(for: date))
        _daysInMonth = State(initialValue: MonthlyView.generateDaysInMonth(for: date))
    }

    var body: some View {
        ScrollView {
            VStack {
                if let selectedDate = selectedDate, navigateToDayView {
                    CalendarView(initialDate: selectedDate)
                } else {
                    VStack {
                        monthNavigationHeader

                        dayHeaders

                        monthGrid
                            .padding(.top, 10)

                        if !allEvents.isEmpty {
                            Divider()
                            Spacer().frame(height: 40)
                            PieChartView(events: allEvents)
                                .frame(height: 300)
                            Spacer().frame(height: 20)
                        }
                    }
                    .onAppear {
                        fetchEventsForCurrentMonth()
                    }
                    .onChange(of: currentMonthStartDate) { newValue in
                        daysInMonth = MonthlyView.generateDaysInMonth(for: newValue)
                        fetchEventsForCurrentMonth()
                    }
                }
            }
        }
        .animation(.easeInOut, value: navigateToDayView)
    }

    private var allEvents: [Event] {
        eventsByDate.flatMap { $0.value }
    }

    private var monthNavigationHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .padding(.horizontal)
                }
                VStack(spacing: 4) {
                    Text(currentMonthFormatted)
                        .font(.title)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                    Text(currentYearFormatted)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
    }

    private var dayHeaders: some View {
        HStack(spacing: 5) {
            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                Text(day)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let calendar = Calendar.current
        let firstWeekdayOffset = calendar.component(.weekday, from: daysInMonth.first ?? Date()) - 2
        let paddedDays = Array(repeating: nil as Date?, count: max(0, firstWeekdayOffset)) + daysInMonth

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 10) {
            ForEach(paddedDays, id: \.self) { date in
                if let date = date {
                    dayColumn(for: date)
                } else {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 5)
    }

    private func dayColumn(for date: Date) -> some View {
        VStack {
            ZStack(alignment: .top) {
                // Background for the day
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 40, height: 72)
                    .cornerRadius(5)

                // Events for the day
                if let events = eventsByDate[date] {
                    ForEach(events) { event in
                        eventLine(for: event)
                    }
                }
            }
            .overlay(
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .padding(4),
                alignment: .topLeading
            )
            .padding(2) // Add internal padding
            .background(
                Calendar.current.isDateInToday(date) ? Color.blue : Color.clear // Background for the border
            )
            .cornerRadius(7) // Ensure the border background is rounded
            .onTapGesture {
                selectedDate = date
                navigateToDayView = true
            }
        }
    }

    private func eventLine(for event: Event) -> some View {
        let startY = CGFloat(event.eventHour * 3) + CGFloat(event.eventMinute / 20)
        let length = CGFloat(event.eventLength) / 20 // 3 pixels per hour (72 pixels total for 24 hours)

        return Rectangle()
            .fill(Color(hex: fetchCategoryColor(for: event)))
            .frame(width: 40, height: length)
            .cornerRadius(3)
            .offset(y: startY)
    }

    // Helper to fetch category color
    private func fetchCategoryColor(for event: Event) -> String {
        do {
            return try DatabaseManager.shared.fetchCategoryColor(for: event.categoryID)
        } catch {
            print("Error fetching category color: \(error)")
            return "#0000FF" // Default color
        }
    }

    private func fetchEventsForCurrentMonth() {
        do {
            try DatabaseManager.shared.dbQueue.read { db in
                eventsByDate.removeAll()
                for date in daysInMonth {
                    do {
                        let events = try DatabaseManager.shared.fetchEvents(for: date, db: db)
                        eventsByDate[date] = events
                    } catch {
                        print("Error fetching events for date \(date): \(error)")
                    }
                }
            }
        } catch {
            print("Error fetching events for the current month: \(error)")
        }
    }


    private func changeMonth(by months: Int) {
        if let newMonthStartDate = Calendar.current.date(byAdding: .month, value: months, to: currentMonthStartDate) {
            currentMonthStartDate = MonthlyView.startOfMonth(for: newMonthStartDate)
        }
    }

    private var currentMonthFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentMonthStartDate)
    }

    private var currentYearFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentMonthStartDate)
    }

    static func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    static func generateDaysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        let startOfMonth = startOfMonth(for: date)

        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
}
