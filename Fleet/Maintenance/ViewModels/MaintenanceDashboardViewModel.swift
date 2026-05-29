import SwiftUI

@MainActor
@Observable
final class MaintenanceDashboardViewModel {
    private(set) var tasks: [MaintenanceTask] = []
    private(set) var workOrders: [WorkOrder] = []
    private(set) var issueReports: [IssueReportRecord] = []
    private(set) var inventory: [Inventory] = []
    private(set) var vehicles: [Vehicle] = []

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    var pendingTasks: Int {
        tasks.filter { $0.status == .pending }.count
    }

    var inProgressTasks: Int {
        tasks.filter { $0.status == .inProgress }.count
    }

    var completedToday: Int {
        tasks.filter { $0.status == .completed }.count
    }

    var lowStockItemsCount: Int {
        inventory.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
    }

    var upcomingItems: [UpcomingDisplayItem] {
        var items: [UpcomingDisplayItem] = []

        let tItems = tasks.filter { $0.status != .completed }.map { task -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: task.id,
                priorityLabel: nil,
                priorityColor: nil,
                referenceId: "TSK-\(task.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "SCHEDULED",
                vehicleName: vehiclePlate(for: task.vehicleId),
                taskDescription: taskTypeString(for: task.taskType),
                estimatedDuration: "1h 30m",
                location: "Bay 01",
                actionButtonTitle: "Start Task",
                actionButtonIcon: "play.fill",
                destination: nil,
                isTask: true
            )
        }
        items.append(contentsOf: tItems)

