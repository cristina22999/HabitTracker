//
//  AddFriendView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 21/11/24.
//

import SwiftUI
import GRDB

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friendName: String = ""
    @State private var callFrequency: String = "Weekly"
    @State private var birthday: Date? = nil
    @State private var isBirthdayUnknown: Bool = true
    @State private var customDays: String = ""
    @State private var errorMessage: String? = nil
    
    let frequencies = ["Weekly", "Biweekly", "Monthly", "On Birthday", "Custom"]
    let dbQueue: DatabaseQueue

    var body: some View {
        NavigationView {
            Form {
                Section("Friend Details") {
                    TextField("Friend's Name", text: $friendName)

                    Picker("Frequency of Call", selection: $callFrequency) {
                        ForEach(frequencies, id: \.self) { frequency in
                            Text(frequency)
                        }
                    }

                    if callFrequency == "Custom" {
                        HStack {
                            Text("Every")
                            TextField("0", text: Binding(
                                get: { customDays },
                                set: { newValue in
                                    if newValue.allSatisfy(\.isNumber) { // Restrict to numbers
                                        customDays = newValue
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .frame(width: 50) // Adjust width as needed
                            .multilineTextAlignment(.center)

                            Text("days")
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }

                    HStack(alignment: .center) {
                                            Text("Birthday")
                                            Spacer()
                                            if !isBirthdayUnknown {
                                                Text("Unknown")
                                                    .foregroundColor(.secondary)
                                                    .onTapGesture {
                                                        isBirthdayUnknown = true
                                                    }
                                            } else {
                                                DatePicker("", selection: Binding(get: { birthday ?? Date() }, set: { birthday = $0 }), displayedComponents: .date)
                                                    .labelsHidden()
                                            }
                                            // Add the "Unknown" toggle here
                                            Toggle("Unknown", isOn: $isBirthdayUnknown)
                                                .onChange(of: !isBirthdayUnknown) { newValue in
                                                    if newValue {
                                                        birthday = nil // Set birthday to nil when "Unknown" is selected
                                                    }
                                                }
                                                .labelsHidden() // Hide label for a cleaner appearance
                                        }
                                    }
                                }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if validateInput() {
                            saveFriend()
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func validateInput() -> Bool {
        if callFrequency == "Custom", Int(customDays) == nil {
            errorMessage = "Input invalid, make sure you type an integer."
            return false
        }
        errorMessage = nil
        return true
    }

    private func saveFriend() {
        guard !friendName.isEmpty else {
            print("Friend's name is required.")
            return
        }

        let frequency: Int
        let onBirthday: Bool

        switch callFrequency {
        case "Weekly":
            frequency = 7
            onBirthday = false
        case "Biweekly":
            frequency = 14
            onBirthday = false
        case "Monthly":
            frequency = 30
            onBirthday = false
        case "Custom":
            frequency = Int(customDays) ?? 0
            onBirthday = false
        case "On Birthday":
            frequency = 0
            onBirthday = true
        default:
            frequency = 0
            onBirthday = false
        }

        var newFriend = Friend(id: nil, name: friendName, frequency: frequency, birthday: birthday, onBirthday: onBirthday)

        do {
            try dbQueue.write { db in
                // Insert the friend into the database
                try newFriend.insert(db)
                
                // Retrieve the newly assigned ID
                let friendID = db.lastInsertedRowID
                newFriend.id = Int64(friendID)
                
                // Schedule calls for this friend
                let scheduler = CallScheduler(db: db)
                _ = scheduler.scheduleNextCalls(for: newFriend, from: Date(), db: db)
                        dismiss()
            }

            print("Friend saved successfully and calls scheduled!")

        } catch {
            print("Error saving friend: \(error)")
        }
    }
}
