import SwiftUI
import Foundation

// MARK: - Local UI-Layer Enums (Maintenance Scheduler only)

enum TaskPriority: String, CaseIterable {
    case low       = "Low"
    case medium    = "Medium"
    case high      = "High"
    case emergency = "Emergency"
}

enum TaskDisplayStatus: String, CaseIterable {
    case pending    = "Pending"
    case inProgress = "In Progress"
    case completed  = "Completed"
    case delayed    = "Delayed"
    case critical   = "Critical"
}

enum SchedulerTabType: String, CaseIterable {
    case tasks = "Tasks"
    case workOrders = "Work Orders"
}

// MARK: - ChecklistItem

struct ChecklistItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    var isChecked: Bool

    init(title: String, isChecked: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isChecked = isChecked
    }
}

// MARK: - ScheduledTask (UI display model)

struct ScheduledTask: Identifiable, Hashable {
    let id: UUID
    let vehicleNumber: String
    let vehicleName: String
    let taskType: MaintenanceTaskType
    let priority: TaskPriority
    let scheduledTime: String
    let assignedBy: String
    let estimatedDuration: String
    var status: TaskDisplayStatus
    let description: String
    let date: Date
    var checklistItems: [ChecklistItem]
    let partsNeeded: [String]
    let previousNote: String
    let aiRecommendation: String
    let sourceTaskId: UUID? // link to Supabase MaintenanceTask.id
}

// MARK: - ScheduledWorkOrder (UI display model)

struct ScheduledWorkOrder: Identifiable, Hashable {
    let id: UUID
    let vehicleNumber: String
    let vehicleName: String
    let priority: WorkOrderPriority
    var status: WorkOrderStatus
    let createdAt: Date
    let assignedBy: String
    let laborHours: String
    let laborCost: String
    var notes: String
    var partsUsed: [String]
    let sourceWorkOrderId: UUID? // link to Supabase WorkOrder.id
    var sourceIssueReportId: UUID? = nil // link to Supabase IssueReportRecord.id
}

// MARK: - ViewModel

@MainActor
@Observable
final class MaintenanceSchedulerViewModel {

    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var selectedTask: ScheduledTask? = nil
    var showTaskDetail: Bool = false

    var selectedTab: SchedulerTabType = .tasks
    var selectedWorkOrder: ScheduledWorkOrder? = nil
    var showWorkOrderDetail: Bool = false

    var allTasks: [ScheduledTask] = []
    var allWorkOrders: [ScheduledWorkOrder] = []

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?

    private var rawTasks: [MaintenanceTask] = []
    private var rawWorkOrders: [WorkOrder] = []
    private var rawIssueReports: [IssueReportRecord] = []
    private var vehicles: [Vehicle] = []
    private var profiles: [Profile] = []
    private(set) var inventory: [Inventory] = []

    // MARK: - Load Data

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let t = MaintenanceTaskService.fetchTasksForUser(assignedTo: userId)
            async let w = WorkOrderService.fetchWorkOrdersForUser(assignedTo: userId)
            async let ir = IssueReportService.fetchIssueReportsAssignedTo(userId: userId)
            async let v = VehicleService.fetchAllVehicles()
            async let p = ProfileService.fetchAllProfiles()
            async let i = InventoryService.fetchAllInventory()

            rawTasks = try await t
            rawWorkOrders = try await w
            rawIssueReports = try await ir
            vehicles = try await v
            profiles = try await p
            inventory = try await i

            buildDisplayModels()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addMaintenanceTasksChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addWorkOrdersChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addIssueReportsChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    // MARK: - Build UI display models from Supabase data

    private func buildDisplayModels() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"

        allTasks = rawTasks.map { task in
            let vehicle = vehicles.first { $0.id == task.vehicleId }
            let scheduledBy = profiles.first { $0.id == task.scheduledBy }

            let displayStatus: TaskDisplayStatus
            switch task.status {
            case .pending: displayStatus = .pending
            case .inProgress: displayStatus = .inProgress
            case .completed: displayStatus = .completed
            case .cancelled: displayStatus = .delayed
            case .none: displayStatus = .pending
            }

            let priority: TaskPriority
            switch task.taskType {
            case .repair: priority = .high
            case .inspection: priority = .medium
            case .oilChange: priority = .low
            case .tireRotation: priority = .low
            case .other: priority = .medium
            case .none: priority = .medium
            }

            return ScheduledTask(
                id: UUID(),
                vehicleNumber: vehicle?.licensePlate ?? "Unknown",
                vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
                taskType: task.taskType ?? .other,
                priority: priority,
                scheduledTime: task.scheduledDate.map { timeFormatter.string(from: $0) } ?? "TBD",
                assignedBy: scheduledBy?.fullName ?? "Fleet Manager",
                estimatedDuration: "1-2 hrs",
                status: displayStatus,
                description: task.description ?? "No description.",
                date: task.scheduledDate ?? Date(),
                checklistItems: defaultChecklist(for: task.taskType),
                partsNeeded: [],
                previousNote: "",
                aiRecommendation: "",
                sourceTaskId: task.id
            )
        }

