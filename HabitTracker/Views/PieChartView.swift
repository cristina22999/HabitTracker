//
//  PieChartView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 26/11/24.
//

import SwiftUI

struct PieChartView: View {
    let events: [Event]

    // Computed property for category totals
    private var categoryTotals: [(categoryID: Int64, percentage: Double)] {
        // Step 1: Calculate total duration across all events
        let totalDuration = events.reduce(0) { $0 + $1.eventLength }
        guard totalDuration > 0 else { return [] } // Return an empty array if no events

        // Step 2: Group events by categoryID
        let grouped = Dictionary(grouping: events, by: { $0.categoryID })

        // Step 3: Compute total duration and percentages for each category
        var results: [(categoryID: Int64, percentage: Double)] = []

        for (categoryID, eventsInCategory) in grouped {
            // Total duration for the category
            let totalForCategory = eventsInCategory.reduce(0) { $0 + $1.eventLength }

            // Percentage calculation
            let percentage = Double(totalForCategory) / Double(totalDuration) * 100

            // Append result
            results.append((categoryID: categoryID, percentage: percentage))
        }

        // Step 4: Sort by percentage in descending order
        return results.sorted { $0.percentage > $1.percentage }
    }

    var body: some View {
        VStack {
            ZStack {
                DonutPieChart(data: categoryTotals)
                    .frame(width: 200, height: 200)

                Text("Balance")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Legend
            VStack(alignment: .leading) {
                ForEach(categoryTotals, id: \.categoryID) { item in
                    HStack {
                        Rectangle()
                            .fill(Color(hex: fetchCategoryColor(for: item.categoryID)))
                            .frame(width: 20, height: 20)
                            .cornerRadius(5)
                        Text("\(fetchCategoryName(for: item.categoryID))")
                            .font(.subheadline)
                        Spacer()
                        Text("\(String(format: "%.1f", item.percentage))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private func fetchCategoryColor(for categoryID: Int64) -> String {
        do {
            return try DatabaseManager.shared.fetchCategoryColor(for: categoryID)
        } catch {
            print("Error fetching color for category \(categoryID): \(error)")
            return "#CCCCCC"
        }
    }
    
    private func fetchCategoryName(for categoryID: Int64) -> String {
        do {
            return try DatabaseManager.shared.fetchCategoryName(for: categoryID)
        } catch {
            print("Error fetching name for category \(categoryID): \(error)")
            return "Life"
        }
    }
}
