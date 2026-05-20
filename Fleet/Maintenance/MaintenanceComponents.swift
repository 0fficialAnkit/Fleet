//
//  MaintenanceComponents.swift
//  Fleet
//
//  Created by Codex on 20/05/26.
//

import SwiftUI

struct MaintenanceScreenContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        MaintenanceThemeReader { theme in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    MaintenanceTopBar()
                    content
                }
                .padding(.horizontal, 26)
                .padding(.top, 12)
                .padding(.bottom, 34)
            }
            .background(theme.screenBackground.ignoresSafeArea())
        }
    }
}

struct MaintenanceTopBar: View {
    var body: some View {
        MaintenanceThemeReader { theme in
            VStack(spacing: 22) {
                HStack {
                    Text("9:41")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.primaryText)

                    Spacer()

                    Text("◔◔◔ WiFi 100%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                }
                .padding(.horizontal, 14)

                HStack {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(theme.brandOrange)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Text("MP")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("FleetOS")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(theme.primaryText)

                            Text("Maintenance")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(theme.brandOrange)
                        }
                    }

                    Spacer()

                    HStack(spacing: 14) {
                        Circle()
                            .fill(theme.iconCircleFill)
                            .frame(width: 50, height: 50)
                            .overlay {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "message")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(theme.primaryText)

                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.24, blue: 0.46))
                                        .frame(width: 10, height: 10)
                                        .offset(x: 9, y: -9)
                                }
                            }
                            .overlay {
                                Circle()
                                    .stroke(theme.hairline, lineWidth: 1)
                            }

                        Circle()
                            .fill(theme.brandOrange)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .regular))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: theme.brandOrange.opacity(0.35), radius: 16, y: 8)
                    }
                }
                .padding(.horizontal, 2)

                Rectangle()
                    .fill(theme.divider)
                    .frame(height: 1)
                    .padding(.horizontal, -26)
            }
        }
    }
}

struct MaintenanceSectionTitle: View {
    let title: String
    let trailing: String?
    let trailingTint: Color?

    init(title: String, trailing: String? = nil, trailingTint: Color? = nil) {
        self.title = title
        self.trailing = trailing
        self.trailingTint = trailingTint
    }

    var body: some View {
        MaintenanceThemeReader { theme in
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(theme.primaryText)

                Spacer()

                if let trailing {
                    if let trailingTint {
                        Text(trailing)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(trailingTint)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(trailingTint.opacity(theme.isDark ? 0.18 : 0.12))
                            .clipShape(Capsule())
                    } else {
                        Text(trailing)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            }
        }
    }
}

struct MaintenancePanel<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        MaintenanceThemeReader { theme in
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(theme.panelFill)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(theme.panelStroke, lineWidth: 1)
                }
        }
    }
}

struct MaintenanceStatTile: View {
    let metric: MaintenanceInventoryMetric

    var body: some View {
        MaintenanceThemeReader { theme in
            MaintenancePanel(cornerRadius: 24) {
                VStack(spacing: 14) {
                    Image(systemName: metric.symbol)
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(metric.tint)

                    Text(metric.value)
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(metric.tint)

                    Text(metric.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 142)
            }
        }
    }
}

struct MaintenanceTheme {
    let isDark: Bool

    var screenBackground: Color {
        isDark ? Color(red: 0.04, green: 0.04, blue: 0.07) : Color(red: 0.96, green: 0.97, blue: 0.99)
    }

    var panelFill: Color {
        isDark ? Color.white.opacity(0.08) : Color.white
    }

    var panelStroke: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    var divider: Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }

    var hairline: Color {
        isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var primaryText: Color {
        isDark ? .white : Color(red: 0.10, green: 0.10, blue: 0.13)
    }

    var secondaryText: Color {
        isDark ? Color.white.opacity(0.58) : Color.black.opacity(0.46)
    }

    var tertiaryText: Color {
        isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.34)
    }

    let brandOrange = Color(red: 1.0, green: 0.67, blue: 0.06)

    var iconCircleFill: Color {
        isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.05)
    }
}

struct MaintenanceThemeReader<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: (MaintenanceTheme) -> Content

    var body: some View {
        content(MaintenanceTheme(isDark: colorScheme == .dark))
    }
}
