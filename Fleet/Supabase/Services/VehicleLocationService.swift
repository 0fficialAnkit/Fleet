import Foundation
import Supabase

enum VehicleLocationService {

    // MARK: - Driver side: push a location record

    private struct LocationInsert: Encodable {
        let id: UUID
        let vehicle_id: UUID
        let latitude: Double
        let longitude: Double
        let speed: Double?
        let recorded_at: Date
    }

    /// Called by the driver's ViewModel every N seconds during an active trip.
    /// Logs detailed errors to help diagnose RLS / network issues.
    @discardableResult
    static func insertLocation(vehicleId: UUID,
                               latitude: Double,
                               longitude: Double,
                               speed: Double?) async -> Bool {
        let payload = LocationInsert(
            id: UUID(),
            vehicle_id: vehicleId,
            latitude: latitude,
            longitude: longitude,
            speed: speed,
            recorded_at: Date()
        )
        do {
            try await supabase
                .from("vehicle_locations")
                .insert(payload)
                .execute()
            print("[VehicleLocationService] Inserted location for vehicle \(vehicleId) — lat:\(latitude) lon:\(longitude)")
            return true
        } catch {
            print("[VehicleLocationService] INSERT FAILED for vehicle \(vehicleId)")
            print("[VehicleLocationService]    Error: \(error)")
            print("[VehicleLocationService]    Localized: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Fleet manager side: fetch latest position per vehicle

    /// Returns the single most-recent location row for each of the given vehicle IDs.
    static func fetchLatestLocations(for vehicleIds: [UUID]) async throws -> [VehicleLocation] {
        guard !vehicleIds.isEmpty else { return [] }

        // Pull all rows for those vehicles, newest first
        let all: [VehicleLocation] = try await supabase
            .from("vehicle_locations")
            .select()
            .in("vehicle_id", values: vehicleIds)
            .order("recorded_at", ascending: false)
            .execute()
            .value

        // Keep only the most-recent row per vehicle
        var seen = Set<UUID>()
        return all.filter { seen.insert($0.vehicleId).inserted }
    }
}
