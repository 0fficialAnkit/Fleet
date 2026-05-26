import SwiftUI

struct WorkOrderListView: View {
    @State private var selectedFilter: WorkOrderStatus? = nil
    @State private var showNewOrderSheet = false
    @State private var workOrders: [UnifiedMaintenanceItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let assignedUserId: UUID?
    let priorityFilter: WorkOrderPriority?
    
    init(initialFilter: WorkOrderStatus? = nil, assignedUserId: UUID? = nil, priorityFilter: WorkOrderPriority? = nil) {
        self.assignedUserId = assignedUserId
        self.priorityFilter = priorityFilter
        self._selectedFilter = State(initialValue: initialFilter)
    }

    var filteredOrders: [UnifiedMaintenanceItem] {
        guard let filter = selectedFilter else { return workOrders }
        return workOrders.filter { $0.unifiedStatus == filter }
    }

    var body: some View {
        ZStack {
                themeModel.backgroundPrimary.ignoresSafeArea()

                if isLoading && workOrders.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        VStack(spacing: themeModel.spacingMD) {

                            // MARK: - Summary Strip
                            HStack(spacing: themeModel.spacingMD) {
                                MiniStatBadge(
                                    count: workOrders.filter { $0.unifiedStatus == .open }.count,
                                    label: "Open",
                                    color: themeModel.info
                                )
                                MiniStatBadge(
                                    count: workOrders.filter { $0.unifiedStatus == .inProgress }.count,
                                    label: "In Progress",
                                    color: themeModel.warning
                                )
                                MiniStatBadge(
                                    count: workOrders.filter { $0.unifiedStatus == .completed }.count,
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
                                    ForEach(filteredOrders) { item in
                                        NavigationLink(value: getDestination(for: item)) {
                                            UnifiedWorkItemRow(item: item)
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
            .task {
                await loadWorkOrders()
            }
        }
    

    private func getDestination(for item: UnifiedMaintenanceItem) -> MaintenanceDestination {
        switch item {
        case .workOrder(let wo): return .workOrderDetail(wo)
        case .issueReport(let ir): return .issueReportDetail(ir)
        }
    }

    private func loadWorkOrders() async {
        isLoading = true
        do {
            var rawWOs: [WorkOrder] = []
            var rawIRs: [IssueReportRecord] = []
            
            if let assignedTo = assignedUserId {
                rawWOs = try await WorkOrderService.fetchWorkOrdersForUser(assignedTo: assignedTo)
                rawIRs = try await IssueReportService.fetchIssueReportsAssignedTo(userId: assignedTo)
            } else {
                rawWOs = try await WorkOrderService.fetchAllWorkOrders()
                // If no user ID, fetch all reports? Or just leave empty for now
            }
            
            var unified = rawWOs.map { UnifiedMaintenanceItem.workOrder($0) } +
                          rawIRs.map { UnifiedMaintenanceItem.issueReport($0) }
            
            if let pFilter = priorityFilter {
                unified = unified.filter { $0.unifiedPriority == pFilter }
            }
            
            workOrders = unified
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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

// MARK: - Unified Work Item Row
struct UnifiedWorkItemRow: View {
    let item: UnifiedMaintenanceItem

    var body: some View {
        VStack(alignment: .leading, spacing: themeModel.spacingMD) {
            HStack {
                // Priority Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(priorityColor(item.unifiedPriority))
                        .frame(width: 8, height: 8)
                    Text(item.title)
                        .font(themeModel.headline())
                        .foregroundStyle(themeModel.textPrimary)
                }
                Spacer()
                StatusBadge(
                    text: statusLabel(item.unifiedStatus),
                    color: statusColor(item.unifiedStatus)
                )
            }

            HStack {
                Label {
                    Text(priorityLabel(item.unifiedPriority))
                        .font(themeModel.bodyMedium())
                        .foregroundStyle(themeModel.textSecondary)
                } icon: {
                    Image(systemName: priorityIcon(item.unifiedPriority))
                        .foregroundStyle(priorityColor(item.unifiedPriority))
                }

                Spacer()

                if let date = item.createdAt {
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