        var mappedWorkOrders = rawWorkOrders.map { wo in
            let vehicle = vehicles.first { $0.id == wo.vehicleId }
            let createdBy = profiles.first { $0.id == wo.createdBy }

            return ScheduledWorkOrder(
                id: UUID(),
                vehicleNumber: vehicle?.licensePlate ?? "Unknown",
                vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
                priority: wo.priority ?? .medium,
                status: wo.status ?? .open,
                createdAt: wo.createdAt ?? Date(),
                assignedBy: createdBy?.fullName ?? "Fleet Manager",
                laborHours: "—",
                laborCost: "—",
                notes: "",
                partsUsed: [],
                sourceWorkOrderId: wo.id
            )
        }
        
        let mappedIssueReports = rawIssueReports.map { ir in
            let vehicle = vehicles.first { $0.id == ir.vehicleId }
            let reportedBy = profiles.first { $0.id == ir.reportedBy }
            
            let priority: WorkOrderPriority
            switch ir.severity.lowercased() {
            case "critical": priority = .critical
            case "high": priority = .high
            case "medium": priority = .medium
            case "low": priority = .low
            default: priority = .medium
            }
            
            let status: WorkOrderStatus
            switch ir.status.lowercased() {
            case "open", "assigned": status = .open
            case "in_progress": status = .inProgress
            case "resolved", "closed": status = .completed
            default: status = .open
            }
            
            return ScheduledWorkOrder(
                id: UUID(),
                vehicleNumber: vehicle?.licensePlate ?? "Unknown",
                vehicleName: "\(vehicle?.make ?? "") \(vehicle?.model ?? "")",
                priority: priority,
                status: status,
                createdAt: ir.createdAt ?? Date(),
                assignedBy: reportedBy?.fullName ?? "Driver",
                laborHours: "—",
                laborCost: "—",
                notes: ir.description ?? "",
                partsUsed: [],
                sourceWorkOrderId: nil,
                sourceIssueReportId: ir.id
            )
        }
        
