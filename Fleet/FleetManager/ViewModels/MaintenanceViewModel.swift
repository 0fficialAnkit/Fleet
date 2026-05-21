import SwiftUI

@Observable
final class MaintenanceViewModel {
    var tasks: [MaintenanceTask] = MockData.maintenanceTasks
    private let vehicles: [Vehicle] = MockData.vehicles
    
    func getVehicle(for vehicleId: UUID) -> Vehicle? {
        vehicles.first { $0.id == vehicleId }
    }
    
    func getStatusColor(_ status: MaintenanceTaskStatus?) -> Color {
        switch status {
        case .completed: return themeModel.success
        case .pending: return themeModel.warning
        case .inProgress: return themeModel.info
        case .cancelled: return themeModel.danger
        case nil: return themeModel.textTertiary
        }
    }
    
    func addTask(vehicleId: UUID, taskType: MaintenanceTaskType, description: String, scheduledDate: Date) {
        let newTask = MaintenanceTask(
            id: UUID(),
            vehicleId: vehicleId,
            scheduledBy: nil,
            assignedTo: nil,
            taskType: taskType,
            description: description,
            scheduledDate: scheduledDate,
            status: .pending
        )
        tasks.append(newTask)
    }
}
