//
//  DonutPieChart.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 26/11/24.
//

import SwiftUI

struct DonutPieChart: View {
    let data: [(categoryID: Int64, percentage: Double)]

    @State private var colors: [Int64: String] = [:] // A mapping of categoryID to color hex values
    @State private var animationProgress: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let lineWidth = radius / 3

            ZStack {
                ForEach(data.indices, id: \.self) { index in
                    let startAngle = startAngle(for: index)
                    let endAngle = startAngle + angle(for: data[index].percentage)

                    DonutSlice(
                        startAngle: startAngle,
                        endAngle: endAngle * animationProgress,
                        color: Color(hex: colors[data[index].categoryID] ?? "#CCCCCC"), // Fallback to default
                        lineWidth: lineWidth
                    )
                }
            }
            .onAppear {
                fetchColors()
                withAnimation(.easeOut(duration: 1.5)) {
                    animationProgress = 1.0
                }
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        if index == 0 {
            return .degrees(-90)
        }
        let previousPercentages = data[0..<index].map { $0.percentage }.reduce(0, +)
        return .degrees(-90 + (previousPercentages / 100) * 360)
    }

    private func angle(for percentage: Double) -> Angle {
        return .degrees((percentage / 100) * 360)
    }

    private func fetchColors() {
        for item in data {
            do {
                let color = try DatabaseManager.shared.fetchCategoryColor(for: item.categoryID)
                colors[item.categoryID] = color
            } catch {
                print("Error fetching category color for categoryID \(item.categoryID): \(error)")
                colors[item.categoryID] = "#CCCCCC" // Default fallback color
            }
        }
    }
}
