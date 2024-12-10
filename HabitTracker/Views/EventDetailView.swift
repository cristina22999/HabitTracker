//
//  EventDetailsView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 12/11/24.
//

import SwiftUI

struct EventDetailView: View {
    var event: Event
    var onSave: () -> Void // Callback when saving changes
    var onDelete: (Bool, Event) -> Void // Callback for delete action

    @State private var eventId: Int64?
    @State private var eventName: String
    @State private var eventDescription: String = ""
    @State private var repeatFrequency: Int
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedCategoryID: Int64?
    @State private var repeatOption: String
    @State private var customFrequency: String = ""
    @State private var endTimeManuallyModified = false
    @State private var allDay: Bool
    @State private var showCreateCategory = false
    @State private var showDeleteConfirmation = false
    @State private var deleteAllFuture = false

    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var categoriesObserver = CategoriesDatabaseObserver(dbQueue: DatabaseManager.shared.dbQueue)

    init(event: Event, onSave: @escaping () -> Void, onDelete: @escaping (Bool, Event) -> Void) {
        self.event = event
        self.onSave = onSave
        self.onDelete = onDelete
        _eventId = State(initialValue: event.id)
        _eventName = State(initialValue: event.eventName)
        _repeatFrequency = State(initialValue: event.repeatFrequency)
        _startDate = State(initialValue: Calendar.current.date(
            bySettingHour: event.eventHour,
            minute: event.eventMinute,
            second: 0,
            of: event.eventDate
        ) ?? event.eventDate)
        _endDate = State(initialValue: Calendar.current.date(
            bySettingHour: event.eventHour + 1,
            minute: event.eventMinute,
            second: 0,
            of: event.eventDate)
            ?? event.eventDate)
        _selectedCategoryID = State(initialValue: event.categoryID)
        _repeatOption = State(initialValue: EventDetailView.repeatOption(for: event.repeatFrequency))
        _customFrequency = State(initialValue: event.repeatFrequency > 0 && EventDetailView.repeatOption(for: event.repeatFrequency) == "Custom" ? "\(event.repeatFrequency)" : "")
        _allDay = State(initialValue: event.allDay)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: $eventName)
                        .font(.title2)
                        .padding(.vertical, 4)

                    TextField("Description", text: $eventDescription, axis: .vertical)
                        .lineLimit(4)
                        .padding(.vertical, 4)
                }

                Section(header: Text("Date and Time")) {
                    Toggle("All Day", isOn: $allDay)
                        .onChange(of: allDay) { _, allDay in
                            if allDay {
                                startDate = Calendar.current.startOfDay(for: startDate)
                                endDate = startDate
                            }
                        }

                    DatePicker("Start", selection: $startDate, displayedComponents: allDay ? [.date] : [.date, .hourAndMinute])
                        .onChange(of: startDate) { _, newStartDate in
                            if !endTimeManuallyModified {
                                endDate = Calendar.current.date(byAdding: .hour, value: 1, to: newStartDate) ?? newStartDate
                            }
                        }

                    if !allDay {
                        DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: endDate) { _, _ in
                                endTimeManuallyModified = true
                            }
                    }
                }

                Section(header: Text("Category")) {
                    HStack {
                        Picker("Select Category", selection: $selectedCategoryID) {
                            ForEach(categoriesObserver.categories, id: \.id) { category in
                                Text(category.name).tag(category.id as Int64?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        Button(action: {
                            showCreateCategory = true
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $showCreateCategory) {
                            CreateCategoryView(onCategoryCreated: { newCategoryID in
                                selectedCategoryID = newCategoryID
                                showCreateCategory = false
                            })
                        }
                    }
                }

                Section(header: Text("Repeat")) {
                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(["None", "Every day", "Every week", "Every month", "Every year", "Custom"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .onChange(of: repeatOption) { newValue in
                        repeatFrequency = EventDetailView.repeatFrequency(for: newValue)
                    }

                    if repeatOption == "Custom" {
                        HStack {
                            Text("Every")
                            TextField("Days", text: $customFrequency)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .multilineTextAlignment(.center)
                            Text("days")
                        }
                        .onChange(of: customFrequency) { newValue in
                            repeatFrequency = Int(newValue) ?? 0
                        }
                    }
                }

                Section {
                    Button(action: {
                        if repeatFrequency > 0 {
                            // Show confirmation dialog for repeating events
                            showDeleteConfirmation = true
                        } else if repeatFrequency == 0  {
                            // Directly delete non-repeating events
                            onDelete(false, event)
                            dismiss()
                        }
                    }) {
                        Text("Delete Event")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .confirmationDialog("Delete Event", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                        Button("Delete Only This One", role: .destructive) {
                            onDelete(false, event) // Delete only this one
                            dismiss()
                        }
                        Button("Delete All Future Events", role: .destructive) {
                            onDelete(true, event) // Delete all future events
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }

            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                }
            }
        }
    }

    private func saveEvent() {
        do {
            // Calculate event length in minutes
            let eventLength = Calendar.current.dateComponents([.minute], from: startDate, to: endDate).minute ?? 0

            // Calculate repeatFrequency
            let repeatFrequency = repeatOption == "Custom" ? Int(customFrequency) ?? 0 : EventDetailView.repeatFrequency(for: repeatOption)

            // Create the updated event
            let updatedEvent = Event(
                id: event.id,
                eventName: eventName,
                eventDate: startDate,
                eventHour: allDay ? 0 : Calendar.current.component(.hour, from: startDate),
                eventMinute: allDay ? 0 : Calendar.current.component(.minute, from: startDate),
                eventLength: eventLength,
                allDay: allDay,
                categoryID: selectedCategoryID ?? 2,
                repeatFrequency: repeatFrequency
            )

            // Update the event in the database
            try DatabaseManager.shared.updateEvent(event: updatedEvent)
            onSave()
            dismiss()
        } catch {
            print("Failed to update event: \(error)")
        }
    }

    static func repeatFrequency(for repeatOption: String) -> Int {
        switch repeatOption {
        case "Every day": return 1
        case "Every week": return 7
        case "Every month": return 30
        case "Every year": return 365
        default: return 0 // "None"
        }
    }

    static func repeatOption(for repeatFrequency: Int) -> String {
        switch repeatFrequency {
        case 0: return "None"
        case 1: return "Every day"
        case 7: return "Every week"
        case 30: return "Every month"
        case 365: return "Every year"
        default: return "Custom"
        }
    }
}
