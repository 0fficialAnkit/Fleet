import Foundation
import Supabase

enum MaintenanceTaskService {

    static func fetchAllTasks() async throws -> [MaintenanceTask] {
        try await supabase
            .from("maintenance_tasks")
            .select()
            .execute()
            .value
    }

    static func fetchTasksForUser(assignedTo: UUID) async throws -> [MaintenanceTask] {
        try await supabase
            .from("maintenance_tasks")
            .select()
            .eq("assigned_to", value: assignedTo)
            .execute()
            .value
    }

    static func createTask(_ task: MaintenanceTask) async throws {
        try await supabase
            .from("maintenance_tasks")
            .insert(task)
            .execute()
    }

    static func updateTask(_ task: MaintenanceTask) async throws {
        try await supabase
            .from("maintenance_tasks")
            .update(task)
            .eq("id", value: task.id)
            .execute()
    }

    static func updateTaskStatus(id: UUID, status: MaintenanceTaskStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: MaintenanceTaskStatus
        }
        try await supabase
            .from("maintenance_tasks")
            .update(StatusUpdate(status: status))
            .eq("id", value: id)
            .execute()
    }
}
