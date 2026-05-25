import Foundation
import SwiftUI

enum themeModel {

    // ======================================================
    // MARK: - Core Colors
    // ======================================================

    static let backgroundPrimary = Color(UIColor.systemGroupedBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemGroupedBackground)
    static let backgroundElevated = Color(UIColor.systemBackground)
    static let backgroundModal = Color(UIColor.systemBackground)
    static let white = Color.white
    static let black = Color.black

    // ======================================================
    // MARK: - Surface Colors
    // ======================================================

    static let surfacePrimary = Color(UIColor.systemBackground)
    static let surfaceSecondary = Color(UIColor.secondarySystemBackground)
    static let surfaceTertiary = Color(UIColor.tertiarySystemBackground)
    static let cardBackground = Color(UIColor.systemBackground)
    static let inputBackground = Color(UIColor.secondarySystemBackground)
    static let divider = Color(UIColor.separator)
    static let border = Color(UIColor.opaqueSeparator)

    // ======================================================
    // MARK: - Text Colors
    // ======================================================

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(UIColor.tertiaryLabel)
    static let textDisabled = Color(UIColor.quaternaryLabel)
    static let textInverse = Color(UIColor.systemBackground)

    // ======================================================
    // MARK: - Brand & Accents
    // ======================================================

    static let accent = Color.teal
    static let accentForeground = Color(UIColor.systemBackground)
    
    static let driverPrimary = Color("Driver")
    static let maintenancePrimary = Color.brown

    // ======================================================
    // MARK: - Semantic Colors
    // ======================================================

    static let success = Color.green
    static let successDark = Color(UIColor.systemGreen)
    static let successLight = Color.green.opacity(0.6)

    static let warning = Color.yellow
    static let warningDark = Color.orange
    static let warningLight = Color.yellow.opacity(0.6)

    static let danger = Color.red
    static let dangerDark = Color(UIColor.systemRed)
    static let dangerLight = Color.red.opacity(0.6)

    static let info = Color.blue
    static let infoDark = Color(UIColor.systemBlue)
    static let infoLight = Color.blue.opacity(0.6)

    // ======================================================
    // MARK: - Status Colors
    // ======================================================

    static let activeVehicle = success
    static let inactiveVehicle = textTertiary
    static let maintenanceVehicle = warning
    static let emergencyVehicle = danger

    static let onlineDriver = success
    static let offlineDriver = danger
    static let idleDriver = warning

    static let tripAssigned = info
    static let tripStarted = warning
    static let tripCompleted = success
    static let tripCancelled = danger
    static let tripDelayed = Color.orange

    static let notificationSuccess = success
    static let notificationWarning = warning
    static let notificationError = danger
    static let notificationInfo = info

    // ======================================================
    // MARK: - Dashboard Metric Colors
    // ======================================================

    static let analyticsGreen = Color.green
    static let analyticsRed = Color.red
    static let analyticsYellow = Color.yellow
    static let analyticsBlue = Color.blue
    static let analyticsPurple = Color.purple

    // ======================================================
    // MARK: - Interactive States
    // ======================================================

    static let buttonPrimary = Color.primary
    static let buttonPrimaryText = Color(UIColor.systemBackground)
    static let buttonSecondary = Color(UIColor.secondarySystemFill)
    static let buttonSecondaryText = Color.primary
    static let buttonDisabled = Color(UIColor.tertiarySystemFill)
    static let buttonDisabledText = Color(UIColor.tertiaryLabel)

    static let inputBorder = Color(UIColor.opaqueSeparator)
    static let inputFocusedBorder = Color.primary
    static let inputErrorBorder = danger
    static let placeholder = Color(UIColor.placeholderText)

    static let navigationBar = Color(UIColor.systemBackground)
    static let tabBar = Color(UIColor.systemBackground)
    static let selectedTab = Color.primary
    static let unselectedTab = Color.secondary

    // ======================================================
    // MARK: - Shadows
    // ======================================================

    static let shadowPrimary = Color.black.opacity(0.1)
    static let shadowSoft = Color.black.opacity(0.05)

    // ======================================================
    // MARK: - Radius
    // ======================================================

    static let radiusXS: CGFloat = 8
    static let radiusSM: CGFloat = 12
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 28
    static let radiusXXL: CGFloat = 36

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
