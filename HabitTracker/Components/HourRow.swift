//
//  HourRow.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 19/11/24.
//

import SwiftUI

struct HourRow: View {
    let hour: Int
    let isLastHour: Bool
    @Binding var activeHour: Int?
    @State private var eventName: String = ""
    @Binding var clearTextField: Bool
    @FocusState private var isRowTextFieldFocused: Bool
    var onSaveEvent: (String) -> Void

    var body: some View {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 4) {
                    Text(hourText(for: hour))
                        .font(.headline)
                        .frame(width: 60, alignment: .leading)
                        .offset(y: -10)
                        .padding(.leading, 20)
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: UIScreen.main.bounds.width * 0.7, height: 1)
                        
                        // TextField for adding a new event
                        TextField("", text: $eventName, onCommit: handleEnter)
                            .focused($isRowTextFieldFocused)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.leading, 10)
                            .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                            .frame(height: 60)
                            .background(isRowTextFieldFocused ? Color.blue.opacity(0.2) : Color.clear)

                        if isLastHour {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: UIScreen.main.bounds.width * 0.7, height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 0)
            .frame(height: 60)
            .onTapGesture {
                if activeHour == nil {
                    activeHour = hour
                    isRowTextFieldFocused = true
                }
            }
            .onChange(of: activeHour) { _, newValue in
                if newValue != hour {
                    isRowTextFieldFocused = false
                }
            }
            .onChange(of: clearTextField) { newValue in
                if newValue {
                    eventName = "" // Clear the text field
                    clearTextField = false // Reset the clearTextField boolean
                }
            }
        }

    private func hourText(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current // Use the current locale

        // Determine if the locale uses 12-hour or 24-hour time format
        let is12HourFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)?.contains("a") ?? false

        if is12HourFormat {
            // Use "h a" for 12-hour format (e.g., "3 PM")
            formatter.dateFormat = "h a"
        } else {
            // Use "HH:mm" for 24-hour format
            formatter.dateFormat = "HH:mm"
        }

        // Create the date with the specific hour
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }


    private func handleEnter() {
        guard !eventName.isEmpty else { return }
        onSaveEvent(eventName)
        eventName = ""
    }
}
