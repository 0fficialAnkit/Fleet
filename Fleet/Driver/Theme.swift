import SwiftUI

// MARK: - Fleet Design System

enum FleetTheme {
    static let accent       = Color(hex: "34D399")   // emerald green
    static let accentBlue   = Color(hex: "60A5FA")   // sky blue
    static let accentOrange = Color(hex: "FB923C")   // warm orange
    static let accentPurple = Color(hex: "A78BFA")   // violet
    static let surface      = Color(hex: "141418")
    static let card         = Color(hex: "1C1C24")
    static let cardBorder   = Color.white.opacity(0.07)
    static let background   = Color(hex: "0A0A0F")
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
