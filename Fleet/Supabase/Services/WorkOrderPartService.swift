import Foundation
import Supabase

enum WorkOrderPartService {

    static func fetchParts(workOrderId: UUID) async throws -> [WorkOrderPart] {
        try await supabase
            .from("work_order_parts")
            .select()
            .eq("work_order_id", value: workOrderId)
            .execute()
            .value
    }

    static func addPart(_ part: WorkOrderPart) async throws {
        try await supabase
            .from("work_order_parts")
            .insert(part)
            .execute()
    }

    static func updatePart(_ part: WorkOrderPart) async throws {
        try await supabase
            .from("work_order_parts")
            .update(part)
            .eq("id", value: part.id)
            .execute()
    }
}