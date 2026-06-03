import SwiftUI

struct WorkOrderListView: View {
    @State private var selectedFilter: WorkOrderStatus? = nil
    @State private var showNewOrderSheet = false
    @State private var workOrders: [UnifiedMaintenanceItem] = []
    @State private var vehicles: [Vehicle] = []
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
        Group {
            if isLoading && workOrders.isEmpty {
                ProgressView()
                    .tint(.brown)
            } else {
                List {
                    // MARK: - Summary Strip
                    Section {
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
                    }

                    // MARK: - Filter Picker
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All",        isSelected: selectedFilter == nil,              color: Color.brown) { selectedFilter = nil }
                                FilterChip(label: "Pending",    isSelected: selectedFilter == .pending,         color: Color.gray)    { selectedFilter = .pending }
                                FilterChip(label: "Open",       isSelected: selectedFilter == .open,            color: Color.blue)     { selectedFilter = .open }
                                FilterChip(label: "In Progress",isSelected: selectedFilter == .inProgress,      color: Color.yellow)  { selectedFilter = .inProgress }
                                FilterChip(label: "Completed",  isSelected: selectedFilter == .completed,       color: Color.green)  { selectedFilter = .completed }
                                FilterChip(label: "Cancelled",  isSelected: selectedFilter == .cancelled,       color: Color.red)   { selectedFilter = .cancelled }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // MARK: - Order List
                    Section {
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
                            ForEach(filteredOrders) { item in
                                NavigationLink(value: getDestination(for: item)) {
                                    UnifiedWorkItemRow(item: item)
                                }
                            }
                        }
                    }
                }
                .refreshable { await loadWorkOrders() }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Work Orders")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewOrderSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .task {
            await loadWorkOrders()
        }
    }

    private func getDestination(for item: UnifiedMaintenanceItem) -> MaintenanceDestination {
        switch item {
        case .workOrder(let wo):
            let vehicle = vehicles.first { $0.id == wo.vehicleId }
            let swo = ScheduledWorkOrder(
                id: wo.id,
                vehicleNumber: vehicle?.licensePlate ?? "Unknown",
                vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
                priority: wo.priority ?? .medium,
                status: wo.status ?? .open,
                createdAt: wo.createdAt ?? Date(),
                assignedBy: "Fleet Manager",
                laborHours: "—",
                laborCost: "—",
                notes: "",
                partsUsed: [],
                sourceWorkOrderId: wo.id,
                vehicleIssue: "Scheduled maintenance / Service required."
            )
            return .scheduledWorkOrderDetail(swo)
        case .issueReport(let ir):
            let vehicle = vehicles.first { $0.id == ir.vehicleId }
            let priority: WorkOrderPriority = {
                switch ir.severity.lowercased() {
                case "critical": return .critical
                case "high":     return .high
                case "medium":   return .medium
                case "low":      return .low
                default:         return .medium
                }
            }()
            let status: WorkOrderStatus = {
                switch ir.status.lowercased() {
                case "open", "assigned": return .open
                case "in_progress":      return .inProgress
                case "resolved", "closed": return .completed
                default:                 return .open
                }
            }()
            let swo = ScheduledWorkOrder(
                id: ir.id,
                vehicleNumber: vehicle?.licensePlate ?? "Unknown",
                vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
                priority: priority,
                status: status,
                createdAt: ir.createdAt ?? Date(),
                assignedBy: "Driver Report",
                laborHours: "—",
                laborCost: "—",
                notes: ir.description ?? "",
                partsUsed: [],
                sourceWorkOrderId: nil,
                sourceIssueReportId: ir.id,
                vehicleIssue: ir.description ?? "Issue reported by driver."
            )
            return .scheduledWorkOrderDetail(swo)
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
            }

            vehicles = (try? await VehicleService.fetchAllVehicles()) ?? []

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
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(.vertical, 4)
    }

    func statusLabel(_ status: WorkOrderStatus?) -> String {
        switch status {
        case .pending:    return "Pending"
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        case .none:       return "Unknown"
        }
    }

    func statusColor(_ status: WorkOrderStatus?) -> Color {
        switch status {
        case .pending:    return Color.gray
        case .open:       return Color.blue
        case .inProgress: return Color.orange
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
        case .high:     return Color.orange
        case .medium:   return Color.blue
        case .low:      return Color.green
        case .none:     return Color.secondary
        }
    }
}

#Preview {
    WorkOrderListView()
}