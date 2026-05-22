////
////  themeModel.swift
////  Fleet
////
////  Created by Ankit Kumar on 19/05/26.
////
//
//import Foundation
//import SwiftUI
//
//enum themeModel {
//
//    
//    // MARK: - Core Brand Colors
//    
//
//    /// Primary app background
//    static let backgroundPrimary = Color(hex: "#000000")
//
//    /// Secondary layered background
//    static let backgroundSecondary = Color(hex: "#0F0F10")
//
//    /// Elevated cards/sheets
//    static let backgroundElevated = Color(hex: "#171717")
//
//    /// Modal background
//    static let backgroundModal = Color(hex: "#1C1C1E")
//
//    /// Pure white
//    static let white = Color.white
//
//    /// Pure black
//    static let black = Color.black
//
//    // ======================================================
//    // MARK: - Surface Colors
//    // ======================================================
//
//    static let surfacePrimary = Color(hex: "#111111")
//    static let surfaceSecondary = Color(hex: "#1A1A1A")
//    static let surfaceTertiary = Color(hex: "#242424")
//
//    static let cardBackground = Color(hex: "#151515")
//    static let inputBackground = Color(hex: "#1E1E1E")
//
//    static let divider = Color(hex: "#2A2A2A")
//    static let border = Color(hex: "#303030")
//
//    // ======================================================
//    // MARK: - Text Colors
//    // ======================================================
//
//    static let textPrimary = Color.white
//
//    static let textSecondary = Color(hex: "#B0B0B0")
//
//    static let textTertiary = Color(hex: "#7A7A7A")
//
//    static let textDisabled = Color(hex: "#5A5A5A")
//
//    static let textInverse = Color.black
//
//    // ======================================================
//    // MARK: - Brand Accent
//    // ======================================================
//
//    /// Uber-style white accent
//    static let accent = Color.white
//
//    static let accentForeground = Color.black
//
//    // ======================================================
//    // MARK: - Semantic Colors
//    // ======================================================
//
//    /// Success / Accepted / Completed
//    static let success = Color(hex: "#22C55E")
//
//    static let successDark = Color(hex: "#15803D")
//
//    static let successLight = Color(hex: "#4ADE80")
//
//    /// Warning / In Progress / Pending
//    static let warning = Color(hex: "#FACC15")
//
//    static let warningDark = Color(hex: "#CA8A04")
//
//    static let warningLight = Color(hex: "#FDE047")
//
//    /// Error / Cancelled / Rejected
//    static let danger = Color(hex: "#EF4444")
//
//    static let dangerDark = Color(hex: "#B91C1C")
//
//    static let dangerLight = Color(hex: "#F87171")
//
//    /// Info / Navigation / Tracking
//    static let info = Color(hex: "#3B82F6")
//
//    static let infoDark = Color(hex: "#1D4ED8")
//
//    static let infoLight = Color(hex: "#60A5FA")
//
//    // ======================================================
//    // MARK: - Fleet Status Colors
//    // ======================================================
//
//    static let activeVehicle = success
//
//    static let inactiveVehicle = textTertiary
//
//    static let maintenanceVehicle = warning
//
//    static let emergencyVehicle = danger
//
//    static let onlineDriver = success
//
//    static let offlineDriver = danger
//
//    static let idleDriver = warning
//
//    // ======================================================
//    // MARK: - Trip Status Colors
//    // ======================================================
//
//    static let tripAssigned = info
//
//    static let tripStarted = warning
//
//    static let tripCompleted = success
//
//    static let tripCancelled = danger
//
//    static let tripDelayed = Color(hex: "#FB923C")
//
//    // ======================================================
//    // MARK: - Notification Colors
//    // ======================================================
//
//    static let notificationSuccess = success
//
//    static let notificationWarning = warning
//
//    static let notificationError = danger
//
//    static let notificationInfo = info
//
//    // ======================================================
//    // MARK: - Dashboard Metric Colors
//    // ======================================================
//
//    static let analyticsGreen = Color(hex: "#10B981")
//
//    static let analyticsRed = Color(hex: "#F43F5E")
//
//    static let analyticsYellow = Color(hex: "#EAB308")
//
//    static let analyticsBlue = Color(hex: "#3B82F6")
//
//    static let analyticsPurple = Color(hex: "#8B5CF6")
//
//    // ======================================================
//    // MARK: - Interactive States
//    // ======================================================
//
//    static let buttonPrimary = Color.white
//
//    static let buttonPrimaryText = Color.black
//
//    static let buttonSecondary = Color(hex: "#1F1F1F")
//
//    static let buttonSecondaryText = Color.white
//
//    static let buttonDisabled = Color(hex: "#3A3A3A")
//
//    static let buttonDisabledText = Color(hex: "#737373")
//
//    // ======================================================
//    // MARK: - Input Fields
//    // ======================================================
//
//    static let inputBorder = Color(hex: "#3A3A3A")
//
//    static let inputFocusedBorder = Color.white
//
//    static let inputErrorBorder = danger
//
//    static let placeholder = Color(hex: "#6B7280")
//
//    // ======================================================
//    // MARK: - Navigation
//    // ======================================================
//
//    static let navigationBar = Color.black
//
//    static let tabBar = Color(hex: "#0E0E0E")
//
//    static let selectedTab = Color.white
//
//    static let unselectedTab = Color(hex: "#6B7280")
//
//    // ======================================================
//    // MARK: - Shadows
//    // ======================================================
//
//    static let shadowPrimary = Color.black.opacity(0.25)
//
//    static let shadowSoft = Color.black.opacity(0.12)
//
//    // ======================================================
//    // MARK: - Radius
//    // ======================================================
//
//    static let radiusXS: CGFloat = 6
//
//    static let radiusSM: CGFloat = 10
//
//    static let radiusMD: CGFloat = 14
//
//    static let radiusLG: CGFloat = 18
//
//    static let radiusXL: CGFloat = 26
//
//    static let radiusXXL: CGFloat = 34
//
//    // ======================================================
//    // MARK: - Spacing System
//    // ======================================================
//
//    static let spacingXS: CGFloat = 4
//
//    static let spacingSM: CGFloat = 8
//
//    static let spacingMD: CGFloat = 16
//
//    static let spacingLG: CGFloat = 24
//
//    static let spacingXL: CGFloat = 32
//
//    static let spacingXXL: CGFloat = 40
//
//    // ======================================================
//    // MARK: - Typography
//    // Native iOS 26 Inspired
//    // ======================================================
//
//    static func largeTitle(_ size: CGFloat = 34) -> Font {
//        .system(size: size, weight: .bold, design: .rounded)
//    }
//
//    static func title(_ size: CGFloat = 28) -> Font {
//        .system(size: size, weight: .bold, design: .rounded)
//    }
//
//    static func headline(_ size: CGFloat = 18) -> Font {
//        .system(size: size, weight: .semibold, design: .rounded)
//    }
//
//    static func body(_ size: CGFloat = 16) -> Font {
//        .system(size: size, weight: .regular, design: .rounded)
//    }
//
//    static func bodyMedium(_ size: CGFloat = 16) -> Font {
//        .system(size: size, weight: .medium, design: .rounded)
//    }
//
//    static func caption(_ size: CGFloat = 13) -> Font {
//        .system(size: size, weight: .regular, design: .rounded)
//    }
//
//    static func small(_ size: CGFloat = 11) -> Font {
//        .system(size: size, weight: .medium, design: .rounded)
//    }
//}
//
//// ======================================================
//// MARK: - Color Extension
//// Hex Color Support
//// ======================================================
//
//extension Color {
//
//    init(hex: String) {
//
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//
//        var int: UInt64 = 0
//
//        Scanner(string: hex).scanHexInt64(&int)
//
//        let a, r, g, b: UInt64
//
//        switch hex.count {
//
//        case 3:
//            (a, r, g, b) = (
//                255,
//                (int >> 8) * 17,
//                (int >> 4 & 0xF) * 17,
//                (int & 0xF) * 17
//            )
//
//        case 6:
//            (a, r, g, b) = (
//                255,
//                int >> 16,
//                int >> 8 & 0xFF,
//                int & 0xFF
//            )
//
//        case 8:
//            (a, r, g, b) = (
//                int >> 24,
//                int >> 16 & 0xFF,
//                int >> 8 & 0xFF,
//                int & 0xFF
//            )
//
//        default:
//            (a, r, g, b) = (255, 255, 255, 255)
//        }
//
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue: Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}


