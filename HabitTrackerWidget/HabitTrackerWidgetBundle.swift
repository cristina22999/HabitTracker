//
//  HabitTrackerWidgetBundle.swift
//  HabitTrackerWidget
//
//  Created by Cristina Poncela on 15/02/25.
//

import WidgetKit
import SwiftUI

@main
struct HabitTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        HabitTrackerWidgetControl()
        HabitTrackerWidgetLiveActivity()
    }
}
