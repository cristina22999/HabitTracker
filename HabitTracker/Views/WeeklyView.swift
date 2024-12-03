//
//  WeeklyView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 23/11/24.
//

import SwiftUI

struct WeeklyView: View {
    @State private var currentWeekStartDate: Date
    @State private var eventsByDate: [Date: [Event]] = [:]
    @State private var navigateToDayView = false
    @State private var navigateToMonthView = false
    @State private var selectedDate: Date

    @StateObject private var databaseObserver: DatabaseObserver

    init(date: Date) {
        let startOfWeek = WeeklyView.startOfWeek(for: date)
        _currentWeekStartDate = State(initialValue: startOfWeek)
        _selectedDate = State(initialValue: date)
        _databaseObserver = StateObject(wrappedValue: DatabaseObserver(dbQueue: DatabaseManager.shared.dbQueue))
    }

    var body: some View {
        VStack {
            if navigateToDayView {
                CalendarView(initialDate: selectedDate)
            } else if navigateToMonthView {
                MonthlyView(date: currentWeekStartDate)
            } else {
                VStack {
                    weekNavigationHeader

                    // Week Grid with days
                    weekGrid
                        .padding()
                }
                .onAppear {
                    fetchEventsForCurrentWeek()
                }
                .onChange(of: currentWeekStartDate) { _ in
                    fetchEventsForCurrentWeek()
                }
            }
        }
        .gesture(
            MagnificationGesture()
                .onEnded { value in
                    if value < 0.8 { // Detect zoom-out
                        navigateToMonthView = true
                    }
                }
        )
        .animation(.easeInOut, value: navigateToDayView)
        .animation(.easeInOut, value: navigateToMonthView)
    }

    private var weekNavigationHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: { changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .padding(.horizontal)
                }
                VStack(spacing: 4) {
                    Text("WEEK \(formattedWeekNumber)")
                        .font(.title)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                    Text(formattedWeekRange)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Button(action: { changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
    }
    
    private var formattedWeekNumber: Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfYear, from: currentWeekStartDate)
    }
    
    private var formattedWeekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM" // Use short month names like "Nov", "Dec"

        let startDay = Calendar.current.component(.day, from: currentWeekStartDate)
        let startMonth = formatter.string(from: currentWeekStartDate)

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStartDate) ?? currentWeekStartDate
        let endDay = Calendar.current.component(.day, from: endDate)
        let endMonth = formatter.string(from: endDate)

        return "\(startDay.ordinalSuffix()) \(startMonth) - \(endDay.ordinalSuffix()) \(endMonth)"
    }

    

    private var weekGrid: some View {
        let weekDays = generateWeekDays(startingFrom: currentWeekStartDate)

        return LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem()], spacing: 20) {
            ForEach(0..<8, id: \.self) { index in
                if index < weekDays.count {
                    dayColumn(for: weekDays[index])
                } else if index == 7 {
                    balanceColumn()
            } else {
                    Spacer()
                }
            }
        }
    }

    private func dayColumn(for date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)

        return VStack {
            Text(formattedDayOfWeek(for: date))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 50, height: 240)
                    .cornerRadius(5)
                    .overlay(
                        // Add a blue border if it is today
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
                    )

                // Events
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
            .onTapGesture {
                selectedDate = date
                navigateToDayView = true
            }
        }
    }
    
    private func balanceColumn() -> some View {
        let categoryTotals = calculateCategoryPercentagesForWeek()
        
        return VStack {
            Text("Balance")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color(UIColor.systemGray6))
                    .frame(width: 50, height: 240)
                    .cornerRadius(5)

                VStack(spacing: 0) {
                    ForEach(categoryTotals, id: \.categoryID) { item in
                        ZStack {
                            Rectangle()
                                .fill(Color(hex: item.color))
                                .frame(height: CGFloat(item.percentage * 240.0 / 100.0))
                            
                            // Overlay percentage text
                            Text("\(String(format: "%.1f", item.percentage))%")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .bold()
                                .padding(2)
                        }
                    }
                }
                .cornerRadius(5)
            }
        }
        .frame(width: 70)
    }

    
    private func calculateCategoryPercentagesForWeek() -> [(categoryID: Int64, color: String, percentage: Double)] {
        var categoryDurations: [Int64: Int] = [:]
        var totalDuration: Int = 0

        for (_, events) in eventsByDate {
            for event in events {
                totalDuration += event.eventLength
                categoryDurations[event.categoryID, default: 0] += event.eventLength
            }
        }

        guard totalDuration > 0 else { return [] }

        return categoryDurations.map { (categoryID, duration) in
            let percentage = Double(duration) / Double(totalDuration) * 100.0
            let color = (try? DatabaseManager.shared.fetchCategoryColor(for: categoryID)) ?? "#0000FF"
            return (categoryID: categoryID, color: color, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }
    }

    private func eventLine(for event: Event) -> some View {
        let startY = CGFloat(event.eventHour * 10) + CGFloat(event.eventMinute / 6)
        let length = CGFloat(event.eventLength) / 6 // Since 10 pixels represent 1 hour (60 minutes)

        return Rectangle()
            .fill(Color(hex: fetchCategoryColor(for: event)))
            .frame(width: 50, height: length)
            .cornerRadius(5)
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

    private func fetchEventsForCurrentWeek() {
        let weekDays = generateWeekDays(startingFrom: currentWeekStartDate)
        eventsByDate.removeAll()

        do {
            try DatabaseManager.shared.dbQueue.read { db in
                for date in weekDays {
                    do {
                        let events = try DatabaseManager.shared.fetchEvents(for: date, db: db)
                        eventsByDate[date] = events
                    } catch {
                        print("Error fetching events for date \(date): \(error)")
                    }
                }
            }
        } catch {
            print("Error fetching events for the current week: \(error)")
        }
    }


    private func changeWeek(by weeks: Int) {
        if let newWeekStartDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: currentWeekStartDate) {
            currentWeekStartDate = WeeklyView.startOfWeek(for: newWeekStartDate)
        }
    }

    private func formattedDayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func generateWeekDays(startingFrom date: Date) -> [Date] {
        var weekDays: [Date] = []
        let calendar = Calendar.current
        let startOfWeek = WeeklyView.startOfWeek(for: date)

        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                weekDays.append(day)
            }
        }

        return weekDays
    }

    // Calculate the start of the week (Monday)
    static func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 2 corresponds to Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
