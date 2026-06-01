import Foundation
import Supabase

enum GeofenceService {

    // MARK: - Geofences

    static func createGeofence(_ g: TripGeofence) async throws {
        try await supabase
            .from("trip_geofences")
            .insert(g)
            .execute()
    }

    static func fetchGeofences(forTrip tripId: UUID) async throws -> [TripGeofence] {
        try await supabase
            .from("trip_geofences")
            .select()
            .eq("trip_id", value: tripId)
            .eq("is_active", value: true)
            .execute()
            .value
    }

    static func deactivateGeofences(forTrip tripId: UUID) async throws {
        struct Update: Encodable { let is_active: Bool }
        try await supabase
            .from("trip_geofences")
            .update(Update(is_active: false))
            .eq("trip_id", value: tripId)
            .execute()
    }

    // MARK: - Events

    static func createEvent(_ e: TripGeofenceEvent) async throws {
        try await supabase
            .from("trip_geofence_events")
            .insert(e)
            .execute()
    }

    static func fetchRecentEvents(limit: Int = 50) async throws -> [TripGeofenceEvent] {
        try await supabase
            .from("trip_geofence_events")
            .select()
            .order("occurred_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    static func fetchEvents(forVehicle vehicleId: UUID) async throws -> [TripGeofenceEvent] {
        try await supabase
            .from("trip_geofence_events")
            .select()
            .eq("vehicle_id", value: vehicleId)
            .order("occurred_at", ascending: false)
            .execute()
            .value
    }
}
