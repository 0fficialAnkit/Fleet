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
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading && workOrders.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        VStack(spacing: 16) {

                            // MARK: - Summary Strip
                            HStack(spacing: 16) {
                                MiniStatBadge(
                                    count: workOrders.filter { $0.unifiedStatus == .open }.count,
                                    label: "Open",
                                    color: Color.blue
                                )
                                MiniStatBadge(
                                    count: workOrders.filter { $0.unifiedStatus == .inProgress }.count,
                                    label: "In Progress",
                                    color: Color.yellow
                                )
                                MiniStatBadge(
                                    count: workOrders.filter { $0.unifiedStatus == .completed }.count,
                                    label: "Done",
                                    color: Color.green
                                )
                            }
                            .padding(.horizontal, 16)

                            // MARK: - Filter Picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "All",        isSelected: selectedFilter == nil,              color: Color.brown) { selectedFilter = nil }
                                    FilterChip(label: "Open",       isSelected: selectedFilter == .open,            color: Color.blue)     { selectedFilter = .open }
                                    FilterChip(label: "In Progress",isSelected: selectedFilter == .inProgress,      color: Color.yellow)  { selectedFilter = .inProgress }
                                    FilterChip(label: "Completed",  isSelected: selectedFilter == .completed,       color: Color.green)  { selectedFilter = .completed }
                                    FilterChip(label: "Cancelled",  isSelected: selectedFilter == .cancelled,       color: Color.red)   { selectedFilter = .cancelled }
                                }
                                .padding(.horizontal, 16)
                            }

                            // MARK: - Order List
                            if filteredOrders.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 44))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                    Text("No orders found")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredOrders) { item in
                                        NavigationLink(value: getDestination(for: item)) {
                                            UnifiedWorkItemRow(item: item)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Work Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewOrderSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.brown)
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
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                .font(.footnote)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? color : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Priority Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(priorityColor(item.unifiedPriority))
                        .frame(width: 8, height: 8)
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
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
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                } icon: {
                    Image(systemName: priorityIcon(item.unifiedPriority))
                        .foregroundStyle(priorityColor(item.unifiedPriority))
                }

                Spacer()

                if let date = item.createdAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text(date, style: .relative)
                            .font(.footnote)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )

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
        case .open:       return Color.blue
        case .inProgress: return Color.yellow
        case .completed:  return Color.green
        case .cancelled:  return Color.red
        case .none:       return Color.secondary
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
        case .critical: return Color.red
        case .high:     return Color.yellow
        case .medium:   return Color.blue
        case .low:      return Color.green
        case .none:     return Color.secondary
        }
    }
}

#Preview {
    WorkOrderListView()
}