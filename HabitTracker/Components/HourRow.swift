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
    }

    private func hourText(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private func handleEnter() {
        guard !eventName.isEmpty else { return }
        onSaveEvent(eventName)
        eventName = ""
    }
}
