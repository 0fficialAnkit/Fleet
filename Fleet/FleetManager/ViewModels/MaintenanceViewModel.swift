import SwiftUI

@MainActor
@Observable
final class MaintenanceViewModel {
    var tasks: [MaintenanceTask] = []
    private(set) var vehicles: [Vehicle] = []

    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let t = MaintenanceTaskService.fetchAllTasks()
            async let v = VehicleService.fetchAllVehicles()
            tasks = try await t
            vehicles = try await v
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

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

    func addTask(vehicleId: UUID, taskType: MaintenanceTaskType, description: String, scheduledDate: Date, assignedTo: UUID? = nil, scheduledBy: UUID? = nil) {
        let newTask = MaintenanceTask(
            id: UUID(),
            vehicleId: vehicleId,
            scheduledBy: scheduledBy,
            assignedTo: assignedTo,
            taskType: taskType,
            description: description,
            scheduledDate: scheduledDate,
            status: .pending
        )
        Task {
            do {
                try await MaintenanceTaskService.createTask(newTask)
                // Send notification to assigned user
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
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