        let woItems = workOrders.filter { $0.status != .completed && $0.status != .cancelled }.map { wo -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: wo.id,
                priorityLabel: woPriorityLabel(wo.priority),
                priorityColor: woPriorityColor(wo.priority),
                referenceId: "WO-\(wo.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "ASSIGNED TO YOU",
                vehicleName: vehiclePlate(for: wo.vehicleId),
                taskDescription: "Work Order Execution",
                estimatedDuration: "2h 30m",
                location: "Bay 04",
                actionButtonTitle: "Start Work",
                actionButtonIcon: "play.fill",
                destination: .workOrderDetail(wo),
                isTask: false
            )
        }
        items.append(contentsOf: woItems)

        let irItems = issueReports.filter { $0.status.lowercased() != "resolved" && $0.status.lowercased() != "closed" }.map { ir -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: ir.id,
                priorityLabel: ir.severity.uppercased(),
                priorityColor: irStatusColor(ir.severity), // We use severity color
                referenceId: "REP-\(ir.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "ASSIGNED TO YOU",
                vehicleName: vehiclePlate(for: ir.vehicleId),
                taskDescription: ir.category + (ir.description?.isEmpty == false ? " - \(ir.description!)" : ""),
                estimatedDuration: "1h 00m",
                location: "Bay 02",
                actionButtonTitle: "Start Repair",
                actionButtonIcon: "play.fill",
                destination: .issueReportDetail(ir),
                isTask: false
            )
        }
        items.append(contentsOf: irItems)

        return Array(items.prefix(3))
    }

    var unifiedItems: [UnifiedMaintenanceItem] {
        let woItems = workOrders.map { UnifiedMaintenanceItem.workOrder($0) }
        let irItems = issueReports.map { UnifiedMaintenanceItem.issueReport($0) }
        return woItems + irItems
    }

    var priorityQueueItems: [UnifiedMaintenanceItem] {
        unifiedItems
            .filter { $0.unifiedStatus == .open || $0.unifiedStatus == .inProgress }
            .sorted { (a, b) -> Bool in
                let priorityScore: [WorkOrderPriority: Int] = [.critical: 4, .high: 3, .medium: 2, .low: 1]
                let scoreA = priorityScore[a.unifiedPriority ?? .low] ?? 0
                let scoreB = priorityScore[b.unifiedPriority ?? .low] ?? 0
                return scoreA > scoreB
            }
            .prefix(3)
            .map { $0 }
    }

    var openWorkOrders: Int {
        unifiedItems.filter { $0.unifiedStatus == .open || $0.unifiedStatus == .inProgress }.count
    }

    var criticalRepairsCount: Int {
        unifiedItems.filter { $0.unifiedPriority == .critical && ($0.unifiedStatus == .open || $0.unifiedStatus == .inProgress) }.count
    }

    var availablePartsPercentage: Int {
        let total = inventory.count
        if total == 0 { return 100 }
        let lowStock = inventory.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
        let available = total - lowStock
        return Int((Double(available) / Double(total)) * 100)
    }

    var estimatedValue: Double {
        inventory.reduce(0) { $0 + (($1.unitCost ?? 0) * Double($1.stockQuantity ?? 0)) }
    }

    var estimatedValueFormatted: String {
        let value = estimatedValue
        if value >= 100_000 {
            return "₹\(String(format: "%.1fL", value / 100_000))"
        } else if value >= 1_000 {
            return "₹\(String(format: "%.1fK", value / 1_000))"
        } else {
            return "₹\(String(format: "%.0f", value))"
        }
    }

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let t = MaintenanceTaskService.fetchTasksForUser(assignedTo: userId)
            async let w = WorkOrderService.fetchWorkOrdersForUser(assignedTo: userId)
            async let ir = IssueReportService.fetchIssueReportsAssignedTo(userId: userId)
            async let i = InventoryService.fetchAllInventory()
            async let v = VehicleService.fetchAllVehicles()
            tasks = try await t
            workOrders = try await w
            issueReports = try await ir
            inventory = try await i
            vehicles = try await v
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addMaintenanceTasksChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addWorkOrdersChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addInventoryChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    func vehiclePlate(for vehicleId: UUID) -> String {
        vehicles.first(where: { $0.id == vehicleId })?.licensePlate ?? "Unknown"
    }

    func vehicleIdString(for vehicleId: UUID) -> String {
        vehicles.first(where: { $0.id == vehicleId })?.licensePlate ?? "Unknown"
    }

    func taskTypeString(for type: MaintenanceTaskType?) -> String {
        switch type {
        case .oilChange: return "Oil Change"
        case .tireRotation: return "Tire Rotation"
        case .inspection: return "Inspection"
        case .repair: return "Repair"
        case .other: return "Other"
        case .none: return "Unknown"
        }
    }

    func taskStatusColor(_ status: MaintenanceTaskStatus?) -> Color {
        switch status {
        case .pending: return Color.orange
        case .inProgress: return Color.blue
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none: return Color(.tertiaryLabel)
        }
    }

    func woStatusColor(_ status: WorkOrderStatus?) -> Color {
        switch status {
        case .open: return Color.blue
        case .inProgress: return Color.orange
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none: return Color(.tertiaryLabel)
        }
    }

    func irStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "open", "assigned": return Color.blue
        case "in_progress": return Color.orange
        case "resolved", "closed": return Color.green
        default: return Color(.tertiaryLabel)
        }
    }

    func irSeverityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return Color.red
        case "high": return Color.orange
        case "medium": return Color.blue
        case "low": return Color.green
        default: return Color(.tertiaryLabel)
        }
    }

    func woPriorityLabel(_ priority: WorkOrderPriority?) -> String? {
        switch priority {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        case nil: return nil
        }
    }

    func woPriorityColor(_ priority: WorkOrderPriority?) -> Color? {
        switch priority {
        case .critical: return Color.red
        case .high: return Color.orange
        case .medium: return Color.blue
        case .low: return Color.green
        case nil: return nil
        }
    }

    func dateString(for date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum MaintenanceDestination: Hashable {
    case workOrderDetail(WorkOrder)
    case issueReportDetail(IssueReportRecord)
    case workOrderList(filter: WorkOrderStatus?, assignedTo: UUID?, priority: WorkOrderPriority?)
}

struct UpcomingDisplayItem: Identifiable, Hashable {
    let id: UUID
    let priorityLabel: String?
    let priorityColor: Color?
    let referenceId: String
    let assignmentTag: String
    let vehicleName: String
    let taskDescription: String
    let estimatedDuration: String
    let location: String
    let actionButtonTitle: String
    let actionButtonIcon: String
    let destination: MaintenanceDestination?
    let isTask: Bool
}