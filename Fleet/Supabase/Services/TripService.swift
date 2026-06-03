import Foundation
import Supabase

// MARK: - TripInsert
// Explicit insert struct — excludes id (optional) to let DB generate it,
// but here we supply it to have a deterministic UUID.
private struct TripInsert: Encodable {
    let id: UUID
    let vehicle_id: UUID
    let driver_id: UUID?
    let route_id: UUID?
    let start_time: Date?
    let end_time: Date?
    let distance: Double?
    let status: TripStatus?
    let order_type: OrderType?
}

enum TripService {

    static func fetchTrip(id: UUID) async throws -> Trip? {
        do {
            let result: [Trip] = try await supabase
                .from("trips")
                .select()
                .eq("id", value: id)
                .execute()
                .value
            return result.first
        } catch {
            print("[TripService] fetchTrip(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func fetchAllTrips() async throws -> [Trip] {
        do {
            let result: [Trip] = try await supabase
                .from("trips")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            print("[TripService] fetchAllTrips: \(result.count) trips")
            return result
        } catch {
            print("[TripService] fetchAllTrips ERROR: \(error)")
            throw error
        }
    }

    static func fetchTripsForDriver(driverId: UUID) async throws -> [Trip] {
        do {
            let result: [Trip] = try await supabase
                .from("trips")
                .select()
                .eq("driver_id", value: driverId)
                .order("start_time", ascending: false)
                .execute()
                .value
            print("[TripService] fetchTripsForDriver(\(driverId)): \(result.count) trips")
            return result
        } catch {
            print("[TripService] fetchTripsForDriver(\(driverId)) ERROR: \(error)")
            throw error
        }
    }

    static func fetchTripsForVehicle(vehicleId: UUID) async throws -> [Trip] {
        do {
            let result: [Trip] = try await supabase
                .from("trips")
                .select()
                .eq("vehicle_id", value: vehicleId)
                .execute()
                .value
            print("[TripService] fetchTripsForVehicle(\(vehicleId)): \(result.count) trips")
            return result
        } catch {
            print("[TripService] fetchTripsForVehicle(\(vehicleId)) ERROR: \(error)")
            throw error
        }
    }

    /// Safe insert — uses explicit struct to avoid sending unknown columns.
    static func createTrip(_ trip: Trip) async throws {
        let payload = TripInsert(
            id: trip.id,
            vehicle_id: trip.vehicleId,
            driver_id: trip.driverId,      // nil → null, never empty string
            route_id: trip.routeId,         // nil → null, never empty string
            start_time: trip.startTime,
            end_time: trip.endTime,
            distance: trip.distance,
            status: trip.status,
            order_type: trip.orderType
        )
        do {
            try await supabase
                .from("trips")
                .insert(payload)
                .execute()
            print("[TripService] createTrip(\(trip.id)): OK driverId=\(String(describing: trip.driverId))")
        } catch {
            print("[TripService] createTrip ERROR: \(error)")
            throw error
        }
    }

    static func updateTrip(_ trip: Trip) async throws {
        do {
            try await supabase
                .from("trips")
                .update(trip)
                .eq("id", value: trip.id)
                .execute()
            print("[TripService] updateTrip(\(trip.id)): OK")
        } catch {
            print("[TripService] updateTrip(\(trip.id)) ERROR: \(error)")
            throw error
        }
    }

    static func updateTripStatus(id: UUID, status: TripStatus) async throws {
        struct StatusUpdate: Encodable {
            let status: TripStatus
        }
        do {
            try await supabase
                .from("trips")
                .update(StatusUpdate(status: status))
                .eq("id", value: id)
                .execute()
            print("[TripService] updateTripStatus(\(id)) → \(status.rawValue): OK")
        } catch {
            print("[TripService] updateTripStatus(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func updateTripTimes(id: UUID, startTime: Date?, endTime: Date?) async throws {
        struct TimeUpdate: Encodable {
            let start_time: Date?
            let end_time: Date?
        }
        do {
            try await supabase
                .from("trips")
                .update(TimeUpdate(start_time: startTime, end_time: endTime))
                .eq("id", value: id)
                .execute()
            print("[TripService] updateTripTimes(\(id)): OK")
        } catch {
            print("[TripService] updateTripTimes(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func startTrip(id: UUID) async throws {
        struct StartUpdate: Encodable {
            let status: TripStatus
            let start_time: Date
        }
        do {
            try await supabase
                .from("trips")
                .update(StartUpdate(status: .active, start_time: Date()))
                .eq("id", value: id)
                .execute()
            print("[TripService] startTrip(\(id)): OK")
        } catch {
            print("[TripService] startTrip(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func endTrip(id: UUID, distance: Double? = nil) async throws {
        struct EndUpdate: Encodable {
            let status: TripStatus
            let end_time: Date
            let distance: Double?
        }
        do {
            try await supabase
                .from("trips")
                .update(EndUpdate(status: .completed, end_time: Date(), distance: distance))
                .eq("id", value: id)
                .execute()
            print("[TripService] endTrip(\(id)) with distance \(String(describing: distance)): OK")
        } catch {
            print("[TripService] endTrip(\(id)) ERROR: \(error)")
            throw error
        }
    }

    /// Updates the recorded distance of a trip.
    /// Called by the voice logging flow when a driver speaks their current mileage.
    static func updateTripDistance(id: UUID, distance: Double) async throws {
        struct DistanceUpdate: Encodable { let distance: Double }
        do {
            try await supabase
                .from("trips")
                .update(DistanceUpdate(distance: distance))
                .eq("id", value: id)
                .execute()
            print("[TripService] updateTripDistance(\(id)) → \(distance) km: OK")
        } catch {
            print("[TripService] updateTripDistance(\(id)) ERROR: \(error)")
            throw error
        }
    }

    static func deleteTrip(id: UUID) async throws {
        do {
            try await supabase
                .from("trips")
                .delete()
                .eq("id", value: id)
                .execute()
            print("[TripService] deleteTrip(\(id)): OK")
        } catch {
            print("[TripService] deleteTrip(\(id)) ERROR: \(error)")
            throw error
        }
    }
}