//
//  themeModel.swift
//  Fleet
//
//  CyberOps Enterprise Theme
//  Ultra Premium Fleet Operations UI
//

import Foundation
import SwiftUI

enum themeModel {

    // ======================================================
    // MARK: - Core Brand Colors
    // Cyberpunk + Tesla + VisionOS Inspired
    // ======================================================

    /// Main background
    static let backgroundPrimary = Color(hex: "#060816")

    /// Layered operational background
    static let backgroundSecondary = Color(hex: "#0D1323")

    /// Elevated dashboard surfaces
    static let backgroundElevated = Color(hex: "#131A2E")

    /// Modal / sheets
    static let backgroundModal = Color(hex: "#182033")

    /// Pure white highlight
    static let white = Color(hex: "#F8FAFF")

    /// Black
    static let black = Color(hex: "#020305")

    // ======================================================
    // MARK: - Surface Colors
    // ======================================================

    static let surfacePrimary = Color(hex: "#111827")

    static let surfaceSecondary = Color(hex: "#172033")

    static let surfaceTertiary = Color(hex: "#1F2A40")

    static let cardBackground = Color(hex: "#151E31")

    static let inputBackground = Color(hex: "#101827")

    static let divider = Color(hex: "#24324D")

    static let border = Color(hex: "#32425F")

    // ======================================================
    // MARK: - Text Colors
    // ======================================================

