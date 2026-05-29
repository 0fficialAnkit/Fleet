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
    let scheduled_date: Date?
    let target_mileage: Double?
    let service_internal: Int?
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
            service_internal: serviceIntervalMonths,
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

    /// Updates task status and sets completed_at timestamp in a single DB call.
    static func updateTaskStatusWithCompletion(id: UUID, status: MaintenanceTaskStatus, completedAt: Date?) async throws {
        struct StatusCompletionUpdate: Encodable {
            let status: MaintenanceTaskStatus
            let completed_at: Date?
        }
        do {
            try await supabase
                .from("maintenance_tasks")
                .update(StatusCompletionUpdate(status: status, completed_at: completedAt))
                .eq("id", value: id)
                .execute()
            print("[MaintenanceTaskService] updateTaskStatusWithCompletion(\(id)) → \(status.rawValue), completedAt=\(String(describing: completedAt)): OK")
        } catch {
            print("[MaintenanceTaskService] updateTaskStatusWithCompletion(\(id)) ERROR: \(error)")
            throw error
        }
    }

    /// Fetches all completed tasks for a user (permanent history).
    static func fetchCompletedTasksForUser(assignedTo: UUID) async throws -> [MaintenanceTask] {
        do {
            let result: [MaintenanceTask] = try await supabase
                .from("maintenance_tasks")
                .select()
                .eq("assigned_to", value: assignedTo)
                .eq("status", value: MaintenanceTaskStatus.completed.rawValue)
                .order("completed_at", ascending: false)
                .execute()
                .value
            print("[MaintenanceTaskService] fetchCompletedTasksForUser(\(assignedTo)): \(result.count) records")
            return result
        } catch {
            print("[MaintenanceTaskService] fetchCompletedTasksForUser(\(assignedTo)) ERROR: \(error)")
            throw error
        }
    }
}