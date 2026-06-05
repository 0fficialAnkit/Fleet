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

        let tItems = tasks.filter { $0.status == .pending }.map { task -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: task.id,
                priorityLabel: nil,
                priorityColor: nil,
                referenceId: "TSK-\(task.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "SCHEDULED",
                vehicleName: vehicleDisplayName(for: task.vehicleId),
                taskDescription: taskTypeString(for: task.taskType),
                estimatedDuration: "1h 30m",
                location: "Bay 01",
                actionButtonTitle: "Start Task",
                actionButtonIcon: "play.fill",
                destination: .scheduledWorkOrderDetail(buildScheduledWOFromTask(task)),
                isTask: true,
                createdAt: task.scheduledDate
            )
        }
        items.append(contentsOf: tItems)

        let woItems = workOrders.filter { $0.status == .open || $0.status == nil || $0.status == .pending }.map { wo -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: wo.id,
                priorityLabel: woPriorityLabel(wo.priority),
                priorityColor: woPriorityColor(wo.priority),
                referenceId: "WO-\(wo.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "ASSIGNED TO YOU",
                vehicleName: vehicleDisplayName(for: wo.vehicleId),
                taskDescription: "Work Order Execution",
                estimatedDuration: "2h 30m",
                location: "Bay 04",
                actionButtonTitle: "Start Work",
                actionButtonIcon: "play.fill",
                destination: .scheduledWorkOrderDetail(buildScheduledWO(wo)),
                isTask: false,
                createdAt: wo.createdAt
            )
        }
        items.append(contentsOf: woItems)

        let irItems = issueReports.filter { $0.status.lowercased() == "open" || $0.status.lowercased() == "assigned" }.map { ir -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: ir.id,
                priorityLabel: ir.severity.uppercased(),
                priorityColor: irSeverityColor(ir.severity),
                referenceId: "REP-\(ir.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "ASSIGNED TO YOU",
                vehicleName: vehicleDisplayName(for: ir.vehicleId),
                taskDescription: ir.category + (ir.description?.isEmpty == false ? " - \(ir.description!)" : ""),
                estimatedDuration: "1h 00m",
                location: "Bay 02",
                actionButtonTitle: "Start Repair",
                actionButtonIcon: "play.fill",
                destination: .scheduledWorkOrderDetail(buildScheduledWOFromIR(ir)),
                isTask: false,
                createdAt: ir.createdAt
            )
        }
        items.append(contentsOf: irItems)
        
        items.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        return Array(items.prefix(3))
    }

    var inProgressItems: [UpcomingDisplayItem] {
        var items: [UpcomingDisplayItem] = []

        let tItems = tasks.filter { $0.status == .inProgress }.map { task -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: task.id,
                priorityLabel: nil,
                priorityColor: nil,
                referenceId: "TSK-\(task.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "IN PROGRESS",
                vehicleName: vehicleDisplayName(for: task.vehicleId),
                taskDescription: taskTypeString(for: task.taskType),
                estimatedDuration: "1h 30m",
                location: "Bay 01",
                actionButtonTitle: "Continue Task",
                actionButtonIcon: "play.fill",
                destination: .scheduledWorkOrderDetail(buildScheduledWOFromTask(task)),
                isTask: true,
                createdAt: task.scheduledDate
            )
        }
        items.append(contentsOf: tItems)

        let woItems = workOrders.filter { $0.status == .inProgress }.map { wo -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: wo.id,
                priorityLabel: woPriorityLabel(wo.priority),
                priorityColor: woPriorityColor(wo.priority),
                referenceId: "WO-\(wo.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "IN PROGRESS",
                vehicleName: vehicleDisplayName(for: wo.vehicleId),
                taskDescription: "Work Order Execution",
                estimatedDuration: "2h 30m",
                location: "Bay 04",
                actionButtonTitle: "Continue Work",
                actionButtonIcon: "play.fill",
                destination: .scheduledWorkOrderDetail(buildScheduledWO(wo)),
                isTask: false,
                createdAt: wo.createdAt
            )
        }
        items.append(contentsOf: woItems)

        let irItems = issueReports.filter { $0.status.lowercased() == "in_progress" }.map { ir -> UpcomingDisplayItem in
            return UpcomingDisplayItem(
                id: ir.id,
                priorityLabel: ir.severity.uppercased(),
                priorityColor: irSeverityColor(ir.severity),
                referenceId: "REP-\(ir.id.uuidString.prefix(4).uppercased())",
                assignmentTag: "IN PROGRESS",
                vehicleName: vehicleDisplayName(for: ir.vehicleId),
                taskDescription: ir.category + (ir.description?.isEmpty == false ? " - \(ir.description!)" : ""),
                estimatedDuration: "1h 00m",
                location: "Bay 02",
                actionButtonTitle: "Continue Repair",
                actionButtonIcon: "play.fill",
                destination: .scheduledWorkOrderDetail(buildScheduledWOFromIR(ir)),
                isTask: false,
                createdAt: ir.createdAt
            )
        }
        items.append(contentsOf: irItems)
        
        items.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        return Array(items.prefix(3))
    }

    var unifiedItems: [UnifiedMaintenanceItem] {
        let woItems = workOrders.map { UnifiedMaintenanceItem.workOrder($0) }
        let irItems = issueReports.map { UnifiedMaintenanceItem.issueReport($0) }
        return woItems + irItems
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

        // Each fetch is independent — one DB failure won't block the others.
        async let t  = MaintenanceTaskService.fetchTasksForUser(assignedTo: userId)
        async let w  = WorkOrderService.fetchWorkOrdersForUser(assignedTo: userId)
        async let i  = InventoryService.fetchAllInventory()
        async let v  = VehicleService.fetchAllVehicles()

        // Await vehicles FIRST — upcomingItems is a computed property that reads vehicles.
        // If vehicles is awaited last, the view renders with empty vehicles → "Unknown".
        // All four fetches still run concurrently (async let), so there's no speed penalty.
        if let result = try? await v  { vehicles     = result } else { print("Failed to fetch vehicles") }
        if let result = try? await t  { tasks        = result } else { print("Failed to fetch tasks") }
        if let result = try? await w  { workOrders   = result } else { print("Failed to fetch workOrders") }
        if let result = try? await i  { inventory    = result } else { print("Failed to fetch inventory") }

        do {
            issueReports = try await IssueReportService.fetchIssueReportsAssignedTo(userId: userId)
        } catch {
            print("Failed to fetch issue reports: \(error)")
        }

        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addMaintenanceTasksChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addWorkOrdersChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addIssueReportsChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addInventoryChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    /// License plate — used for IDs / reference codes.
    func vehiclePlate(for vehicleId: UUID) -> String {
        vehicles.first(where: { $0.id == vehicleId })?.licensePlate ?? "Unknown"
    }

    /// Make + model display name — used as the card title in Upcoming Maintenance.
    func vehicleDisplayName(for vehicleId: UUID) -> String {
        guard let v = vehicles.first(where: { $0.id == vehicleId }) else { return "Unknown" }
        let name = "\(v.make ?? "") \(v.model ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? (v.licensePlate ?? "Unknown") : name
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
        case .pending: return Color.gray
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

    // MARK: - ScheduledWorkOrder Builders (for dashboard → detail navigation)

    func buildScheduledWO(_ wo: WorkOrder) -> ScheduledWorkOrder {
        let vehicle = vehicles.first { $0.id == wo.vehicleId }
        return ScheduledWorkOrder(
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
    }

    func buildScheduledWOFromTask(_ task: MaintenanceTask) -> ScheduledWorkOrder {
        let vehicle = vehicles.first { $0.id == task.vehicleId }
        let status: WorkOrderStatus = {
            switch task.status {
            case .pending:    return .open
            case .inProgress: return .inProgress
            case .completed:  return .completed
            case .cancelled:  return .cancelled
            case .none:       return .open
            }
        }()
        return ScheduledWorkOrder(
            id: task.id,
            vehicleNumber: vehicle?.licensePlate ?? "Unknown",
            vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
            priority: .medium,
            status: status,
            createdAt: task.scheduledDate ?? Date(),
            assignedBy: "Fleet Manager",
            laborHours: "—",
            laborCost: "—",
            notes: task.description ?? "",
            partsUsed: [],
            sourceWorkOrderId: task.workOrderId,
            vehicleIssue: task.description ?? "Scheduled task."
        )
    }

    func buildScheduledWOFromIR(_ ir: IssueReportRecord) -> ScheduledWorkOrder {
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
        return ScheduledWorkOrder(
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
    }
}

enum MaintenanceDestination: Hashable {
    case scheduledWorkOrderDetail(ScheduledWorkOrder)
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
    let createdAt: Date?
}