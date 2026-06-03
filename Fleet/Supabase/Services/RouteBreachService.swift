import Foundation
import Supabase

enum RouteBreachService {

    static func logBreach(_ breach: RouteBreach) async throws {
        try await supabase.from("route_breach_events").insert(breach).execute()
    }

    /// Fetch all breaches for a specific trip (fleet manager order detail).
    static func fetchBreaches(forTrip tripId: UUID) async throws -> [RouteBreach] {
        try await supabase
            .from("route_breach_events")
            .select()
            .eq("trip_id", value: tripId)
            .order("occurred_at", ascending: true)
            .execute().value
    }

    /// Fetch all breaches for a specific driver across ALL trips (driver history).
    static func fetchBreaches(forDriver driverId: UUID) async throws -> [RouteBreach] {
        try await supabase
            .from("route_breach_events")
            .select()
            .eq("driver_id", value: driverId)
            .order("occurred_at", ascending: false)
            .execute().value
    }
}
