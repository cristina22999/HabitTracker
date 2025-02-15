//
//  CompactPieChartView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 15/02/25.
//

import SwiftUI
import GRDB

struct CompactPieChartView: View {
    let events: [Event]
    
    private var categoryTotals: [(categoryID: Int64, percentage: Double)] {
        let totalDuration = events.reduce(0) { $0 + $1.eventLength }
        guard totalDuration > 0 else { return [] }
        
        let grouped = Dictionary(grouping: events, by: { $0.categoryID })
        return grouped.map { categoryID, events in
            let totalForCategory = events.reduce(0) { $0 + $1.eventLength }
            let percentage = Double(totalForCategory) / Double(totalDuration) * 100
            return (categoryID: categoryID, percentage: percentage)
        }.sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
            ZStack {
                if events.isEmpty {
                    // Show empty state
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                } else {
                    ForEach(categoryTotals, id: \.categoryID) { item in
                        CompactDonutSlice(
                            startAngle: startAngle(for: item),
                            endAngle: endAngle(for: item),
                            color: Color(hex: fetchCategoryColor(for: item.categoryID))
                        )
                    }
                }
            }
        }
    
    private func startAngle(for item: (categoryID: Int64, percentage: Double)) -> Angle {
        let index = categoryTotals.firstIndex { $0.categoryID == item.categoryID } ?? 0
        if index == 0 { return .degrees(-90) }
        let previousPercentages = categoryTotals[0..<index].map { $0.percentage }.reduce(0, +)
        return .degrees(-90 + (previousPercentages / 100) * 360)
    }
    
    private func endAngle(for item: (categoryID: Int64, percentage: Double)) -> Angle {
        let startAngle = startAngle(for: item)
        return startAngle + .degrees((item.percentage / 100) * 360)
    }
    
    private func fetchCategoryColor(for categoryID: Int64) -> String {
        do {
            return try DatabaseManager.shared.fetchCategoryColor(for: categoryID)
        } catch {
            return "#CCCCCC" // Default gray color
        }
    }
}

struct CompactDonutSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 40, y: 40)
            let radius: CGFloat = 35
            
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .stroke(color, lineWidth: 8)
    }
}
