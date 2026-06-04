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
        VStack(spacing: 0) {
            // Metrics Summary Grid
            HStack(spacing: 12) {
                MetricCard(
                    icon: "tray.fill",
                    value: "\(workOrders.filter { $0.unifiedStatus == .open }.count)",
                    label: "Open",
                    color: Color.blue
                )
                MetricCard(
                    icon: "wrench.adjustable.fill",
                    value: "\(workOrders.filter { $0.unifiedStatus == .inProgress }.count)",
                    label: "In Progress",
                    color: Color.orange
                )
                MetricCard(
                    icon: "checkmark.circle.fill",
                    value: "\(workOrders.filter { $0.unifiedStatus == .completed }.count)",
                    label: "Done",
                    color: Color.green
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Segmented Picker for status filtering
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(nil as WorkOrderStatus?)
                Text("Pending").tag(WorkOrderStatus.pending as WorkOrderStatus?)
                Text("Open").tag(WorkOrderStatus.open as WorkOrderStatus?)
                Text("In Progress").tag(WorkOrderStatus.inProgress as WorkOrderStatus?)
                Text("Done").tag(WorkOrderStatus.completed as WorkOrderStatus?)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if isLoading && workOrders.isEmpty {
                Spacer()
                ProgressView()
                    .tint(.brown)
                Spacer()
            } else {
                List {
                    if filteredOrders.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color(.tertiaryLabel))
                                Text("No orders found")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                    } else {
                        ForEach(filteredOrders) { item in
                            NavigationLink(value: getDestination(for: item)) {
                                UnifiedWorkItemRow(item: item, vehicles: vehicles)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await loadWorkOrders() }
            }
        }
        .background(Color(.systemGroupedBackground))
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
                rawIRs = try await IssueReportService.fetchAllIssueReports()
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
    let vehicles: [Vehicle]

    var vehiclePlate: String {
        vehicles.first(where: { $0.id == item.vehicleId })?.licensePlate ?? "Unknown Vehicle"
    }
    
    var vehicleModel: String {
        if let v = vehicles.first(where: { $0.id == item.vehicleId }) {
            let make = v.make ?? ""
            let model = v.model ?? ""
            return "\(make) \(model)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    var iconName: String {
        switch item {
        case .issueReport: return "exclamationmark.triangle.fill"
        case .workOrder: return "wrench.and.screwdriver.fill"
        }
    }

    var priorityColor: Color {
        switch item.unifiedPriority {
        case .critical, .high: return Color.red
        case .medium: return Color.orange
        case .low: return Color.blue
        case nil: return Color.secondary
        }
    }

    var priorityLabel: String {
        switch item.unifiedPriority {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case nil: return "Normal"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Native-looking Left Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(priorityColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(priorityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                // Vehicle Plate
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(vehiclePlate)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    
                    if !vehicleModel.isEmpty {
                        Text("· \(vehicleModel)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(1)
                    }
                }
                
                // Issue / WO Type
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status & Priority Badge
            VStack(alignment: .trailing, spacing: 6) {
                if let status = item.unifiedStatus {
                    StatusBadge(text: statusLabel(status), color: statusColor(status))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(priorityLabel)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(priorityColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(priorityColor.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    func statusLabel(_ status: WorkOrderStatus) -> String {
        switch status {
        case .pending:    return "Pending"
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .completed:  return "Done"
        case .cancelled:  return "Cancelled"
        }
    }

    func statusColor(_ status: WorkOrderStatus) -> Color {
        switch status {
        case .pending:    return Color.gray
        case .open:       return Color.blue
        case .inProgress: return Color.orange
        case .completed:  return Color.green
        case .cancelled:  return Color.red
        }
    }
}


#Preview {
    WorkOrderListView()
}