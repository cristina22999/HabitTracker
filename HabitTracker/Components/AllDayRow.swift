//
//  AllDayRow.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 19/11/24.
//

import SwiftUI

struct AllDayRow: View {
    let event: Event
    var onEventTapped: (Event) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("All Day")
                .font(.headline)
                .frame(width: 80, alignment: .leading)
                .padding(.leading, 20)

            Text(event.eventName)
                .font(.body)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.3))
                .cornerRadius(8)
                .onTapGesture {
                    onEventTapped(event)
                }
        }
        .padding(.horizontal)
    }
}
