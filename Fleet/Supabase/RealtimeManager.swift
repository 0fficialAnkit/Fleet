import Foundation
import Supabase
import Realtime

/// Manages Supabase Realtime subscriptions for live data updates.
/// ViewModels subscribe to changes via closures.
@MainActor
@Observable
final class RealtimeManager {

    static let shared = RealtimeManager()

    // MARK: - Change callbacks (nonisolated to avoid Sendable issues)

    nonisolated(unsafe) var onTripsChange: (() -> Void)?
    nonisolated(unsafe) var onWorkOrdersChange: (() -> Void)?
    nonisolated(unsafe) var onMaintenanceTasksChange: (() -> Void)?
    nonisolated(unsafe) var onDefectReportsChange: (() -> Void)?
    nonisolated(unsafe) var onNotificationsChange: (() -> Void)?
    nonisolated(unsafe) var onMessagesChange: (() -> Void)?
    nonisolated(unsafe) var onVehicleLocationsChange: (() -> Void)?
    nonisolated(unsafe) var onVehiclesChange: (() -> Void)?
    nonisolated(unsafe) var onInventoryChange: (() -> Void)?

    private var channels: [RealtimeChannelV2] = []

    private init() {}

    // MARK: - Subscribe All

    func subscribeAll() async {
        await subscribe(table: "trips") { [weak self] in self?.onTripsChange?() }
        await subscribe(table: "work_orders") { [weak self] in self?.onWorkOrdersChange?() }
        await subscribe(table: "maintenance_tasks") { [weak self] in self?.onMaintenanceTasksChange?() }
        await subscribe(table: "defect_reports") { [weak self] in self?.onDefectReportsChange?() }
        await subscribe(table: "notifications") { [weak self] in self?.onNotificationsChange?() }
        await subscribe(table: "messages") { [weak self] in self?.onMessagesChange?() }
        await subscribe(table: "vehicle_locations") { [weak self] in self?.onVehicleLocationsChange?() }
        await subscribe(table: "vehicles") { [weak self] in self?.onVehiclesChange?() }
        await subscribe(table: "inventory") { [weak self] in self?.onInventoryChange?() }
    }

    // MARK: - Subscribe to a single table

    private func subscribe(table: String, onChange: @escaping @Sendable () -> Void) async {
        let channel = supabase.realtimeV2.channel("public:\(table)")

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: table
        )

        await channel.subscribe()
        channels.append(channel)

        Task { [weak self] in
            for await _ in changes {
                guard self != nil else { break }
                await MainActor.run {
                    onChange()
                }
            }
        }
    }

    // MARK: - Unsubscribe

    func unsubscribeAll() async {
        for channel in channels {
            await channel.unsubscribe()
        }
        channels.removeAll()
    }
}
