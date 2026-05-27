import Foundation
import Supabase

// MARK: - VehicleInsert
// Only sends columns that exist in the vehicles table.
// DO NOT add purchase_date here — it is not in the Supabase schema for this sprint.
private struct VehicleInsert: Encodable {
    let id: UUID
    let make: String?
    let model: String?
    let year: Int?
    let vin: String?
    let license_plate: String?
    let tank_capacity: Double?
    let mileage: Double?
    let assigned_driver_id: UUID?  // nil → sends null (never empty string)
    let admin_id: UUID?
    let status: VehicleStatus?
}

// MARK: - VehicleUpdate
private struct VehicleUpdate: Encodable {
    let make: String?
    let model: String?
    let year: Int?
    let vin: String?
    let license_plate: String?
    let tank_capacity: Double?
    let mileage: Double?
    let assigned_driver_id: UUID?
    let admin_id: UUID?
    let status: VehicleStatus?
}

enum VehicleService {

    static func fetchAllVehicles() async throws -> [Vehicle] {
        do {
            let result: [Vehicle] = try await supabase
                .from("vehicles")
                .select()
                .execute()
                .value
            print("[VehicleService] fetchAllVehicles: \(result.count) vehicles loaded")
            return result
        } catch {
            print("[VehicleService] fetchAllVehicles ERROR: \(error)")
            throw error
        }
    }

    static func fetchVehicle(id: UUID) async throws -> Vehicle {
        do {
            let result: Vehicle = try await supabase
                .from("vehicles")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            print("[VehicleService] fetchVehicle(\(id)): OK")
            return result
        } catch {
            print("[VehicleService] fetchVehicle(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func fetchVehicleForDriver(driverId: UUID) async throws -> Vehicle? {
        do {
            let vehicles: [Vehicle] = try await supabase
                .from("vehicles")
                .select()
                .eq("assigned_driver_id", value: driverId)
                .execute()
                .value
            print("[VehicleService] fetchVehicleForDriver(\(driverId)): found \(vehicles.count)")
            return vehicles.first
        } catch {
            print("[VehicleService] fetchVehicleForDriver(\(driverId)) ERROR: \(error)")
            throw error
        }
    }

    /// Safe insert — only sends columns that exist in the vehicles table.
    static func createVehicle(
        make: String?,
        model: String?,
        year: Int?,
        vin: String?,
        licensePlate: String?,
        tankCapacity: Double?,
        mileage: Double?,
        assignedDriverId: UUID?,
        adminId: UUID? = nil,
        status: VehicleStatus?
    ) async throws {
        let payload = VehicleInsert(
            id: UUID(),
            make: make,
            model: model,
            year: year,
            vin: vin,
            license_plate: licensePlate,
            tank_capacity: tankCapacity,
            mileage: mileage,
            assigned_driver_id: assignedDriverId, // nil → null, never empty string
            admin_id: adminId,
            status: status
        )
        do {
            try await supabase
                .from("vehicles")
                .insert(payload)
                .execute()
            print("[VehicleService] createVehicle: OK — \(make ?? "?") \(model ?? "?")")
        } catch {
            print("[VehicleService] createVehicle ERROR: \(error)")
            throw error
        }
    }

    static func updateVehicle(_ vehicle: Vehicle) async throws {
        let payload = VehicleUpdate(
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            vin: vehicle.vin,
            license_plate: vehicle.licensePlate,
            tank_capacity: vehicle.tankCapacity,
            mileage: vehicle.mileage,
            assigned_driver_id: vehicle.assignedDriverId,
            admin_id: vehicle.adminId,
            status: vehicle.status
        )
        do {
            try await supabase
                .from("vehicles")
                .update(payload)
                .eq("id", value: vehicle.id)
                .execute()
            print("[VehicleService] updateVehicle(\(vehicle.id)): OK")
        } catch {
            print("[VehicleService] updateVehicle(\(vehicle.id)) ERROR: \(error)")
            throw error
        }
    }

    static func deleteVehicle(id: UUID) async throws {
        do {
            try await supabase
                .from("vehicles")
                .delete()
                .eq("id", value: id)
                .execute()
            print("[VehicleService] deleteVehicle(\(id)): OK")
        } catch {
            print("[VehicleService] deleteVehicle(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func assignDriver(vehicleId: UUID, driverId: UUID?) async throws {
        struct DriverUpdate: Encodable {
            let assigned_driver_id: UUID?
        }
        do {
            try await supabase
                .from("vehicles")
                .update(DriverUpdate(assigned_driver_id: driverId))
                .eq("id", value: vehicleId)
                .execute()
            print("[VehicleService] assignDriver vehicleId=\(vehicleId) driverId=\(String(describing: driverId)): OK")
        } catch {
            print("[VehicleService] assignDriver ERROR: \(error)")
            throw error
        }
    }
}