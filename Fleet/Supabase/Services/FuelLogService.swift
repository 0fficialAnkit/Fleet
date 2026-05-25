import Foundation
import Supabase

enum FuelLogService {

    static func fetchFuelLogs(driverId: UUID) async throws -> [FuelLog] {
        try await supabase
            .from("fuel_logs")
            .select()
            .eq("driver_id", value: driverId)
            .order("recorded_at", ascending: false)
            .execute()
            .value
    }

    static func fetchFuelLogs(vehicleId: UUID) async throws -> [FuelLog] {
        try await supabase
            .from("fuel_logs")
            .select()
            .eq("vehicle_id", value: vehicleId)
            .order("recorded_at", ascending: false)
            .execute()
            .value
    }

    static func fetchAllFuelLogs() async throws -> [FuelLog] {
        try await supabase
            .from("fuel_logs")
            .select()
            .order("recorded_at", ascending: false)
            .execute()
            .value
    }

    static func createFuelLog(_ log: FuelLog) async throws {
        try await supabase
            .from("fuel_logs")
            .insert(log)
            .execute()
    }
}
