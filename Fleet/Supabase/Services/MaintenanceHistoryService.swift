import Foundation
import Supabase

enum MaintenanceHistoryService {

    static func fetchHistory(vehicleId: UUID) async throws -> [MaintenanceHistory] {
        try await supabase
            .from("maintenance_history")
            .select()
            .eq("vehicle_id", value: vehicleId)
            .order("completed_at", ascending: false)
            .execute()
            .value
    }

    static func fetchAllHistory() async throws -> [MaintenanceHistory] {
        try await supabase
            .from("maintenance_history")
            .select()
            .order("completed_at", ascending: false)
            .execute()
            .value
    }

    static func createHistory(_ history: MaintenanceHistory) async throws {
        try await supabase
            .from("maintenance_history")
            .insert(history)
            .execute()
    }
}
