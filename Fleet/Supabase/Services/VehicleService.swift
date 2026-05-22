import Foundation
import Supabase

enum VehicleService {

    static func fetchAllVehicles() async throws -> [Vehicle] {
        try await supabase
            .from("vehicles")
            .select()
            .execute()
            .value
    }

    static func fetchVehicle(id: UUID) async throws -> Vehicle {
        try await supabase
            .from("vehicles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    static func fetchVehicleForDriver(driverId: UUID) async throws -> Vehicle? {
        let vehicles: [Vehicle] = try await supabase
            .from("vehicles")
            .select()
            .eq("assigned_driver_id", value: driverId)
            .execute()
            .value
        return vehicles.first
    }

    static func createVehicle(_ vehicle: Vehicle) async throws {
        try await supabase
            .from("vehicles")
            .insert(vehicle)
            .execute()
    }

    static func updateVehicle(_ vehicle: Vehicle) async throws {
        try await supabase
            .from("vehicles")
            .update(vehicle)
            .eq("id", value: vehicle.id)
            .execute()
    }

    static func deleteVehicle(id: UUID) async throws {
        try await supabase
            .from("vehicles")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    static func assignDriver(vehicleId: UUID, driverId: UUID?) async throws {
        struct DriverUpdate: Encodable {
            let assigned_driver_id: UUID?
        }
        try await supabase
            .from("vehicles")
            .update(DriverUpdate(assigned_driver_id: driverId))
            .eq("id", value: vehicleId)
            .execute()
    }
}
