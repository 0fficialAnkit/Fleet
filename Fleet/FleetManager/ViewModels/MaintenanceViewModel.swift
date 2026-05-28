import SwiftUI

@MainActor
@Observable
final class MaintenanceViewModel {
    var tasks: [MaintenanceTask] = []
    var workOrders: [WorkOrder] = []
    private(set) var vehicles: [Vehicle] = []
    private(set) var maintenanceStaff: [Profile] = []

    var isLoading = false
    var errorMessage: String?

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addMaintenanceTasksChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addWorkOrdersChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let t = MaintenanceTaskService.fetchAllTasks()
            async let w = WorkOrderService.fetchAllWorkOrders()
            async let v = VehicleService.fetchAllVehicles()
            async let s = ProfileService.fetchProfilesByRole(role: "maintenance")
            tasks = try await t
            workOrders = try await w
            vehicles = try await v
            maintenanceStaff = try await s
            print("[MaintenanceViewModel] Loaded: tasks=\(tasks.count) workOrders=\(workOrders.count) vehicles=\(vehicles.count) staff=\(maintenanceStaff.count)")
        } catch {
            print("[MaintenanceViewModel] loadData ERROR: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getVehicle(for vehicleId: UUID) -> Vehicle? {
        vehicles.first { $0.id == vehicleId }
    }

    func getStatusColor(_ status: MaintenanceTaskStatus?) -> Color {
        switch status {
        case .completed: return Color.green
        case .pending: return Color.orange
        case .inProgress: return Color.blue
        case .cancelled: return Color.red
        case nil: return Color(.tertiaryLabel)
        }
    }

    /// Create a work order assigned to a maintenance staff member.
    func addWorkOrder(vehicleId: UUID, createdBy: UUID?, assignedTo: UUID?, priority: WorkOrderPriority) async throws {
        print("[MaintenanceViewModel] addWorkOrder vehicleId=\(vehicleId) assignedTo=\(String(describing: assignedTo))")
        let workOrderId = try await WorkOrderService.createWorkOrder(
            vehicleId: vehicleId,
            createdBy: createdBy,
            assignedTo: assignedTo,
            priority: priority,
            status: .open
        )
        // Notify assigned maintenance staff
        if let userId = assignedTo {
            let vehicle = vehicles.first { $0.id == vehicleId }
            let vehicleName = "\(vehicle?.make ?? "") \(vehicle?.model ?? "")"
            let notification = Notification(
                id: UUID(),
                userId: userId,
                title: "New Work Order",
                message: "A \(priority.rawValue) priority work order has been assigned to you for \(vehicleName).",
                type: .maintenance,
                isRead: false,
                createdAt: Date()
            )
            try? await NotificationService.createNotification(notification)
        }
        _ = workOrderId
        await loadData()
    }

    /// Create a maintenance task, optionally linked to a work order.
    func addTask(
        vehicleId: UUID,
        taskType: MaintenanceTaskType,
        description: String,
        scheduledDate: Date?,
        targetMileage: Double?,
        serviceIntervalMonths: Int?,
        scheduleType: MaintenanceScheduleType?,
        assignedTo: UUID? = nil,
        scheduledBy: UUID? = nil,
        workOrderId: UUID? = nil
    ) async throws {
        print("[MaintenanceViewModel] addTask vehicleId=\(vehicleId) type=\(taskType.rawValue) assignedTo=\(String(describing: assignedTo))")
        try await MaintenanceTaskService.createTask(
            workOrderId: workOrderId,
            vehicleId: vehicleId,
            scheduledBy: scheduledBy,
            assignedTo: assignedTo,
            taskType: taskType,
            description: description,
            scheduledDate: scheduledDate,
            targetMileage: targetMileage,
            serviceIntervalMonths: serviceIntervalMonths,
            scheduleType: scheduleType,
            status: .pending
        )
        // Notify assigned maintenance staff
        if let userId = assignedTo {
            let notification = Notification(
                id: UUID(),
                userId: userId,
                title: "New Maintenance Task",
                message: "You have been assigned a \(taskType.rawValue.replacingOccurrences(of: "_", with: " ")) task.",
                type: .maintenance,
                isRead: false,
                createdAt: Date()
            )
            try? await NotificationService.createNotification(notification)
        }
        await loadData()
    }
}