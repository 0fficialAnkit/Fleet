import Foundation
import Supabase

enum GeofenceService {

    // MARK: - Zones

    static func createGeofence(_ g: TripGeofence) async throws {
        try await supabase.from("trip_geofences").insert(g).execute()
    }

    /// Active fences only (used during a live trip).
    static func fetchGeofences(forTrip tripId: UUID) async throws -> [TripGeofence] {
        try await supabase
            .from("trip_geofences").select()
            .eq("trip_id", value: tripId)
            .eq("is_active", value: true)
            .execute().value
    }

    /// All fences regardless of active state (used in order history / completed trips).
    static func fetchAllGeofences(forTrip tripId: UUID) async throws -> [TripGeofence] {
        try await supabase
            .from("trip_geofences").select()
            .eq("trip_id", value: tripId)
            .execute().value
    }

    static func deactivateGeofences(forTrip tripId: UUID) async throws {
        struct P: Encodable { let is_active = false }
        try await supabase.from("trip_geofences")
            .update(P()).eq("trip_id", value: tripId).execute()
    }

    // MARK: - Events

    static func createEvent(_ e: TripGeofenceEvent) async throws {
        try await supabase.from("trip_geofence_events").insert(e).execute()
    }

    static func fetchEvents(forVehicle vehicleId: UUID, limit: Int = 30) async throws -> [TripGeofenceEvent] {
        try await supabase
            .from("trip_geofence_events").select()
            .eq("vehicle_id", value: vehicleId)
            .order("occurred_at", ascending: false)
            .limit(limit)
            .execute().value
    }

    /// Fetch ALL events for a specific set of fence IDs (trip-scoped, no limit).
    /// Preferred over fetchEvents(forVehicle:) for zone restoration — avoids cross-trip
    /// contamination and the 30-event limit cutting off older events.
    static func fetchEvents(forFences fenceIds: [UUID]) async throws -> [TripGeofenceEvent] {
        guard !fenceIds.isEmpty else { return [] }
        return try await supabase
            .from("trip_geofence_events").select()
            .in("geofence_id", values: fenceIds.map { $0.uuidString })
            .order("occurred_at", ascending: false)
            .execute().value
    }
}
