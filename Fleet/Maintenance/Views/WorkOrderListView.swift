import SwiftUI

struct WorkOrderListView: View {
    @State private var selectedFilter: WorkOrderStatus? = nil
    @State private var showNewOrderSheet = false

    // Dummy Data based on DataModel
    let workOrders = [
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high,     status: .open,       createdAt: Date().addingTimeInterval(-86400)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .medium,   status: .inProgress, createdAt: Date().addingTimeInterval(-172800)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .critical, status: .open,       createdAt: Date().addingTimeInterval(-43200)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .low,      status: .completed,  createdAt: Date().addingTimeInterval(-259200)),
        WorkOrder(id: UUID(), vehicleId: UUID(), createdBy: UUID(), assignedTo: UUID(), priority: .high,     status: .cancelled,  createdAt: Date().addingTimeInterval(-345600))
    ]

    var filteredOrders: [WorkOrder] {
        guard let filter = selectedFilter else { return workOrders }
        return workOrders.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: themeModel.spacingMD) {

                        // MARK: - Summary Strip
                        HStack(spacing: themeModel.spacingMD) {
                            MiniStatBadge(
                                count: workOrders.filter { $0.status == .open }.count,
                                label: "Open",
                                color: themeModel.info
                            )
                            MiniStatBadge(
                                count: workOrders.filter { $0.status == .inProgress }.count,
                                label: "In Progress",
                                color: themeModel.warning
                            )
                            MiniStatBadge(
                                count: workOrders.filter { $0.status == .completed }.count,
                                label: "Done",
                                color: themeModel.success
                            )
                        }
                        .padding(.horizontal, themeModel.spacingMD)

                        // MARK: - Filter Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: themeModel.spacingSM) {
                                FilterChip(label: "All",        isSelected: selectedFilter == nil,              color: themeModel.maintenancePrimary) { selectedFilter = nil }
                                FilterChip(label: "Open",       isSelected: selectedFilter == .open,            color: themeModel.info)     { selectedFilter = .open }
                                FilterChip(label: "In Progress",isSelected: selectedFilter == .inProgress,      color: themeModel.warning)  { selectedFilter = .inProgress }
                                FilterChip(label: "Completed",  isSelected: selectedFilter == .completed,       color: themeModel.success)  { selectedFilter = .completed }
                                FilterChip(label: "Cancelled",  isSelected: selectedFilter == .cancelled,       color: themeModel.danger)   { selectedFilter = .cancelled }
                            }
                            .padding(.horizontal, themeModel.spacingMD)
                        }

                        // MARK: - Order List
                        if filteredOrders.isEmpty {
                            VStack(spacing: themeModel.spacingMD) {
                                Image(systemName: "tray")
                                    .font(.system(size: 44))
                                    .foregroundStyle(themeModel.textTertiary)
                                Text("No orders found")
                                    .font(themeModel.bodyMedium())
                                    .foregroundStyle(themeModel.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, themeModel.spacingXXL)
                        } else {
                            LazyVStack(spacing: themeModel.spacingMD) {
                                ForEach(filteredOrders) { order in
                                    NavigationLink(destination: WorkOrderDetailView(workOrder: order)) {
                                        WorkOrderRow(workOrder: order)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, themeModel.spacingMD)
                        }
                    }
                    .padding(.vertical, themeModel.spacingMD)
                }
            }
            .navigationTitle("Work Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewOrderSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(themeModel.maintenancePrimary)
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }
}

// MARK: - Mini Stat Badge
private struct MiniStatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(themeModel.title(20))
                .foregroundStyle(color)
            Text(label)
                .font(themeModel.small())
                .foregroundStyle(themeModel.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusMD, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.8)
        )
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(themeModel.caption())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? color : themeModel.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.15) : themeModel.surfaceSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Work Order Row
struct WorkOrderRow: View {
    let workOrder: WorkOrder

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                // Priority Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(priorityColor(workOrder.priority))
                        .frame(width: 8, height: 8)
                    Text("WO-\(workOrder.id.uuidString.prefix(6).uppercased())")
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                }
                Spacer()
                StatusBadge(
                    text: statusLabel(workOrder.status),
                    color: statusColor(workOrder.status)
                )
            }

            HStack {
                Label {
                    Text(priorityLabel(workOrder.priority))
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textSecondary)
                } icon: {
                    Image(systemName: priorityIcon(workOrder.priority))
                        .foregroundStyle(priorityColor(workOrder.priority))
                }

                Spacer()

                if let date = workOrder.createdAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(themeModel.textTertiary)
                        Text(date, style: .relative)
                            .font(themeModel.caption())
                            .foregroundStyle(themeModel.textTertiary)
                    }
                }
            }
        }
        .padding(themeModel.spacingMD)
        .glassEffect(in: RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: themeModel.radiusLG, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: themeModel.shadowPrimary, radius: 8, y: 4)
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
        case .low:      return "Low Priority"
        case .medium:   return "Medium Priority"
        case .high:     return "High Priority"
        case .critical: return "Critical"
        case .none:     return "Unknown"
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

#Preview {
    WorkOrderListView()
}
