import SwiftUI

struct WorkOrderDetailView: View {
    let workOrder: WorkOrder
    @State private var notes: String = ""
    @State private var currentStatus: WorkOrderStatus?

    init(workOrder: WorkOrder) {
        self.workOrder = workOrder
        _currentStatus = State(initialValue: workOrder.status)
    }

    var body: some View {
        ZStack {
            themeModel.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: themeModel.spacingLG) {

                    // MARK: - Status Banner
                    HStack(spacing: themeModel.spacingSM) {
                        Image(systemName: statusIcon(currentStatus))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(statusColor(currentStatus))
                        Text(statusLabel(currentStatus))
                            .font(themeModel.headline())
                            .foregroundStyle(statusColor(currentStatus))
                        Spacer()
                        StatusBadge(
                            text: priorityLabel(workOrder.priority),
                            color: priorityColor(workOrder.priority),
                            icon: priorityIcon(workOrder.priority)
                        )
                    }
                    .padding(themeModel.spacingMD)
                    .background(statusColor(currentStatus).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                            .stroke(statusColor(currentStatus).opacity(0.25), lineWidth: 1)
                    )

                    // MARK: - Details Section
                    GlassSection(title: "Order Details") {
                        InfoRow(icon: "number",         label: "Order ID",    value: "WO-\(workOrder.id.uuidString.prefix(8).uppercased())")
                        divider
                        InfoRow(icon: "car.fill",       label: "Vehicle ID",  value: "VH-\(workOrder.vehicleId.uuidString.prefix(8).uppercased())")
                        divider
                        InfoRow(icon: "flag.fill",      label: "Priority",    value: priorityLabel(workOrder.priority), valueColor: priorityColor(workOrder.priority))
                        divider
                        InfoRow(icon: "calendar",       label: "Created",     value: workOrder.createdAt.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "N/A")
                    }

                    // MARK: - Parts Used Section
                    GlassSection(title: "Parts Used") {
                        Button(action: {}) {
                            ActionRow(
                                icon: "plus.circle.fill",
                                title: "Add Part from Inventory",
                                iconColor: themeModel.maintenancePrimary
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().background(themeModel.divider)

                        PartRow(icon: "gearshape.2.fill", name: "Brake Pads (Front)", qty: 2, color: themeModel.maintenancePrimary)
                        Divider().background(themeModel.divider)
                        PartRow(icon: "drop.fill",        name: "Engine Oil (5W-30)", qty: 4, color: themeModel.info)
                    }

                    // MARK: - Labor & Notes Section
                    GlassSection(title: "Labor & Notes") {
                        HStack(spacing: themeModel.spacingMD) {
                            LaborStat(label: "Est. Hours", value: "3.5 hrs", icon: "clock.fill",  color: themeModel.info)
                            LaborStat(label: "Labor Cost",  value: "$210",    icon: "dollarsign",  color: themeModel.success)
                        }

                        Divider().background(themeModel.divider)

                        TextField("Add service details, notes or observations...", text: $notes, axis: .vertical)
                            .lineLimit(4...8)
                            .font(themeModel.body())
                            .foregroundStyle(themeModel.textPrimary)
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: themeModel.spacingMD) {
                        if currentStatus != .completed {
                            ActionButton(
                                title: "Mark as Completed",
                                icon: "checkmark.circle.fill",
                                color: themeModel.success
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentStatus = .completed
                                }
                            }
                        }

                        if currentStatus == .completed {
                            ActionButton(
                                title: "Reopen Order",
                                icon: "arrow.counterclockwise.circle.fill",
                                color: themeModel.warning
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentStatus = .inProgress
                                }
                            }
                        }

                        if currentStatus != .cancelled {
                            ActionButton(
                                title: "Cancel Order",
                                icon: "xmark.circle",
                                color: themeModel.danger
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentStatus = .cancelled
                                }
                            }
                        }
                    }
                }
                .padding(themeModel.spacingMD)
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var divider: some View {
        Divider().background(themeModel.divider)
    }

    // MARK: - Helpers
    func statusIcon(_ status: WorkOrderStatus?) -> String {
        switch status {
        case .open:       return "tray.circle"
        case .inProgress: return "wrench.adjustable"
        case .completed:  return "checkmark.circle.fill"
        case .cancelled:  return "xmark.circle.fill"
        case .none:       return "tray.circle"
        }
    }

    func statusLabel(_ status: WorkOrderStatus?) -> String {
        switch status {
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        case .none:       return "Unknown"
        }
    }

    func statusColor(_ status: WorkOrderStatus?) -> Color {
        switch status {
        case .open:       return themeModel.info
        case .inProgress: return themeModel.warning
        case .completed:  return themeModel.success
        case .cancelled:  return themeModel.danger
        case .none:       return themeModel.textSecondary
        }
    }

    func priorityLabel(_ priority: WorkOrderPriority?) -> String {
        switch priority {
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .critical: return "Critical"
        case .none:     return "N/A"
        }
    }

    func priorityIcon(_ priority: WorkOrderPriority?) -> String {
        switch priority {
        case .low:      return "arrow.down.circle"
        case .medium:   return "minus.circle"
        case .high:     return "arrow.up.circle"
        case .critical: return "exclamationmark.2"
        case .none:     return "minus.circle"
        }
    }

    func priorityColor(_ priority: WorkOrderPriority?) -> Color {
        switch priority {
        case .critical: return themeModel.danger
        case .high:     return themeModel.warning
        case .medium:   return themeModel.info
        case .low:      return themeModel.success
        case .none:     return themeModel.textSecondary
        }
    }
}

// MARK: - GlassSection
private struct GlassSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            SectionHeader(title: title)

            VStack(spacing: themeModel.spacingMD) {
                content()
            }
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
        }
    }
}

// MARK: - Part Row
private struct PartRow: View {
    let icon: String
    let name: String
    let qty: Int
    let color: Color

    var body: some View {
        HStack(spacing: themeModel.spacingMD) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(name)
                .font(themeModel.body())
                .foregroundStyle(themeModel.textPrimary)
            Spacer()
            Text("×\(qty)")
                .font(themeModel.bodyMedium())
                .foregroundStyle(themeModel.textSecondary)
        }
    }
}

// MARK: - Labor Stat
private struct LaborStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: themeModel.spacingSM) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(themeModel.headline())
                    .foregroundStyle(themeModel.textPrimary)
                Text(label)
                    .font(themeModel.caption())
                    .foregroundStyle(themeModel.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(themeModel.spacingMD)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
    }
}

// MARK: - Action Button
private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: themeModel.spacingSM) {
                Image(systemName: icon)
                Text(title)
            }
            .font(themeModel.headline())
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(themeModel.spacingMD)
            .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.15), radius: 8, y: 4)
        }
    }
}

#Preview {
    NavigationStack {
        WorkOrderDetailView(workOrder: WorkOrder(
            id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(),
            priority: .high, status: .inProgress, createdAt: Date()
        ))
    }
}
