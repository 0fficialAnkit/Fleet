//
//  themeModel.swift
//  Fleet
//
//  iOS 26 Liquid Glass Theme
//  Fleet Operations Design System
//

import Foundation
import SwiftUI

enum themeModel {

    // ======================================================
    // MARK: - Core Brand Colors
    // ======================================================

    static let backgroundPrimary = Color.dynamic(light: Color(hex: "#F8FAFC"), dark: Color(hex: "#060816"))
    static let backgroundSecondary = Color.dynamic(light: Color(hex: "#F1F5F9"), dark: Color(hex: "#0D1323"))
    static let backgroundElevated = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#131A2E"))
    static let backgroundModal = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#182033"))
    static let white = Color(hex: "#F8FAFF")
    static let black = Color(hex: "#020305")

    // ======================================================
    // MARK: - Surface Colors
    // ======================================================

    static let surfacePrimary = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#111827"))
    static let surfaceSecondary = Color.dynamic(light: Color(hex: "#F8FAFC"), dark: Color(hex: "#172033"))
    static let surfaceTertiary = Color.dynamic(light: Color(hex: "#F1F5F9"), dark: Color(hex: "#1F2A40"))
    static let cardBackground = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#151E31"))
    static let inputBackground = Color.dynamic(light: Color(hex: "#F1F5F9"), dark: Color(hex: "#101827"))
    static let divider = Color.dynamic(light: Color(hex: "#E2E8F0"), dark: Color(hex: "#24324D"))
    static let border = Color.dynamic(light: Color(hex: "#CBD5E1"), dark: Color(hex: "#32425F"))

    // ======================================================
    // MARK: - Text Colors
    // ======================================================

    static let textPrimary = Color.dynamic(light: Color(hex: "#0F172A"), dark: Color(hex: "#F5F7FF"))
    static let textSecondary = Color.dynamic(light: Color(hex: "#475569"), dark: Color(hex: "#B7C2D9"))
    static let textTertiary = Color.dynamic(light: Color(hex: "#64748B"), dark: Color(hex: "#7F8CA8"))
    static let textDisabled = Color.dynamic(light: Color(hex: "#94A3B8"), dark: Color(hex: "#586278"))
    static let textInverse = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color.black)

    // ======================================================
    // MARK: - Brand Accent
    // ======================================================

    static let accent = Color.dynamic(light: Color(hex: "#008B99"), dark: Color(hex: "#5EEBFF"))
    static let accentForeground = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#061018"))

    // ======================================================
    // MARK: - Driver Accent
    // ======================================================

    static let driverPrimary = Color("Driver")

    // ======================================================
    // MARK: - Maintenance Accent
    // ======================================================

    static let maintenancePrimary = Color.dynamic(light: Color(hex: "#7C3AED"), dark: Color(hex: "#A78BFA"))

    // ======================================================
    // MARK: - Semantic Colors
    // ======================================================

    static let success = Color(hex: "#00F5A0")
    static let successDark = Color(hex: "#00B074")
    static let successLight = Color(hex: "#66FFD0")

    static let warning = Color(hex: "#FFD60A")
    static let warningDark = Color(hex: "#C89B00")
    static let warningLight = Color(hex: "#FFE566")

    static let danger = Color(hex: "#FF375F")
    static let dangerDark = Color(hex: "#C1123F")
    static let dangerLight = Color(hex: "#FF7B97")

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

    static let buttonPrimary = Color.dynamic(light: Color(hex: "#0F172A"), dark: Color(hex: "#5EEBFF"))
    static let buttonPrimaryText = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#071018"))
    static let buttonSecondary = Color.dynamic(light: Color(hex: "#E2E8F0"), dark: Color(hex: "#1A2338"))
    static let buttonSecondaryText = Color.dynamic(light: Color(hex: "#0F172A"), dark: Color(hex: "#F5F7FF"))
    static let buttonDisabled = Color.dynamic(light: Color(hex: "#CBD5E1"), dark: Color(hex: "#2B3447"))
    static let buttonDisabledText = Color.dynamic(light: Color(hex: "#64748B"), dark: Color(hex: "#6C768C"))

    // ======================================================
    // MARK: - Input Fields
    // ======================================================

    static let inputBorder = Color.dynamic(light: Color(hex: "#CBD5E1"), dark: Color(hex: "#334155"))
    static let inputFocusedBorder = Color.dynamic(light: Color(hex: "#0F172A"), dark: Color(hex: "#5EEBFF"))
    static let inputErrorBorder = danger
    static let placeholder = Color.dynamic(light: Color(hex: "#94A3B8"), dark: Color(hex: "#718096"))

    // ======================================================
    // MARK: - Navigation
    // ======================================================

    static let navigationBar = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#060816"))
    static let tabBar = Color.dynamic(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#0B1020"))
    static let selectedTab = Color.dynamic(light: Color(hex: "#0F172A"), dark: Color(hex: "#5EEBFF"))
    static let unselectedTab = Color.dynamic(light: Color(hex: "#94A3B8"), dark: Color(hex: "#7C8CA8"))

    // ======================================================
    // MARK: - Shadows & Glow
    // ======================================================

    static let shadowPrimary = Color.black.opacity(0.15)
    static let shadowSoft = Color.black.opacity(0.08)

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

    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

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
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
