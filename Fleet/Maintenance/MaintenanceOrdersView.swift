//
//  MaintenanceOrdersView.swift
//  Fleet
//
//  Created by Codex on 20/05/26.
//

import SwiftUI

struct MaintenanceOrdersView: View {
    var body: some View {
        MaintenanceScreenContainer {
            MaintenanceSectionTitle(title: "Work Orders", trailing: "5 total")

            HStack(spacing: 14) {
                orderStatusTile(value: "1", label: "To Do", isActive: false)
                orderStatusTile(value: "2", label: "In Progress", isActive: true)
                orderStatusTile(value: "2", label: "Done", isActive: false)
            }

            VStack(spacing: 18) {
                ForEach(MaintenanceSampleData.workOrders) { order in
                    MaintenanceOrderCard(order: order)
                }
            }
        }
    }

    private func orderStatusTile(value: String, label: String, isActive: Bool) -> some View {
        MaintenanceThemeReader { theme in
            VStack(spacing: 10) {
                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(isActive ? theme.brandOrange : theme.secondaryText)

                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isActive ? theme.brandOrange : theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 106)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isActive ? theme.brandOrange.opacity(theme.isDark ? 0.18 : 0.12) : theme.panelFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isActive ? theme.brandOrange : theme.panelStroke, lineWidth: isActive ? 2 : 1)
            }
        }
    }
}

private struct MaintenanceOrderCard: View {
    let order: MaintenanceWorkOrder

    var body: some View {
        MaintenanceThemeReader { theme in
            MaintenancePanel(cornerRadius: 30) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top, spacing: 14) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(theme.brandOrange.opacity(theme.isDark ? 0.18 : 0.12))
                            .frame(width: 52, height: 52)
                            .overlay {
                                Image(systemName: "wrench.and.screwdriver")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(theme.brandOrange)
                            }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(order.title)
                                .font(.system(size: 19, weight: .bold))
                                .foregroundStyle(theme.primaryText)

                            Text("\(order.code) · \(order.vehicle)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.secondaryText)
                        }

                        Spacer()

                        Text(order.priority)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(order.priorityTint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(order.priorityTint.opacity(theme.isDark ? 0.15 : 0.10))
                            .clipShape(Capsule())
                    }

                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                            Text("Est: \(order.estimate)")
                            Text("·")
                            Text(order.assignee)
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.secondaryText)

                        Spacer()

                        HStack(spacing: 10) {
                            actionPill(text: "To", tint: theme.secondaryText, fill: theme.iconCircleFill)
                            actionPill(text: "Done", tint: Color(red: 0.20, green: 0.91, blue: 0.38), fill: Color(red: 0.20, green: 0.91, blue: 0.38).opacity(theme.isDark ? 0.16 : 0.10))
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 24)
            }
        }
    }

    private func actionPill(text: String, tint: Color, fill: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(fill)
        .clipShape(Capsule())
    }
}

#Preview("Maintenance Orders") {
    MaintenanceOrdersView()
        .preferredColorScheme(.dark)
}
