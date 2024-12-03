//
//  EditFriendView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 21/11/24.
//

import SwiftUI
import GRDB

struct EditFriendView: View {
    @Environment(\.dismiss) private var dismiss
    let friend: Friend
    let dbQueue: DatabaseQueue
    @State private var friendName: String
    @State private var callFrequency: String
    @State private var customDays: String = ""
    @State private var birthday: Date?
    @State private var errorMessage: String? = nil

    let frequencies = ["Weekly", "Biweekly", "Monthly", "On Birthday", "Custom"]

    init(friend: Friend, dbQueue: DatabaseQueue) {
        self.friend = friend
        self.dbQueue = dbQueue

        // Initialize states based on the existing friend's data
        _friendName = State(initialValue: friend.name)
        _birthday = State(initialValue: friend.birthday)
        if friend.frequency == 7 {
            _callFrequency = State(initialValue: "Weekly")
        } else if friend.frequency == 14 {
            _callFrequency = State(initialValue: "Biweekly")
        } else if friend.frequency == 30 {
            _callFrequency = State(initialValue: "Monthly")
        } else if friend.frequency == 0 {
            _callFrequency = State(initialValue: "On Birthday")
        } else {
            _callFrequency = State(initialValue: "Custom")
            _customDays = State(initialValue: "\(friend.frequency)")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Friend Details")) {
                    TextField("Friend Name", text: $friendName)
                        .font(.title2)
                        .padding(.vertical, 4)

                    // Picker for frequency selection
                    Picker("Frequency of Call", selection: $callFrequency) {
                        ForEach(frequencies, id: \.self) { frequency in
                            Text(frequency)
                        }
                    }

                    // Custom frequency input
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

                    // Date picker for birthday
                    DatePicker(
                        "Birthday",
                        selection: Binding(
                            get: { birthday ?? Date() },
                            set: { birthday = $0 }
                        ),
                        displayedComponents: .date
                    )
                }

                Section {
                    Button(action: deleteFriend) {
                        Text("Delete Friend")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Edit Friend")
            .toolbar {
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
        if callFrequency == "Custom", Int(customDays) == nil || customDays.isEmpty {
            errorMessage = "Input invalid, make sure you type an integer."
            return false
        }
        errorMessage = nil
        return true
    }

    private func saveFriend() {
        do {
            try dbQueue.write { db in
                var updatedFriend = friend
                updatedFriend.name = friendName

                // Convert selected frequency to an integer
                switch callFrequency {
                case "Weekly":
                    updatedFriend.frequency = 7
                case "Biweekly":
                    updatedFriend.frequency = 14
                case "Monthly":
                    updatedFriend.frequency = 30
                case "On Birthday":
                    updatedFriend.frequency = 0
                case "Custom":
                    updatedFriend.frequency = Int(customDays) ?? 0
                default:
                    updatedFriend.frequency = 0
                }

                updatedFriend.birthday = birthday
                try updatedFriend.update(db)
            }
        } catch {
            print("Error updating friend: \(error)")
        }
    }

    private func deleteFriend() {
        do {
            try dbQueue.write { db in
                let deleted = try Friend.deleteOne(db, key: friend.id)
                if !deleted {
                    print("Failed to delete friend with ID \(friend.id ?? 0)")
                }
            }
            dismiss() // Close the view after deletion
        } catch {
            print("Error deleting friend: \(error)")
        }
    }
}
