//
//  ContentView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 29/10/24.
//
//
//  ContentView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 29/10/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView {
            CalendarView(initialDate: Date()) // Pass today's date as the initial date
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            FriendsListView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Friends List")
                }
        }
    }
}
