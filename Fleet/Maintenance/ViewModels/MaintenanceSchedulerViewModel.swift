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
    case active     = "Active"
    case inProgress = "In Progress"
    case completed  = "Completed"
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
    var estimatedDuration: String
    var status: TaskDisplayStatus
    let description: String
    let date: Date
    var checklistItems: [ChecklistItem]
    let partsNeeded: [String]
    let previousNote: String
    let aiRecommendation: String
    let sourceTaskId: UUID? // link to Supabase MaintenanceTask.id
    var laborHours: String? = nil
    var laborCost: String? = nil
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
    let vehicleIssue: String
}

// MARK: - Unified Scheduler Item (task or work order in one type)
enum SchedulerUnifiedItem: Identifiable, Hashable {
    case task(ScheduledTask)
    case workOrder(ScheduledWorkOrder)

    var id: UUID {
        switch self {
        case .task(let t):      return t.id
        case .workOrder(let w): return w.id
        }
    }

    var sortDate: Date {
        switch self {
        case .task(let t):      return t.date
        case .workOrder(let w): return w.createdAt
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class MaintenanceSchedulerViewModel {

    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    var selectedTask: ScheduledTask? = nil
    var showTaskDetail: Bool = false

    var selectedTab: SchedulerTabType = .active
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

    // MARK: - Date Navigation Helper

    func selectDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    // MARK: - Fetch Data from Supabase

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            vehicles = try await VehicleService.fetchAllVehicles()
            profiles = try await ProfileService.fetchAllProfiles()
            inventory = try await InventoryService.fetchAllInventory()

            if let uid = currentUserId {
                rawTasks = try await MaintenanceTaskService.fetchTasksForUser(assignedTo: uid)
                rawWorkOrders = try await WorkOrderService.fetchWorkOrdersForUser(assignedTo: uid)
                rawIssueReports = try await IssueReportService.fetchIssueReportsAssignedTo(userId: uid)
            } else {
                rawTasks = try await MaintenanceTaskService.fetchAllTasks()
                rawWorkOrders = try await WorkOrderService.fetchAllWorkOrders()
                rawIssueReports = try await IssueReportService.fetchAllIssueReports()
            }

            buildDisplayModels()
        } catch {
            errorMessage = error.localizedDescription
            print("[SchedulerViewModel] loadData error: \(error)")
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
                sourceTaskId: task.id,
                laborHours: nil,
                laborCost: nil
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
                sourceWorkOrderId: wo.id,
                vehicleIssue: "Scheduled maintenance / Service required."
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
                sourceIssueReportId: ir.id,
                vehicleIssue: ir.description ?? "No description reported."
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

    // Active: pending / delayed / critical tasks  +  open work orders
    var activeItemsForSelectedDate: [SchedulerUnifiedItem] {
        let cal = Calendar.current
        let tasks = allTasks
            .filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
            .filter { [.pending, .delayed, .critical].contains($0.status) }
            .map    { SchedulerUnifiedItem.task($0) }
        let wos = allWorkOrders
            .filter { cal.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .filter { $0.status == .open }
            .map    { SchedulerUnifiedItem.workOrder($0) }
        return (tasks + wos).sorted { $0.sortDate < $1.sortDate }
    }

    // In Progress: inProgress tasks  +  inProgress work orders
    var inProgressItemsForSelectedDate: [SchedulerUnifiedItem] {
        let cal = Calendar.current
        let tasks = allTasks
            .filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
            .filter { $0.status == .inProgress }
            .map    { SchedulerUnifiedItem.task($0) }
        let wos = allWorkOrders
            .filter { cal.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .filter { $0.status == .inProgress }
            .map    { SchedulerUnifiedItem.workOrder($0) }
        return (tasks + wos).sorted { $0.sortDate < $1.sortDate }
    }

    // Completed: completed tasks  +  completed / cancelled work orders
    var completedItemsForSelectedDate: [SchedulerUnifiedItem] {
        let cal = Calendar.current
        let tasks = allTasks
            .filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
            .filter { $0.status == .completed }
            .map    { SchedulerUnifiedItem.task($0) }
        let wos = allWorkOrders
            .filter { cal.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .filter { $0.status == .completed || $0.status == .cancelled }
            .map    { SchedulerUnifiedItem.workOrder($0) }
        return (tasks + wos).sorted { $0.sortDate < $1.sortDate }
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

    var allVehicles: [Vehicle] { vehicles }

    func updateTaskLabor(id: UUID, hours: String, cost: String) {
        if let idx = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[idx].laborHours = hours
            allTasks[idx].laborCost = cost
        }
        if selectedTask?.id == id {
            selectedTask?.laborHours = hours
            selectedTask?.laborCost = cost
        }
    }

    func updateTaskDuration(id: UUID, duration: String) {
        if let idx = allTasks.firstIndex(where: { $0.id == id }) {
            allTasks[idx].estimatedDuration = duration
        }
        if selectedTask?.id == id {
            selectedTask?.estimatedDuration = duration
        }
    }

    func createNewTask(vehicleId: UUID, taskType: MaintenanceTaskType, priority: TaskPriority, date: Date, description: String, estimatedDuration: String, laborHours: String, laborCost: String, currentUserId: UUID?) async {
        guard let vehicle = vehicles.first(where: { $0.id == vehicleId }) else { return }
        
        let newTask = ScheduledTask(
            id: UUID(),
            vehicleNumber: vehicle.licensePlate ?? "Unknown",
            vehicleName: "\(vehicle.make ?? "") \(vehicle.model ?? "")",
            taskType: taskType,
            priority: priority,
            scheduledTime: DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short),
            assignedBy: "Maintenance Personnel",
            estimatedDuration: estimatedDuration,
            status: .pending,
            description: description,
            date: date,
            checklistItems: [],
            partsNeeded: [],
            previousNote: "",
            aiRecommendation: "Perform routine maintenance.",
            sourceTaskId: nil,
            laborHours: laborHours.isEmpty ? nil : laborHours,
            laborCost: laborCost.isEmpty ? nil : laborCost
        )
        
        allTasks.append(newTask)
        
        if let currentUserId {
            do {
                let dbPriority: WorkOrderPriority
                switch priority {
                case .low: dbPriority = .low
                case .medium: dbPriority = .medium
                case .high: dbPriority = .high
                case .emergency: dbPriority = .critical
                }
                
                let workOrderId = try await WorkOrderService.createWorkOrder(
                    vehicleId: vehicleId,
                    createdBy: currentUserId,
                    assignedTo: currentUserId,
                    priority: dbPriority,
                    status: .open
                )
                
                try await MaintenanceTaskService.createTask(
                    workOrderId: workOrderId,
                    vehicleId: vehicleId,
                    scheduledBy: currentUserId,
                    assignedTo: currentUserId,
                    taskType: taskType,
                    description: description,
                    scheduledDate: date,
                    targetMileage: nil,
                    serviceIntervalMonths: nil,
                    scheduleType: nil,
                    status: .pending
                )
            } catch {
                print("[SchedulerViewModel] Failed to create work order or task: \(error)")
            }
        }
    }
}