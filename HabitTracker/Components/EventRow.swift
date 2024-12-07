//
//  EventRow.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 20/11/24.
//

import SwiftUI

struct EventRow: View {
    let event: Event
    var onEventTapped: (Event) -> Void
    var onMoveEvent: (Event, Int, Int) -> Void

    @State private var categoryColor: String = "#0000FF" // Default color

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background with dynamic height and category color
            Rectangle()
                .fill(Color(hex: categoryColor)) // Use dynamically fetched category color
                .frame(
                    width: UIScreen.main.bounds.width * 0.7,
                    height: CGFloat(event.eventLength)
                )
                .cornerRadius(10)
                .offset(y: CGFloat(event.eventMinute))
                .padding(.leading, 84) // Align horizontally with the grey lines
                .onTapGesture {
                    onEventTapped(event)
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let (newHour, newMinute) = calculateNewTime(from: value.translation.height)
                            onMoveEvent(event, newHour, newMinute)
                        }
                )

            // Centered Event name
            VStack {
                Spacer() // Push the text down
                Text(event.eventName)
                    .padding(.leading, 10)
                    .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                Spacer() // Push the text up
            }
            .frame(
                width: UIScreen.main.bounds.width * 0.7,
                height: CGFloat(event.eventLength)
            )
            .padding(.leading, 84) // Align text horizontally with the grey lines
            .offset(y: CGFloat(event.eventMinute))
        }
        .offset(y: 10) // Shift everything down by 10 points
        .onAppear {
            updateCategoryColor(for: event.categoryID)
        }
        .onChange(of: event.categoryID) { newCategoryID in
                    updateCategoryColor(for: newCategoryID) // Fetch new color when categoryID changes
                }
    }
    
    private func updateCategoryColor(for categoryID: Int64) {
        do {
            // Fetch the category color using DatabaseManager
            let fetchedColor = try DatabaseManager.shared.fetchCategoryColor(for: categoryID)
            DispatchQueue.main.async {
                self.categoryColor = fetchedColor // Update state with the fetched color
            }
        } catch {
            print("Error fetching category color for categoryID \(categoryID): \(error)")
            DispatchQueue.main.async {
                self.categoryColor = "#0000FF" // Fallback to default color
            }
        }
    }


    private func calculateNewTime(from translation: CGFloat) -> (Int, Int) {
        let hourChange = Int(translation / 60)
        let minuteChange = Int((translation.truncatingRemainder(dividingBy: 60)) / 15) * 15
        let newHour = max(0, min(23, event.eventHour + hourChange))
        let newMinute = max(0, min(45, minuteChange))
        return (newHour, newMinute)
    }
}
