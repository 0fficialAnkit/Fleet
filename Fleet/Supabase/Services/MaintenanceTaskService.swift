import Foundation
import Supabase

// MARK: - MaintenanceTaskInsert
// Explicit insert struct — all columns that exist in maintenance_tasks table.
private struct MaintenanceTaskInsert: Encodable {
    let id: UUID
    let work_order_id: UUID?
    let vehicle_id: UUID
    let scheduled_by: UUID?
    let assigned_to: UUID?
    let task_type: MaintenanceTaskType?
    let description: String?
    let scheduled_date: String?
    let target_mileage: Double?
    let service_interval_months: Int?
    let schedule_type: MaintenanceScheduleType?
    let status: MaintenanceTaskStatus?
}

enum MaintenanceTaskService {

    static func fetchAllTasks() async throws -> [MaintenanceTask] {
        do {
            let result: [MaintenanceTask] = try await supabase
                .from("maintenance_tasks")
                .select()
                .execute()
                .value
            print("[MaintenanceTaskService] fetchAllTasks: \(result.count) records")
            return result
        } catch {
            print("[MaintenanceTaskService] fetchAllTasks ERROR: \(error)")
            throw error
        }
    }

    static func fetchTasksForUser(assignedTo: UUID) async throws -> [MaintenanceTask] {
        do {
            let result: [MaintenanceTask] = try await supabase
                .from("maintenance_tasks")
                .select()
                .eq("assigned_to", value: assignedTo)
                .execute()
                .value
            print("[MaintenanceTaskService] fetchTasksForUser(\(assignedTo)): \(result.count) records")
            return result
        } catch {
            print("[MaintenanceTaskService] fetchTasksForUser(\(assignedTo)) ERROR: \(error)")
            throw error
        }
    }

    /// Safe insert — explicitly lists every column to avoid sending unknown keys.
    static func createTask(
        workOrderId: UUID?,
        vehicleId: UUID,
        scheduledBy: UUID?,
        assignedTo: UUID?,
        taskType: MaintenanceTaskType?,
        description: String?,
        scheduledDate: Date?,
        targetMileage: Double?,
        serviceIntervalMonths: Int?,
        scheduleType: MaintenanceScheduleType?,
        status: MaintenanceTaskStatus?
    ) async throws {
        let dateString: String?
        if let date = scheduledDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            dateString = formatter.string(from: date)
        } else {
            dateString = nil
        }

        let payload = MaintenanceTaskInsert(
            id: UUID(),
            work_order_id: workOrderId,
            vehicle_id: vehicleId,
            scheduled_by: scheduledBy,
            assigned_to: assignedTo,
            task_type: taskType,
            description: description,
            scheduled_date: dateString,
            target_mileage: targetMileage,
            service_interval_months: serviceIntervalMonths,
            schedule_type: scheduleType,
            status: status
        )
        do {
            try await supabase
                .from("maintenance_tasks")
                .insert(payload)
                .execute()
            print("[MaintenanceTaskService] createTask: OK vehicleId=\(vehicleId) workOrderId=\(String(describing: workOrderId))")
        } catch {
            print("[MaintenanceTaskService] createTask ERROR: \(error)")
            throw error
        }
    }

    /// Legacy method — keep for compatibility with existing callers.
    static func createTask(_ task: MaintenanceTask) async throws {
        try await createTask(
            workOrderId: task.workOrderId,
            vehicleId: task.vehicleId,
            scheduledBy: task.scheduledBy,
            assignedTo: task.assignedTo,
            taskType: task.taskType,
            description: task.description,
            scheduledDate: task.scheduledDate,
            targetMileage: task.targetMileage,
            serviceIntervalMonths: task.serviceIntervalMonths,
            scheduleType: task.scheduleType,
            status: task.status
        )
    }

    static func updateTask(_ task: MaintenanceTask) async throws {
        do {
            try await supabase
                .from("maintenance_tasks")
                .update(task)
                .eq("id", value: task.id)
                .execute()
            print("[MaintenanceTaskService] updateTask(\(task.id)): OK")
        } catch {
            print("[MaintenanceTaskService] updateTask(\(task.id)) ERROR: \(error)")
            throw error
        }
    }

    static func updateTaskStatus(id: UUID, status: MaintenanceTaskStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: MaintenanceTaskStatus
        }
        do {
            try await supabase
                .from("maintenance_tasks")
                .update(StatusUpdate(status: status))
                .eq("id", value: id)
                .execute()
            print("[MaintenanceTaskService] updateTaskStatus(\(id)) → \(status.rawValue): OK")
        } catch {
            print("[MaintenanceTaskService] updateTaskStatus(\(id)) ERROR: \(error)")
            throw error
        }
    }
}