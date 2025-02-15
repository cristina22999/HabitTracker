//
//  BalanceWidget.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 15/02/25.
//

import WidgetKit
import SwiftUI

struct BalanceWidget: Widget {
    static let kind = "com.cristinaponcela.habit-tracker.balanceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: BalanceTimelineProvider()
        ) { entry in
            BalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Balance Widget")
        .description("Shows your daily, weekly, and monthly activity balance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
