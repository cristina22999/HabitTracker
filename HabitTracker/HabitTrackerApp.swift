//
//  HabitTrackerApp.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 29/10/24.
//

import SwiftUI

@main
struct HabitTrackerApp: App {
    // Initialize the AuthManager
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager) // Inject AuthManager into the environment
        }
    }
}
