import Foundation
import Supabase

/// Manages Supabase Realtime subscriptions for live data updates.
/// ViewModels subscribe to changes via closures.
/// Uses arrays of handlers so multiple ViewModels can listen to the same table.
@MainActor
@Observable
final class RealtimeManager {

    static let shared = RealtimeManager()

    // MARK: - Multi-listener handler arrays
    private var tripsHandlers: [() -> Void] = []
    private var workOrdersHandlers: [() -> Void] = []
    private var maintenanceTasksHandlers: [() -> Void] = []
    private var defectReportsHandlers: [() -> Void] = []
    private var notificationsHandlers: [() -> Void] = []
    private var messagesHandlers: [() -> Void] = []
    private var vehicleLocationsHandlers: [() -> Void] = []
    private var vehiclesHandlers: [() -> Void] = []
    private var inventoryHandlers: [() -> Void] = []
    private var issueReportsHandlers: [() -> Void] = []
    private var profilesHandlers: [() -> Void] = []
    private var usersHandlers: [() -> Void] = []
    private var fuelLogsHandlers: [() -> Void] = []
    private var voiceTripLogsHandlers: [() -> Void] = []
    private var tripIncidentsHandlers: [() -> Void] = []
    private var geofenceEventsHandlers: [() -> Void] = []

    private var channels: [RealtimeChannelV2] = []

    private init() {}

    // MARK: - Add Handler Methods

    func addTripsChangeHandler(_ handler: @escaping () -> Void) {
        tripsHandlers.append(handler)
    }

    func addWorkOrdersChangeHandler(_ handler: @escaping () -> Void) {
        workOrdersHandlers.append(handler)
    }

    func addMaintenanceTasksChangeHandler(_ handler: @escaping () -> Void) {
        maintenanceTasksHandlers.append(handler)
    }

    func addDefectReportsChangeHandler(_ handler: @escaping () -> Void) {
        defectReportsHandlers.append(handler)
    }

    func addNotificationsChangeHandler(_ handler: @escaping () -> Void) {
        notificationsHandlers.append(handler)
    }

    func addMessagesChangeHandler(_ handler: @escaping () -> Void) {
        messagesHandlers.append(handler)
    }

    func addVehicleLocationsChangeHandler(_ handler: @escaping () -> Void) {
        vehicleLocationsHandlers.append(handler)
    }

    func addVehiclesChangeHandler(_ handler: @escaping () -> Void) {
        vehiclesHandlers.append(handler)
    }

    func addInventoryChangeHandler(_ handler: @escaping () -> Void) {
        inventoryHandlers.append(handler)
    }

    func addIssueReportsChangeHandler(_ handler: @escaping () -> Void) {
        issueReportsHandlers.append(handler)
    }

    func addProfilesChangeHandler(_ handler: @escaping () -> Void) {
        profilesHandlers.append(handler)
    }

    func addUsersChangeHandler(_ handler: @escaping () -> Void) {
        usersHandlers.append(handler)
    }

    func addFuelLogsChangeHandler(_ handler: @escaping () -> Void) {
        fuelLogsHandlers.append(handler)
    }

    func addVoiceTripLogsChangeHandler(_ handler: @escaping () -> Void) {
        voiceTripLogsHandlers.append(handler)
    }

    func addTripIncidentsChangeHandler(_ handler: @escaping () -> Void) {
        tripIncidentsHandlers.append(handler)
    }

    func addGeofenceEventsChangeHandler(_ handler: @escaping () -> Void) {
        geofenceEventsHandlers.append(handler)
    }

    // MARK: - Subscribe All

    func subscribeAll() async {
        await subscribe(table: "trips") { [weak self] in self?.tripsHandlers.forEach { $0() } }
        await subscribe(table: "work_orders") { [weak self] in self?.workOrdersHandlers.forEach { $0() } }
        await subscribe(table: "maintenance_tasks") { [weak self] in self?.maintenanceTasksHandlers.forEach { $0() } }
        await subscribe(table: "defect_reports") { [weak self] in self?.defectReportsHandlers.forEach { $0() } }
        await subscribe(table: "notifications") { [weak self] in self?.notificationsHandlers.forEach { $0() } }
        await subscribe(table: "messages") { [weak self] in self?.messagesHandlers.forEach { $0() } }
        await subscribe(table: "vehicle_locations") { [weak self] in self?.vehicleLocationsHandlers.forEach { $0() } }
        await subscribe(table: "vehicles") { [weak self] in self?.vehiclesHandlers.forEach { $0() } }
        await subscribe(table: "inventory") { [weak self] in self?.inventoryHandlers.forEach { $0() } }
        await subscribe(table: "issue_reports") { [weak self] in self?.issueReportsHandlers.forEach { $0() } }
        await subscribe(table: "profiles") { [weak self] in self?.profilesHandlers.forEach { $0() } }
        await subscribe(table: "users") { [weak self] in self?.usersHandlers.forEach { $0() } }
        await subscribe(table: "fuel_logs") { [weak self] in self?.fuelLogsHandlers.forEach { $0() } }
        await subscribe(table: "voice_trip_logs") { [weak self] in self?.voiceTripLogsHandlers.forEach { $0() } }
        await subscribe(table: "trip_incidents") { [weak self] in self?.tripIncidentsHandlers.forEach { $0() } }
        await subscribe(table: "trip_geofence_events") { [weak self] in self?.geofenceEventsHandlers.forEach { $0() } }
    }

    // MARK: - Subscribe to a single table

    private func subscribe(table: String, onChange: @escaping @MainActor @Sendable () -> Void) async {
        let channel = supabase.realtimeV2.channel("public:\(table)")

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: table
        )

        do {
            try await channel.subscribeWithError()
        } catch {
            print("[RealtimeManager] Subscription error for \(table): \(error)")
        }
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
        // Clear all handlers
        tripsHandlers.removeAll()
        workOrdersHandlers.removeAll()
        maintenanceTasksHandlers.removeAll()
        defectReportsHandlers.removeAll()
        notificationsHandlers.removeAll()
        messagesHandlers.removeAll()
        vehicleLocationsHandlers.removeAll()
        vehiclesHandlers.removeAll()
        inventoryHandlers.removeAll()
        issueReportsHandlers.removeAll()
        profilesHandlers.removeAll()
        usersHandlers.removeAll()
        fuelLogsHandlers.removeAll()
        voiceTripLogsHandlers.removeAll()
        tripIncidentsHandlers.removeAll()
        geofenceEventsHandlers.removeAll()
    }
}