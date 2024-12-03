//
//  DonutSlice.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 26/11/24.
//

import SwiftUI

struct DonutSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let lineWidth: CGFloat

    @State private var animationProgress: CGFloat = 0.0 // Controls how much of the slice is drawn

    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 100

            // Add arc for the slice
            path.addArc(
                center: center,
                radius: radius - lineWidth / 2,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
        .trim(from: 0.0, to: animationProgress) // Draw only part of the path based on progress
        .stroke(color, lineWidth: lineWidth) // Draw the arc as a stroke
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0 // Animate the drawing of the slice
            }
        }
    }
}

