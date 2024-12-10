//
//  CalendarView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 29/10/24.
//

import SwiftUI
import GRDB
import Combine

struct CalendarView: View {
    @State private var events: [Event] = []
    @State private var activeHour: Int? = nil
    @State private var currentDate = Date()
    @State private var selectedEvent: Event?
    @State private var navigateToWeeklyView = false
    @State private var navigateToMonthlyView = false
    @State private var clearTextField: Bool = false

    @StateObject private var databaseObserver: DatabaseObserver
    
    @State private var magnificationScale: CGFloat = 1.0

    private var isToday: Bool {
        Calendar.current.isDateInToday(currentDate)
    }

    init(initialDate: Date) {
           _currentDate = State(initialValue: initialDate)
           _databaseObserver = StateObject(wrappedValue: DatabaseObserver(dbQueue: DatabaseManager.shared.dbQueue))
       }

    var body: some View {
        if navigateToMonthlyView {
            MonthlyView(date: currentDate) // Navigate to MonthlyView and pass currentDate
        } else {
            VStack {
                if navigateToWeeklyView {
                    WeeklyView(date: currentDate)
                } else {
                    VStack {
                        dateNavigationHeader
                        
                        // Display allDay events first
                        let allDayEvents = events.filter { $0.allDay }
                        if !allDayEvents.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(allDayEvents, id: \.id) { event in
                                    AllDayRow(
                                        event: event,
                                        onEventTapped: { tappedEvent in
                                            selectedEvent = tappedEvent
                                        }
                                    )
                                }
                                Divider()
                                    .padding(.vertical, 5)
                            }
                        }
                        
                        // Scrollable hourly events with overlaid EventRows
                        eventScrollView
                    }
                    
                    .onAppear {
                        fetchAndDisplayEvents(for: currentDate)
                    }
                    .onChange(of: currentDate) { _, newDate in
                        fetchAndDisplayEvents(for: newDate)
                    }
                    .sheet(item: $selectedEvent) { event in
                        EventDetailView(
                            event: event,
                            onSave: {
                                databaseObserver.refreshEvents(for: currentDate) // Refresh events for the current date
                                fetchAndDisplayEvents(for: currentDate)
                                selectedEvent = nil
                            },
                            onDelete: { deleteFuture, eventToDelete in
                                        if deleteFuture {
                                            deleteAllFutureEvents(
                                                eventName: eventToDelete.eventName,
                                                date: eventToDelete.eventDate,
                                                hour: eventToDelete.eventHour
                                            )
                                            selectedEvent = nil
                                        } else {
                                            deleteEvent(eventToDelete)
                                            selectedEvent = nil
                                        }
                                        fetchAndDisplayEvents(for: currentDate)
                                    }
                                )
                            }

                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                magnificationScale = value
                            }
                            .onEnded { value in
                                if value < 0.8 { // Detect zoom-out gesture
                                    navigateToWeeklyView = true
                                }
                                magnificationScale = 1.0 // Reset scale
                            }
                    )
                }
            }
            .animation(.easeInOut, value: navigateToWeeklyView)
        }
    }

    private var dateNavigationHeader: some View {
        HStack {
            Button(action: { changeDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title)
                    .padding(.horizontal)
            }
            VStack(spacing: 4) {
                // Day of the week (tap to open date picker)
                Text(formattedDayOfWeek)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isToday ? .blue : .primary) // Blue if today
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            navigateToMonthlyView = true
                        }
                    }
                // Date with suffix
                Text(formattedDateWithSuffix)
                    .font(.headline)
                    .foregroundColor(isToday ? .blue : .secondary) // Blue if today
            }
            Button(action: { changeDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title)
                    .padding(.horizontal)
            }
        }
        .padding()
    }


    private var eventScrollView: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Hour rows for the calendar structure
                VStack(spacing: 0) {
                    Spacer().frame(height: 10)
                    ForEach(0..<24, id: \.self) { hour in
                        HourRow(
                            hour: hour,
                            isLastHour: hour == 23,
                            activeHour: $activeHour,
                            clearTextField: $clearTextField,
                            onSaveEvent: { eventName in
                                                    addEventNoDB(at: hour, minute: 0, eventName: eventName)
                                                    clearTextField = true // Trigger clearing text fields
                                                }
                        )
                    }
                    Spacer().frame(height: 10)
                }

                // Overlay EventRows for hourly events (exclude all-day events)
                ForEach(events.filter { !$0.allDay }, id: \.id) { event in
                    EventRow(
                        event: event,
                        onEventTapped: { tappedEvent in
                            selectedEvent = tappedEvent
                        },
                        onMoveEvent: { movedEvent, newHour, newMinute in
                            moveEvent(movedEvent, toHour: newHour, toMinute: newMinute)
                        }
                    )
                    .frame(height: CGFloat(event.eventLength))
                    .offset(y: calculateEventRowOffset(for: event))
                }
            }
            .padding(.horizontal)
            // Pie Chart for the day's events
                                if !events.isEmpty {
                                    
                                    Divider()
                                    Spacer().frame(height: 40)
                                    
                                    PieChartView(events: events)
                                        .frame(height: 300)
                                    Spacer().frame(height: 20)
                                }
        }
    }


    private func calculateEventRowOffset(for event: Event) -> CGFloat {
        let rowHeight: CGFloat = 60
        return CGFloat(event.eventHour) * rowHeight + CGFloat(event.eventMinute)
    }

    private func fetchAndDisplayEvents(for date: Date) {
        do {
            try DatabaseManager.shared.dbQueue.write { db in
                // Perform all database operations within this closure to avoid "methods not reentrant" error
                try DatabaseManager.shared.addRepeatingEventsIfNeeded(for: date, db: db)
                try DatabaseManager.shared.addCallEventsIfNeeded(for: date, db: db)
                try DatabaseManager.shared.addBirthdayCallIfNeeded(for: date, db: db)
                events = try DatabaseManager.shared.fetchEvents(for: date, db: db)
            }
        } catch {
            print("Error fetching events: \(error)")
        }
    }



    private func addEvent(at hour: Int, minute: Int, eventName: String, db: Database) {
        guard !eventName.isEmpty else { return }

        do {
            try DatabaseManager.shared.addEvent(
                eventName: eventName,
                eventDate: currentDate,
                eventHour: hour,
                eventMinute: minute,
                allDay: false,  // HourRow events default to `false`
                eventLength: 60,
                categoryID: 2,
                done: false,
                repeatFrequency: 0,
                db: db
            )
            fetchAndDisplayEvents(for: currentDate)
        } catch {
            print("Error adding event: \(error)")
        }
    }

    private func addEventNoDB(at hour: Int, minute: Int, eventName: String) {
        guard !eventName.isEmpty else { return }

        do {
            try DatabaseManager.shared.dbQueue.write { db in
                try DatabaseManager.shared.addEvent(
                    eventName: eventName,
                    eventDate: currentDate,
                    eventHour: hour,
                    eventMinute: minute,
                    allDay: false,  // HourRow events default to `false`
                    eventLength: 60,
                    categoryID: 2,
                    done: false,
                    repeatFrequency: 0,
                    db: db
                )
            }
            fetchAndDisplayEvents(for: currentDate) // Refresh events after insertion
        } catch {
            print("Error adding event: \(error)")
        }
    }

    
    private func deleteEvent(_ event: Event) {
        do {
            try DatabaseManager.shared.deleteEvent(eventID: event.id ?? 0, eventName: event.eventName, date: currentDate, hour: event.eventHour, deleteFuture: false)
            fetchAndDisplayEvents(for: currentDate)
        } catch {
            print("Error deleting event: \(error)")
        }
    }
    
    private func deleteAllFutureEvents(eventName: String, date: Date, hour: Int) {
        do {
            try DatabaseManager.shared.deleteAllFutureEvents(
                eventName: eventName,
                eventDate: date,
                eventHour: hour
            )
        } catch {
            print("Error deleting event: \(error)")
        }
    }

    private func moveEvent(_ event: Event, toHour newHour: Int, toMinute newMinute: Int) {
        do {
            var updatedEvent = event
            updatedEvent.eventHour = newHour
            updatedEvent.eventMinute = newMinute
            try DatabaseManager.shared.updateEvent(event: updatedEvent)
            fetchAndDisplayEvents(for: currentDate)
        } catch {
            print("Error moving event: \(error)")
        }
    }

    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) {
            currentDate = newDate
        }
    }

    private var formattedDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentDate).uppercased()
    }

    private var formattedDateWithSuffix: String {
        let day = Calendar.current.component(.day, from: currentDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return "\(day.ordinalSuffix()) \(formatter.string(from: currentDate))"
    }
}


