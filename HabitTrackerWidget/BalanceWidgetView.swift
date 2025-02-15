//
//  BalanceWidgetView.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 15/02/25.
//

import SwiftUI
import WidgetKit

struct BalanceWidgetView: View {
    let entry: BalanceTimelineEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallBalanceView(entry: entry)
        case .systemMedium:
            MediumBalanceView(entry: entry)
        case .systemLarge:
            LargeBalanceView(entry: entry)
        case .systemExtraLarge:
            ExtraLargeBalanceView(entry: entry)
        @unknown default:
            MediumBalanceView(entry: entry)
        }
    }
}

// Small widget shows only daily balance
struct SmallBalanceView: View {
    let entry: BalanceTimelineEntry
    
    var body: some View {
        VStack {
            Text(formattedDate)
                .font(.caption)
                .bold()
            CompactPieChartView(events: entry.dailyEvents)
                .frame(width: 100, height: 100)
        }
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
}

// Medium widget shows daily and weekly
struct MediumBalanceView: View {
    let entry: BalanceTimelineEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Daily Balance
            VStack {
                Text(formattedDate)
                    .font(.caption)
                    .bold()
                CompactPieChartView(events: entry.dailyEvents)
                    .frame(width: 80, height: 80)
            }
            
            // Weekly Balance
            VStack {
                Text("WEEK \(weekNumber)")
                    .font(.caption)
                    .bold()
                CompactPieChartView(events: entry.weeklyEvents)
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
    
    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: entry.date)
    }
}

// Large widget shows all three (original layout)
struct LargeBalanceView: View {
    let entry: BalanceTimelineEntry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Daily Balance
                VStack {
                    Text(formattedDate)
                        .font(.caption)
                        .bold()
                    CompactPieChartView(events: entry.dailyEvents)
                        .frame(width: 80, height: 80)
                }
                
                // Weekly Balance
                VStack {
                    Text("WEEK \(weekNumber)")
                        .font(.caption)
                        .bold()
                    CompactPieChartView(events: entry.weeklyEvents)
                        .frame(width: 80, height: 80)
                }
            }
            
            // Monthly Balance
            VStack {
                Text(monthYear)
                    .font(.caption)
                    .bold()
                CompactPieChartView(events: entry.monthlyEvents)
                    .frame(width: 80, height: 80)
            }
        }
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
    
    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: entry.date)
    }
    
    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: entry.date).uppercased()
    }
}

// Extra large widget shows all three with additional details
struct ExtraLargeBalanceView: View {
    let entry: BalanceTimelineEntry
    
    var body: some View {
        HStack(spacing: 24) {
            // Daily Balance
            VStack {
                Text(formattedDate)
                    .font(.title3)
                    .bold()
                CompactPieChartView(events: entry.dailyEvents)
                    .frame(width: 120, height: 120)
                if !entry.dailyEvents.isEmpty {
                    Text("\(entry.dailyEvents.count) events")
                        .font(.caption)
                }
            }
            
            // Weekly Balance
            VStack {
                Text("WEEK \(weekNumber)")
                    .font(.title3)
                    .bold()
                CompactPieChartView(events: entry.weeklyEvents)
                    .frame(width: 120, height: 120)
                if !entry.weeklyEvents.isEmpty {
                    Text("\(entry.weeklyEvents.count) events")
                        .font(.caption)
                }
            }
            
            // Monthly Balance
            VStack {
                Text(monthYear)
                    .font(.title3)
                    .bold()
                CompactPieChartView(events: entry.monthlyEvents)
                    .frame(width: 120, height: 120)
                if !entry.monthlyEvents.isEmpty {
                    Text("\(entry.monthlyEvents.count) events")
                        .font(.caption)
                }
            }
        }
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
    
    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: entry.date)
    }
    
    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: entry.date).uppercased()
    }
}