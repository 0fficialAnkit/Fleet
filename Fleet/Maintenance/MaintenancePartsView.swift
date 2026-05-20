//
//  MaintenancePartsView.swift
//  Fleet
//
//  Created by Codex on 20/05/26.
//

import SwiftUI

struct MaintenancePartsView: View {
    var body: some View {
        MaintenanceScreenContainer {
            MaintenanceSectionTitle(
                title: "Spare Parts",
                trailing: "3 low",
                trailingTint: Color(red: 1.0, green: 0.24, blue: 0.46)
            )

            HStack(spacing: 18) {
                ForEach(MaintenanceSampleData.inventoryMetrics) { metric in
                    MaintenanceStatTile(metric: metric)
                }
            }

            LowStockAlertCard()

            VStack(spacing: 18) {
                ForEach(MaintenanceSampleData.parts) { part in
                    MaintenancePartCard(part: part)
                }
            }
        }
    }
}

private struct LowStockAlertCard: View {
    var body: some View {
        MaintenanceThemeReader { theme in
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Low Stock Alerts")
                        .font(.system(size: 19, weight: .bold))
                }
                .foregroundStyle(Color(red: 1.0, green: 0.24, blue: 0.46))

                VStack(spacing: 18) {
                    ForEach(MaintenanceSampleData.inventoryAlerts) { alert in
                        HStack {
                            Text(alert.title)
                                .font(.system(size: 18, weight: .medium))
                            Spacer()
                            Text(alert.value)
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.24, blue: 0.46))
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 28)
            .background {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color(red: 0.28, green: 0.08, blue: 0.13).opacity(theme.isDark ? 0.82 : 0.10))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.24, blue: 0.46).opacity(theme.isDark ? 0.35 : 0.18), lineWidth: 1)
            }
        }
    }
}

private struct MaintenancePartCard: View {
    let part: MaintenancePart

    var body: some View {
        MaintenanceThemeReader { theme in
            MaintenancePanel(cornerRadius: 30) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 18) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(part.tint.opacity(theme.isDark ? 0.14 : 0.10))
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 23, weight: .medium))
                                    .foregroundStyle(part.tint)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(part.title)
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(theme.primaryText)

                            Text(part.code)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(part.quantity)
                                .font(.system(size: 23, weight: .bold))
                                .foregroundStyle(part.tint)

                            Text(part.unitLabel)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                        }
                    }

                    HStack(spacing: 14) {
                        Text(part.category)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(part.tint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(part.tint.opacity(theme.isDark ? 0.14 : 0.10))
                            .clipShape(Capsule())

                        Text(part.minimumText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.secondaryText)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.iconCircleFill)
                                .frame(height: 10)

                            Capsule()
                                .fill(part.tint)
                                .frame(width: proxy.size.width * part.progress, height: 10)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 24)
            }
            .overlay {
                if part.tint == Color(red: 1.0, green: 0.24, blue: 0.46) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(part.tint.opacity(theme.isDark ? 0.28 : 0.14), lineWidth: 1)
                }
            }
        }
    }
}

#Preview("Maintenance Parts") {
    MaintenancePartsView()
        .preferredColorScheme(.dark)
}
