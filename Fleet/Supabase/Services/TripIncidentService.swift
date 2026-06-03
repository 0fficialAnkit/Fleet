import Foundation
import Supabase

enum TripIncidentService {
    
    /// Create a new trip incident in the database
    static func createIncident(_ incident: TripIncident) async throws {
        do {
            try await supabase
                .from("trip_incidents")
                .insert(incident)
                .execute()
            print("[TripIncidentService] createIncident(\(incident.id)): OK")
        } catch {
            print("[TripIncidentService] createIncident ERROR: \(error)")
            throw error
        }
    }
    
    /// Fetch all incidents for a specific trip
    static func fetchIncidents(forTripId tripId: UUID) async throws -> [TripIncident] {
        do {
            let result: [TripIncident] = try await supabase
                .from("trip_incidents")
                .select()
                .eq("trip_id", value: tripId)
                .order("created_at", ascending: false)
                .execute()
                .value
            print("[TripIncidentService] fetchIncidents for trip \(tripId): \(result.count) items")
            return result
        } catch {
            print("[TripIncidentService] fetchIncidents ERROR: \(error)")
            throw error
        }
    }

    /// Fetch the most recent voice-reported incidents across all trips (fleet manager dashboard).
    static func fetchRecentVoiceIncidents(limit: Int = 5) async throws -> [TripIncident] {
        do {
            let result: [TripIncident] = try await supabase
                .from("trip_incidents")
                .select()
                .eq("source", value: "voice")
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            print("[TripIncidentService] fetchRecentVoiceIncidents: \(result.count) items")
            return result
        } catch {
            print("[TripIncidentService] fetchRecentVoiceIncidents ERROR: \(error)")
            throw error
        }
    }
}

