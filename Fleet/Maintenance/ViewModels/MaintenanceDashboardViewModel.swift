import SwiftUI

@MainActor
@Observable
final class MaintenanceDashboardViewModel {
    private(set) var tasks: [MaintenanceTask] = []
    private(set) var workOrders: [WorkOrder] = []
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

    var upcomingTasks: [MaintenanceTask] {
        Array(tasks.filter { $0.status != .completed }.prefix(3))
    }

    var openWorkOrders: Int {
        workOrders.filter { $0.status == .open || $0.status == .inProgress }.count
    }

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let t = MaintenanceTaskService.fetchTasksForUser(assignedTo: userId)
            async let w = WorkOrderService.fetchWorkOrdersForUser(assignedTo: userId)
            async let i = InventoryService.fetchAllInventory()
            async let v = VehicleService.fetchAllVehicles()
            tasks = try await t
            workOrders = try await w
            inventory = try await i
            vehicles = try await v
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.onMaintenanceTasksChange = { [weak self] in Task { await self?.loadData() } }
        rt.onWorkOrdersChange = { [weak self] in Task { await self?.loadData() } }
        rt.onInventoryChange = { [weak self] in Task { await self?.loadData() } }
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

    func dateString(for date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
