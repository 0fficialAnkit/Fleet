//
//  TripUpdateService.swift
//  Fleet
//
//  Supabase CRUD for the `trip_updates` table.
//

import Foundation
import Supabase

enum TripUpdateService {

    /// Inserts a new trip update record into the database.
    static func createUpdate(_ update: TripUpdate) async throws {
        do {
            try await supabase
                .from("trip_updates")
                .insert(update)
                .execute()
            print("[TripUpdateService] createUpdate(\(update.id)) type=\(update.updateType?.rawValue ?? "nil"): OK")
        } catch {
            print("[TripUpdateService] createUpdate ERROR: \(error)")
            throw error
        }
    }

    /// Fetches all updates for a given trip, newest first.
    static func fetchUpdates(forTripId tripId: UUID) async throws -> [TripUpdate] {
        do {
            let result: [TripUpdate] = try await supabase
                .from("trip_updates")
                .select()
                .eq("trip_id", value: tripId)
                .order("created_at", ascending: false)
                .execute()
                .value
            print("[TripUpdateService] fetchUpdates for trip \(tripId): \(result.count) items")
            return result
        } catch {
            print("[TripUpdateService] fetchUpdates ERROR: \(error)")
            throw error
        }
    }
}
