//
//  StateObject.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 12/11/24.
//

import GRDB
import Combine
import SwiftUI

class DatabaseObserver: ObservableObject {
    @Published var events: [Event] = []
    private let dbQueue: DatabaseQueue
    private var eventObservationToken: AnyCancellable?
    private var categoryObservationToken: AnyCancellable?

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
        setupEventObservation()       // Start observing the `events` table
        setupCategoryObservation()    // Start observing the `eventCategory` table
        fetchEvents(for: Date())      // Fetch initial events for today
    }
    
    private func setupEventObservation() {
        eventObservationToken = DatabaseRegionObservation(tracking: Table("events"))
            .publisher(in: dbQueue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Database observation error: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.fetchEvents(for: Date())
                }
            )
    }
    
    private func setupCategoryObservation() {
        categoryObservationToken = DatabaseRegionObservation(tracking: Table("eventCategory"))
            .publisher(in: dbQueue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Category observation error: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.refreshCategoryData()
                }
            )
    }
    
    private func refreshCategoryData() {
        fetchAllEvents()
    }

    func fetchEvents(for date: Date) {
        do {
            let fetchedEvents = try dbQueue.read { db in
                try Event
                    .filter(Column("eventDate") == date)
                    .order(Column("eventHour").asc, Column("eventMinute").asc)
                    .fetchAll(db)
            }
            DispatchQueue.main.async { [weak self] in
                self?.events = fetchedEvents
            }
        } catch {
            print("Error fetching events: \(error)")
        }
    }
    
    func fetchAllEvents() {
        do {
            let fetchedEvents = try dbQueue.read { db in
                try Event
                    .order(Column("eventDate").asc, Column("eventHour").asc, Column("eventMinute").asc)
                    .fetchAll(db)
            }
            DispatchQueue.main.async { [weak self] in
                self?.events = fetchedEvents
            }
        } catch {
            print("Error fetching all events: \(error)")
        }
    }
    
    func refreshEvents(for date: Date) {
        fetchEvents(for: date)
    }
}
