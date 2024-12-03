//
//  FriendObserver.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 19/11/24.
//

import GRDB
import Combine
import SwiftUI

class FriendsDatabaseObserver: ObservableObject {
    @Published var friends: [Friend] = []
    private var observation: AnyCancellable?
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
        setupObservation()
        fetchFriends() // Initial fetch
    }

    private func setupObservation() {
        observation = DatabaseRegionObservation(tracking: Table("friends"))
            .publisher(in: dbQueue)
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Database observation error: \(error)")
                }
            }, receiveValue: { [weak self] _ in
                self?.fetchFriends() // Fetch friends whenever the table changes
            })
    }

    func fetchFriends() {
        do {
            let fetchedFriends = try dbQueue.read { db in
                try Friend.order(Column("name").asc).fetchAll(db)
            }
            DispatchQueue.main.async { [weak self] in
                self?.friends = fetchedFriends
            }
        } catch {
            print("Error fetching friends: \(error)")
        }
    }
}
