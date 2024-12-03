//
//  FriendsListView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 29/10/24.
//

import SwiftUI
import GRDB

struct FriendsListView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var friendsObserver: FriendsDatabaseObserver = FriendsDatabaseObserver(dbQueue: DatabaseManager.shared.dbQueue)

    var body: some View {
        NavigationView {
            List {
                ForEach(friendsObserver.friends, id: \.id) { friend in
                    NavigationLink(destination: EditFriendView(friend: friend, dbQueue: DatabaseManager.shared.dbQueue)) {
                        HStack {
                            Text(friend.name)
                                .font(.headline)
                        }
                    }
                }
                .onDelete(perform: deleteFriend)
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddFriendView(dbQueue: DatabaseManager.shared.dbQueue)) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func deleteFriend(at offsets: IndexSet) {
            for index in offsets {
                let friend = friendsObserver.friends[index]
                do {
                    _ = try DatabaseManager.shared.dbQueue.write { db in
                        try Friend.deleteOne(db, key: friend.id)
                    }
                } catch {
                    print("Error deleting friend: \(error)")
                }
            }
        }
    }

