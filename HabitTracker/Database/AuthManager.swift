//
//  AuthManager.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 30/10/24.
//

import Foundation

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
        }
    }
    
    init() {
        // Check UserDefaults to see if the user has already logged in
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    }
    
    func logIn() {
        isAuthenticated = true
    }
    
    func logOut() {
        isAuthenticated = false
    }
}
