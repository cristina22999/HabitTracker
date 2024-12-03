//
//  CategoryObserver.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 19/11/24.
//

import GRDB
import Combine
import SwiftUI

class CategoriesDatabaseObserver: ObservableObject {
    @Published var categories: [EventCategory] = []
    private var observation: AnyCancellable?
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
        setupObservation()
        fetchCategories() // Initial fetch
    }

    private func setupObservation() {
        observation = DatabaseRegionObservation(tracking: Table("eventCategory"))
            .publisher(in: dbQueue)
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Database observation error: \(error)")
                }
            }, receiveValue: { [weak self] _ in
                self?.fetchCategories() // Fetch categories whenever the table changes
            })
    }

    func fetchCategories() {
        do {
            let fetchedCategories = try dbQueue.read { db in
                try EventCategory.order(Column("name").asc).fetchAll(db)
            }
            DispatchQueue.main.async { [weak self] in
                self?.categories = fetchedCategories
            }
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
}