    static let textPrimary = Color(hex: "#F5F7FF")

    static let textSecondary = Color(hex: "#B7C2D9")

    static let textTertiary = Color(hex: "#7F8CA8")

    static let textDisabled = Color(hex: "#586278")

    static let textInverse = Color.black

    // ======================================================
    // MARK: - Brand Accent
    // ======================================================

    /// Electric cyan accent
    static let accent = Color(hex: "#5EEBFF")

    static let accentForeground = Color(hex: "#061018")

    // ======================================================
    // MARK: - Semantic Colors
    // ======================================================

    /// Active / Operational
    static let success = Color(hex: "#00F5A0")

    static let successDark = Color(hex: "#00B074")

    static let successLight = Color(hex: "#66FFD0")

    /// Maintenance / Warning
    static let warning = Color(hex: "#FFD60A")

    static let warningDark = Color(hex: "#C89B00")

    static let warningLight = Color(hex: "#FFE566")

    /// Critical / Emergency
    static let danger = Color(hex: "#FF375F")

    static let dangerDark = Color(hex: "#C1123F")

    static let dangerLight = Color(hex: "#FF7B97")

    /// Tracking / Navigation / Info
    static let info = Color(hex: "#4DA8FF")

    static let infoDark = Color(hex: "#1C6DD0")

    static let infoLight = Color(hex: "#88C8FF")

    // ======================================================
    // MARK: - Fleet Status Colors
    // ======================================================

    static let activeVehicle = success

    static let inactiveVehicle = textTertiary

    static let maintenanceVehicle = warning

    static let emergencyVehicle = danger

    static let onlineDriver = success

    static let offlineDriver = danger

    static let idleDriver = warning

    // ======================================================
    // MARK: - Trip Status Colors
    // ======================================================

    static let tripAssigned = info

    static let tripStarted = warning

    static let tripCompleted = success

    static let tripCancelled = danger

    static let tripDelayed = Color(hex: "#FF9F1C")

    // ======================================================
    // MARK: - Notification Colors
    // ======================================================

    static let notificationSuccess = success

    static let notificationWarning = warning

    static let notificationError = danger

    static let notificationInfo = info

    // ======================================================
    // MARK: - Dashboard Metric Colors
    // ======================================================

    static let analyticsGreen = Color(hex: "#00FFB2")

    static let analyticsRed = Color(hex: "#FF4D6D")

    static let analyticsYellow = Color(hex: "#FFD93D")

    static let analyticsBlue = Color(hex: "#5DA9FF")

    static let analyticsPurple = Color(hex: "#9B5CFF")

    // ======================================================
    // MARK: - Interactive States
    // ======================================================

    static let buttonPrimary = Color(hex: "#5EEBFF")

    static let buttonPrimaryText = Color(hex: "#071018")

    static let buttonSecondary = Color(hex: "#1A2338")

    static let buttonSecondaryText = Color(hex: "#F5F7FF")

    static let buttonDisabled = Color(hex: "#2B3447")

    static let buttonDisabledText = Color(hex: "#6C768C")

    // ======================================================
    // MARK: - Input Fields
    // ======================================================

    static let inputBorder = Color(hex: "#334155")

    static let inputFocusedBorder = Color(hex: "#5EEBFF")

    static let inputErrorBorder = danger

    static let placeholder = Color(hex: "#718096")

    // ======================================================
    // MARK: - Navigation
    // ======================================================

    static let navigationBar = Color(hex: "#060816")

    static let tabBar = Color(hex: "#0B1020")

    static let selectedTab = Color(hex: "#5EEBFF")

    static let unselectedTab = Color(hex: "#7C8CA8")

    // ======================================================
    // MARK: - Shadows & Glow
    // ======================================================

    static let shadowPrimary = Color.black.opacity(0.45)

    static let shadowSoft = Color(hex: "#5EEBFF").opacity(0.08)

    // ======================================================
    // MARK: - Radius
    // ======================================================

    static let radiusXS: CGFloat = 8

    static let radiusSM: CGFloat = 12

    static let radiusMD: CGFloat = 18

    static let radiusLG: CGFloat = 24

    static let radiusXL: CGFloat = 32

    static let radiusXXL: CGFloat = 40

    // ======================================================
    // MARK: - Spacing
    // ======================================================

    static let spacingXS: CGFloat = 4

    static let spacingSM: CGFloat = 8

    static let spacingMD: CGFloat = 16

    static let spacingLG: CGFloat = 24

    static let spacingXL: CGFloat = 32

    static let spacingXXL: CGFloat = 40

    // ======================================================
    // MARK: - Typography
    // Futuristic Enterprise UI
    // ======================================================

    static func largeTitle(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func bodyMedium(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func small(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// ======================================================
// MARK: - Color Extension
// ======================================================

extension Color {

    init(hex: String) {

        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64

        switch hex.count {

        case 3:
            (a, r, g, b) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )

        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )

        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )

        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
