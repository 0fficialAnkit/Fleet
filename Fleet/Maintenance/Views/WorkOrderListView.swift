import SwiftUI

struct WorkOrderListView: View {
    @State private var selectedFilter: WorkOrderStatus? = nil
    @State private var workOrders: [UnifiedMaintenanceItem] = []
    @State private var vehicles:   [Vehicle]               = []
    @State private var isLoading   = false
    @State private var errorMessage: String?

    let assignedUserId: UUID?
    let priorityFilter: WorkOrderPriority?

    init(initialFilter: WorkOrderStatus? = nil,
         assignedUserId: UUID? = nil,
         priorityFilter: WorkOrderPriority? = nil) {
        self.assignedUserId = assignedUserId
        self.priorityFilter = priorityFilter
        self._selectedFilter = State(initialValue: initialFilter)
    }

    // MARK: - Computed
    var filteredOrders: [UnifiedMaintenanceItem] {
        guard let filter = selectedFilter else { return workOrders }
        return workOrders.filter { $0.unifiedStatus == filter }
    }

    var openCount:       Int { workOrders.filter { $0.unifiedStatus == .open       }.count }
    var inProgressCount: Int { workOrders.filter { $0.unifiedStatus == .inProgress }.count }
    var doneCount:       Int { workOrders.filter { $0.unifiedStatus == .completed  }.count }

    var body: some View {
        Group {
            if isLoading && workOrders.isEmpty {
                ProgressView().tint(.brown)
            } else {
                List {
                    // ── KPI summary ──────────────────────────────────────
                    Section {
                        HStack(spacing: 0) {
                            woKpi("\(openCount)",       "Open",        .blue)
                            Divider().frame(height: 36)
                            woKpi("\(inProgressCount)", "In Progress", .orange)
                            Divider().frame(height: 36)
                            woKpi("\(doneCount)",       "Done",        .green)
                        }
                        .padding(.vertical, 4)
                    }

                    // ── Filter picker ────────────────────────────────────
                    Section {
                        Picker("Filter", selection: $selectedFilter) {
                            Text("All").tag(nil as WorkOrderStatus?)
                            Text("Pending").tag(WorkOrderStatus.pending    as WorkOrderStatus?)
                            Text("Open").tag(WorkOrderStatus.open          as WorkOrderStatus?)
                            Text("In Progress").tag(WorkOrderStatus.inProgress as WorkOrderStatus?)
                            Text("Done").tag(WorkOrderStatus.completed     as WorkOrderStatus?)
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // ── Orders ────────────────────────────────────────────
                    if filteredOrders.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "No Work Orders",
                                systemImage: "tray",
                                description: Text(selectedFilter == nil
                                    ? "No work orders found."
                                    : "No orders match this filter.")
                            )
                            .listRowBackground(Color.clear)
                        }
                    } else {
                        Section {
                            ForEach(filteredOrders) { item in
                                NavigationLink(value: getDestination(for: item)) {
                                    UnifiedWorkItemRow(item: item, vehicles: vehicles)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await loadWorkOrders() }
            }
        }
        .navigationTitle("Work Orders")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // Placeholder — actual add sheet can be wired here
                EmptyView()
            }
        }
        .task { await loadWorkOrders() }
    }

    // MARK: - KPI cell
    private func woKpi(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigation destination (logic unchanged)
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
                laborHours: "—", laborCost: "—", notes: "",
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
                priority: priority, status: status,
                createdAt: ir.createdAt ?? Date(),
                assignedBy: "Driver Report",
                laborHours: "—", laborCost: "—",
                notes: ir.description ?? "",
                partsUsed: [],
                sourceWorkOrderId: nil,
                sourceIssueReportId: ir.id,
                vehicleIssue: ir.description ?? "Issue reported by driver."
            )
            return .scheduledWorkOrderDetail(swo)
        }
    }

    // MARK: - Load (logic unchanged)
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

// MARK: - Unified Work Item Row (cleaned up)
struct UnifiedWorkItemRow: View {
    let item:     UnifiedMaintenanceItem
    let vehicles: [Vehicle]

    var vehicle: Vehicle? { vehicles.first { $0.id == item.vehicleId } }

    var vehiclePlate: String { vehicle?.licensePlate ?? "Unknown" }
    var vehicleModel: String {
        guard let v = vehicle else { return "" }
        return "\(v.make ?? "") \(v.model ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var icon: String {
        switch item {
        case .issueReport: return "exclamationmark.triangle.fill"
        case .workOrder:   return "wrench.and.screwdriver.fill"
        }
    }

    var priorityColor: Color {
        switch item.unifiedPriority {
        case .critical, .high: return .red
        case .medium:          return .orange
        case .low:             return .blue
        case nil:              return .secondary
        }
    }

    var priorityLabel: String {
        switch item.unifiedPriority {
        case .critical: return "Critical"
        case .high:     return "High"
        case .medium:   return "Medium"
        case .low:      return "Low"
        case nil:       return "Normal"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(priorityColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(priorityColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(vehiclePlate)
                        .font(.subheadline.weight(.semibold))
                    if !vehicleModel.isEmpty {
                        Text("· \(vehicleModel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let status = item.unifiedStatus {
                    StatusBadge(text: statusLabel(status), color: statusColor(status))
                }
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(priorityLabel)
                        .font(.caption.bold())
                }
                .foregroundStyle(priorityColor)
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
        case .pending:    return .gray
        case .open:       return .blue
        case .inProgress: return .orange
        case .completed:  return .green
        case .cancelled:  return .red
        }
    }
}

#Preview {
    NavigationStack {
        WorkOrderListView()
    }
}
