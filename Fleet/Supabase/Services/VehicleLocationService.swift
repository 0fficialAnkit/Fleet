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
    /// Silently swallows errors so a network blip never crashes the trip.
    static func insertLocation(vehicleId: UUID,
                               latitude: Double,
                               longitude: Double,
                               speed: Double?) async {
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
        } catch {
            print("[VehicleLocationService] insertLocation error: \(error.localizedDescription)")
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