        mappedWorkOrders.append(contentsOf: mappedIssueReports)
        allWorkOrders = mappedWorkOrders
    }

    private func defaultChecklist(for type: MaintenanceTaskType?) -> [ChecklistItem] {
        switch type {
        case .oilChange:
            return [
                ChecklistItem(title: "Drain old engine oil"),
                ChecklistItem(title: "Replace oil filter"),
                ChecklistItem(title: "Add new oil"),
                ChecklistItem(title: "Check for leaks after fill")
            ]
        case .tireRotation:
            return [
                ChecklistItem(title: "Record current tread depth"),
                ChecklistItem(title: "Rotate tyres"),
                ChecklistItem(title: "Inflate to recommended PSI"),
                ChecklistItem(title: "Check for punctures or cracks")
            ]
        case .inspection:
            return [
                ChecklistItem(title: "Lights and signals check"),
                ChecklistItem(title: "Fluid levels check"),
                ChecklistItem(title: "Brake system check"),
                ChecklistItem(title: "Tyre pressure verification")
            ]
        case .repair:
            return [
                ChecklistItem(title: "Diagnose fault"),
                ChecklistItem(title: "Order parts if needed"),
                ChecklistItem(title: "Perform repair"),
                ChecklistItem(title: "Test after repair")
            ]
        default:
            return [ChecklistItem(title: "Complete task")]
        }
    }

    // MARK: - Calendar Days
    var calendarDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-7...22).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    var tasksForSelectedDate: [ScheduledTask] {
        allTasks.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var workOrdersForSelectedDate: [ScheduledWorkOrder] {
        allWorkOrders.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var taskCountForDate: [Date: Int] {
        var counts: [Date: Int] = [:]
        for task in allTasks {
            let day = Calendar.current.startOfDay(for: task.date)
            counts[day, default: 0] += 1
        }
        for wo in allWorkOrders {
            let day = Calendar.current.startOfDay(for: wo.createdAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    // MARK: - Mutations

    func updateTaskStatus(id: UUID, to status: TaskDisplayStatus) {
        if let i = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[i].status = status

            // Write back to Supabase
            if let sourceId = allTasks[i].sourceTaskId {
                let dbStatus: MaintenanceTaskStatus
                switch status {
                case .pending: dbStatus = .pending
                case .inProgress: dbStatus = .inProgress
                case .completed: dbStatus = .completed
                case .delayed, .critical: dbStatus = .pending
                }
                Task {
                    try? await MaintenanceTaskService.updateTaskStatus(id: sourceId, status: dbStatus)
                }
            }
        }
        if selectedTask?.id == id {
            selectedTask?.status = status
        }
    }

    func toggleChecklist(taskId: UUID, itemId: UUID) {
        guard let ti = allTasks.firstIndex(where: { $0.id == taskId }),
              let ci = allTasks[ti].checklistItems.firstIndex(where: { $0.id == itemId }) else { return }
        allTasks[ti].checklistItems[ci].isChecked.toggle()
        if selectedTask?.id == taskId {
            selectedTask = allTasks[ti]
        }
    }

    func updateWorkOrderStatus(id: UUID, to status: WorkOrderStatus) {
        if let i = allWorkOrders.firstIndex(where: { $0.id == id }) {
            allWorkOrders[i].status = status

            // Write back to Supabase
            if let sourceId = allWorkOrders[i].sourceWorkOrderId {
                Task {
                    try? await WorkOrderService.updateWorkOrderStatus(id: sourceId, status: status)
                    // If completed, create maintenance history
                    if status == .completed {
                        let wo = allWorkOrders[i]
                        if let vehicle = vehicles.first(where: { $0.licensePlate == wo.vehicleNumber }) {
                            let history = MaintenanceHistory(
                                id: UUID(),
                                vehicleId: vehicle.id,
                                workOrderId: sourceId,
                                serviceDetails: "Work order completed: \(wo.notes)",
                                cost: nil,
                                completedAt: Date()
                            )
                            try? await MaintenanceHistoryService.createHistory(history)
                        }
                    }
                }
            } else if let sourceIrId = allWorkOrders[i].sourceIssueReportId, let uid = currentUserId {
                Task {
                    let statusStr: String
                    switch status {
                    case .open: statusStr = "open"
                    case .inProgress: statusStr = "in_progress"
                    case .completed: statusStr = "resolved"
                    case .cancelled: statusStr = "closed"
                    }
                    try? await IssueReportService.updateIssueReport(id: sourceIrId, assignedTo: uid, status: statusStr)
                }
            }
        }
        if selectedWorkOrder?.id == id {
            selectedWorkOrder?.status = status
        }
    }

    func updateWorkOrderNotes(id: UUID, notes: String) {
        if let i = allWorkOrders.firstIndex(where: { $0.id == id }) {
            allWorkOrders[i].notes = notes
        }
        if selectedWorkOrder?.id == id {
            selectedWorkOrder?.notes = notes
        }
    }

    func addPartToWorkOrder(id: UUID, part: String) {
        if let i = allWorkOrders.firstIndex(where: { $0.id == id }) {
            allWorkOrders[i].partsUsed.append(part)
        }
        if selectedWorkOrder?.id == id {
            selectedWorkOrder?.partsUsed.append(part)
        }
        
        // Find matching inventory item
        if let inventoryItem = inventory.first(where: { $0.partName?.lowercased() == part.lowercased() }) {
            let itemId = inventoryItem.id
            let stock = inventoryItem.stockQuantity ?? 0
            
            Task {
                // Update stock if greater than 0
                if stock > 0 {
                    try? await InventoryService.updateStock(id: itemId, newQuantity: stock - 1)
                }
                
                // Add WorkOrderPart record
                if let sourceId = allWorkOrders.first(where: { $0.id == id })?.sourceWorkOrderId {
                    let wop = WorkOrderPart(
                        id: UUID(),
                        workOrderId: sourceId,
                        inventoryItemId: itemId,
                        quantityUsed: 1,
                        hoursSpent: nil
                    )
                    try? await WorkOrderPartService.addPart(wop)
                }
            }
        }
    }
}