//    // Set up a database observation for the events table
//    private func setupDatabaseObservation() { // use state object instead
//        guard let dbQueue = DatabaseManager.shared.dbQueue else {
//            print("Database queue is unavailable.")
//            return
//        }
//
//        // Observe changes to the `events` table
//        observationToken = try? DatabaseRegionObservation(tracking: Table("events"))
//            .publisher(in: dbQueue)
//            .receive(on: DispatchQueue.main) // Ensure updates are handled on the main thread
//            .sink(
//                receiveCompletion: { completion in
//                    if case let .failure(error) = completion {
//                        print("Database observation error: \(error)")
//                    }
//                },
//                receiveValue: { _ in
//                    // Refetch data for the current date
//                    fetchAndDisplayEvents(for: currentDate)
//                }
//            )
//    }
    
//    private func setupDatabaseObservation() {
//        guard let dbQueue = DatabaseManager.shared.dbQueue else {
//            print("Database queue is unavailable.")
//            return
//        }
//
//        // Observe changes to the `events` table
//        observationToken = try? DatabaseRegionObservation(tracking: Table("events"))
//            .publisher(in: dbQueue)
//            .receive(on: DispatchQueue.main) // Ensure updates are handled on the main thread
//            .sink(
//                receiveCompletion: { completion in
//                    if case let .failure(error) = completion {
//                        print("Database observation error: \(error)")
//                    }
//                },
//                receiveValue: { [weak self] _ in // weak can't be used for struct
//                    DispatchQueue.main.async {
//                        // Refetch data for the current date
//                        self?.fetchAndDisplayEvents(for: self?.currentDate ?? Date())
//                    }
//                }
//            )
//    }


