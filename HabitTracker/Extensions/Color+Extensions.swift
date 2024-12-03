//
//  Color+Extensions.swift
//  HabitTracker
//
//  Created by Cristina Poncela on 05/11/24.
//

import SwiftUI

extension Color {
    /// Initializes a Color from a hex string.
    /// - Parameter hex: A string in the format "#RRGGBB" or "RRGGBB".
    /// Defaults to blue (`#0000FF`) for invalid input.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")

        // Ensure the hex string is valid
        guard hex.count == 6, let intCode = Int(hex, radix: 16) else {
            // Default to blue if invalid
            self = Color.blue
            return
        }

        // Extract RGB components
        let red = Double((intCode >> 16) & 0xFF) / 255.0
        let green = Double((intCode >> 8) & 0xFF) / 255.0
        let blue = Double(intCode & 0xFF) / 255.0

        // Initialize the color
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }

    /// Converts a Color to its hex string representation.
    /// - Returns: A string in the format "#RRGGBB".
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

