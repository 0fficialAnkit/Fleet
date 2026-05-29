import Foundation
import Supabase

// MARK: - MaintenanceTaskInsert
// Explicit insert struct — only columns confirmed to exist in maintenance_tasks table.
// schedule_type is excluded: column does not exist in the current DB schema.
private struct MaintenanceTaskInsert: Encodable {
    let id: UUID
    let work_order_id: UUID?
    let vehicle_id: UUID
    let scheduled_by: UUID?
    let assigned_to: UUID?
    let task_type: MaintenanceTaskType?
    let description: String?
    let scheduled_date: Date?
    let target_mileage: Double?
    let service_interval_months: Int?
    let status: MaintenanceTaskStatus?
}

// MARK: - MaintenanceTaskUpdate
// Safe update struct — only non-problematic columns.
private struct MaintenanceTaskUpdate: Encodable {
    let work_order_id: UUID?
    let vehicle_id: UUID
    let scheduled_by: UUID?
    let assigned_to: UUID?
    let task_type: MaintenanceTaskType?
    let description: String?
    let scheduled_date: Date?
    let target_mileage: Double?
    let service_interval_months: Int?
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

    /// Safe insert — explicitly lists every column that exists in maintenance_tasks.
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
        scheduleType: MaintenanceScheduleType?,   // accepted for API compat, not sent to DB
        status: MaintenanceTaskStatus?
    ) async throws {
        let payload = MaintenanceTaskInsert(
            id: UUID(),
            work_order_id: workOrderId,
            vehicle_id: vehicleId,
            scheduled_by: scheduledBy,
            assigned_to: assignedTo,
            task_type: taskType,
            description: description,
            scheduled_date: scheduledDate,
            target_mileage: targetMileage,
            service_interval_months: serviceIntervalMonths,
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

    /// Safe update — uses an explicit struct to avoid sending schedule_type (non-existent column).
    static func updateTask(_ task: MaintenanceTask) async throws {
        let payload = MaintenanceTaskUpdate(
            work_order_id: task.workOrderId,
            vehicle_id: task.vehicleId,
            scheduled_by: task.scheduledBy,
            assigned_to: task.assignedTo,
            task_type: task.taskType,
            description: task.description,
            scheduled_date: task.scheduledDate,
            target_mileage: task.targetMileage,
            service_interval_months: task.serviceIntervalMonths,
            status: task.status
        )
        do {
            try await supabase
                .from("maintenance_tasks")
                .update(payload)
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