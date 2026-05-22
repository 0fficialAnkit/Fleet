import Foundation
import Supabase

enum InspectionService {

    static func fetchAllInspections() async throws -> [VehicleInspection] {
        try await supabase
            .from("vehicle_inspections")
            .select()
            .execute()
            .value
    }

    static func fetchInspections(vehicleId: UUID) async throws -> [VehicleInspection] {
        try await supabase
            .from("vehicle_inspections")
            .select()
            .eq("vehicle_id", value: vehicleId)
            .execute()
            .value
    }

    static func fetchInspectionsForDriver(driverId: UUID) async throws -> [VehicleInspection] {
        try await supabase
            .from("vehicle_inspections")
            .select()
            .eq("driver_id", value: driverId)
            .execute()
            .value
    }

    static func createInspection(_ inspection: VehicleInspection) async throws {
        try await supabase
            .from("vehicle_inspections")
            .insert(inspection)
            .execute()
    }
}
