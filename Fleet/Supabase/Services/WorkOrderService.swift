import Foundation
import Supabase

enum WorkOrderService {

    static func fetchAllWorkOrders() async throws -> [WorkOrder] {
        try await supabase
            .from("work_orders")
            .select()
            .execute()
            .value
    }

    static func fetchWorkOrdersForUser(assignedTo: UUID) async throws -> [WorkOrder] {
        try await supabase
            .from("work_orders")
            .select()
            .eq("assigned_to", value: assignedTo)
            .execute()
            .value
    }

    static func createWorkOrder(_ workOrder: WorkOrder) async throws {
        try await supabase
            .from("work_orders")
            .insert(workOrder)
            .execute()
    }

    static func updateWorkOrder(_ workOrder: WorkOrder) async throws {
        try await supabase
            .from("work_orders")
            .update(workOrder)
            .eq("id", value: workOrder.id)
            .execute()
    }

    static func updateWorkOrderStatus(id: UUID, status: WorkOrderStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: WorkOrderStatus
        }
        try await supabase
            .from("work_orders")
            .update(StatusUpdate(status: status))
            .eq("id", value: id)
            .execute()
    }
}
