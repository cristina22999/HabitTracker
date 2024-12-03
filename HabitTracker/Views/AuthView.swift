//
//  AuthView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 30/10/24.
//

import SwiftUI
import GRDB

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoginMode: Bool = true
    @State private var loginStatusMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isLoginMode ? "Login" : "Sign Up")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Username", text: $username)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
            
            Button(action: {
                if isLoginMode {
                    loginUser()
                } else {
                    createUser()
                }
            }) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                isLoginMode.toggle()
            }) {
                Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login")
                    .font(.footnote)
            }
            
            Text(loginStatusMessage)
                .foregroundColor(.red)
                .font(.footnote)
        }
        .padding()
    }
    
    private func loginUser() {
        do {
            if let _ = try UserRepository.fetchUser(username: username, password: password) {
                authManager.logIn()
                loginStatusMessage = "Login successful!"
            } else {
                loginStatusMessage = "Invalid username or password."
            }
        } catch {
            loginStatusMessage = "Failed to login: \(error)"
        }
    }
    
    private func createUser() {
        do {
            try UserRepository.createUser(username: username, password: password)
            authManager.logIn()
            loginStatusMessage = "Account created! You’re now logged in."
        } catch {
            loginStatusMessage = "Failed to sign up: \(error)"
        }
    }
}
