//
//  VoiceTripLogService.swift
//  Fleet
//
//  Supabase CRUD for the `voice_trip_logs` table.
//

import Foundation
import Supabase

enum VoiceTripLogService {

    /// Saves a new voice log record to Supabase.
    static func saveLog(_ log: VoiceTripLog) async throws {
        do {
            try await supabase
                .from("voice_trip_logs")
                .insert(log)
                .execute()
            print("[VoiceTripLogService] saveLog(\(log.id)): OK")
        } catch {
            print("[VoiceTripLogService] saveLog ERROR: \(error)")
            throw error
        }
    }

    /// Fetches all voice logs for a specific trip, newest first.
    static func fetchLogs(forTripId tripId: UUID) async throws -> [VoiceTripLog] {
        do {
            let result: [VoiceTripLog] = try await supabase
                .from("voice_trip_logs")
                .select()
                .eq("trip_id", value: tripId)
                .order("created_at", ascending: false)
                .execute()
                .value
            print("[VoiceTripLogService] fetchLogs for trip \(tripId): \(result.count) items")
            return result
        } catch {
            print("[VoiceTripLogService] fetchLogs ERROR: \(error)")
            throw error
        }
    }

    /// Fetches the most recent voice logs across all trips (used by fleet manager dashboard).
    static func fetchAllRecentLogs(limit: Int = 10) async throws -> [VoiceTripLog] {
        do {
            let result: [VoiceTripLog] = try await supabase
                .from("voice_trip_logs")
                .select()
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            print("[VoiceTripLogService] fetchAllRecentLogs: \(result.count) items")
            return result
        } catch {
            print("[VoiceTripLogService] fetchAllRecentLogs ERROR: \(error)")
            throw error
        }
    }
}
