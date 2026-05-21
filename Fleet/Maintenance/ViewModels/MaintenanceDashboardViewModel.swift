import SwiftUI

@Observable
final class MaintenanceDashboardViewModel {
    private(set) var tasks: [MaintenanceTask] = MockData.maintenanceTasks
    private(set) var inventory: [Inventory] = MockData.inventory
    
    var pendingTasks: Int {
        tasks.filter { $0.status == .pending }.count
    }
    
    var inProgressTasks: Int {
        tasks.filter { $0.status == .inProgress }.count
    }
    
    var completedToday: Int {
        // Mock data logic for today's completed tasks
        tasks.filter { $0.status == .completed }.count
    }
    
    var lowStockItemsCount: Int {
        inventory.filter { ($0.stockQuantity ?? 0) <= ($0.reorderLevel ?? 0) }.count
    }
    
    var upcomingTasks: [MaintenanceTask] {
        // Limit to upcoming tasks
        Array(tasks.filter { $0.status != .completed }.prefix(3))
    }
    
    func vehicleIdString(for vehicleId: UUID) -> String {
        guard let vehicle = MockData.vehicles.first(where: { $0.id == vehicleId }) else { return "Unknown" }
        return vehicle.licensePlate ?? "Unknown"
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
