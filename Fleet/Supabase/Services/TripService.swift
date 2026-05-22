import Foundation
import Supabase

enum TripService {

    static func fetchAllTrips() async throws -> [Trip] {
        try await supabase
            .from("trips")
            .select()
            .execute()
            .value
    }

    static func fetchTripsForDriver(driverId: UUID) async throws -> [Trip] {
        try await supabase
            .from("trips")
            .select()
            .eq("driver_id", value: driverId)
            .execute()
            .value
    }

    static func fetchTripsForVehicle(vehicleId: UUID) async throws -> [Trip] {
        try await supabase
            .from("trips")
            .select()
            .eq("vehicle_id", value: vehicleId)
            .execute()
            .value
    }

    static func createTrip(_ trip: Trip) async throws {
        try await supabase
            .from("trips")
            .insert(trip)
            .execute()
    }

    static func updateTrip(_ trip: Trip) async throws {
        try await supabase
            .from("trips")
            .update(trip)
            .eq("id", value: trip.id)
            .execute()
    }

    static func updateTripStatus(id: UUID, status: TripStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: TripStatus
        }
        try await supabase
            .from("trips")
            .update(StatusUpdate(status: status))
            .eq("id", value: id)
            .execute()
    }

    static func updateTripTimes(id: UUID, startTime: Date?, endTime: Date?) async throws {
        struct TimeUpdate: Encodable {
            let start_time: Date?
            let end_time: Date?
        }
        try await supabase
            .from("trips")
            .update(TimeUpdate(start_time: startTime, end_time: endTime))
            .eq("id", value: id)
            .execute()
    }

    static func startTrip(id: UUID) async throws {
        struct StartUpdate: Encodable {
            let status: TripStatus
            let start_time: Date
        }
        try await supabase
            .from("trips")
            .update(StartUpdate(status: .active, start_time: Date()))
            .eq("id", value: id)
            .execute()
    }

    static func endTrip(id: UUID) async throws {
        struct EndUpdate: Encodable {
            let status: TripStatus
            let end_time: Date
        }
        try await supabase
            .from("trips")
            .update(EndUpdate(status: .completed, end_time: Date()))
            .eq("id", value: id)
            .execute()
    }

    static func deleteTrip(id: UUID) async throws {
        try await supabase
            .from("trips")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
