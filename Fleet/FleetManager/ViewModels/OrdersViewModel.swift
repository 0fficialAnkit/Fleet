import SwiftUI

@MainActor
@Observable
final class OrdersViewModel {
    private(set) var trips: [Trip] = []
    private(set) var routes: [Route] = []
    private(set) var profiles: [Profile] = []
    private(set) var vehicles: [Vehicle] = []

    init(trips: [Trip] = [], routes: [Route] = [], profiles: [Profile] = [], vehicles: [Vehicle] = []) {
        self.trips = trips
        self.routes = routes
        self.profiles = profiles
        self.vehicles = vehicles
    }

    var isLoading = false
    var errorMessage: String?
    /// Set once on login from AuthViewModel.currentUserId
    var adminId: UUID?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let t = TripService.fetchAllTrips(adminId: adminId)
            async let r = RouteService.fetchAllRoutes(managerId: adminId)
            async let p = ProfileService.fetchAllProfiles(managerId: adminId)
            async let v = VehicleService.fetchAllVehicles(adminId: adminId)
            trips = try await t
            routes = try await r
            profiles = try await p
            vehicles = try await v
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        RealtimeManager.shared.addTripsChangeHandler { [weak self] in
            Task { await self?.loadData() }
        }
    }

    func getStatusColor(for status: TripStatus?) -> Color {
        switch status {
        case .scheduled: return Color.blue
        case .active: return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none: return Color(.quaternaryLabel)
        }
    }

    // MARK: - Lookup helpers

    func route(for routeId: UUID?) -> Route? {
        guard let id = routeId else { return nil }
        return routes.first { $0.id == id }
    }

    func driverName(for driverId: UUID?) -> String {
        guard let id = driverId else { return "Unassigned" }
        return profiles.first { $0.id == id }?.fullName ?? "Unassigned"
    }

    func vehicleName(for vehicleId: UUID) -> String {
        guard let v = vehicles.first(where: { $0.id == vehicleId }) else { return "Unknown Vehicle" }
        return "\(v.make ?? "") \(v.model ?? "")"
    }

    // MARK: - Legacy helpers (used by old multi-step flow views)

    /// Returns all driver profiles with no date-based conflict filtering.
    func driversWithRole() -> [Profile] {
        profiles.filter { $0.role == "driver" }
    }

    /// Returns all active vehicles with no date conflict filtering.
    func availableVehicles(for orderType: OrderType) -> [Vehicle] {
        vehicles.filter { $0.status == .active }
    }

    // MARK: - Conflict-aware availability

    /// Vehicles that are active status AND not already on a trip on the given date.
    /// - Active trips block the vehicle regardless of date (they're in use right now).
    /// - Scheduled trips block only when the selected date falls on the same calendar day.
    func availableVehicles(for orderType: OrderType, at date: Date) -> [Vehicle] {
        let busyIds = busyVehicleIds(at: date)
        return vehicles.filter { $0.status == .active && !busyIds.contains($0.id) }
    }

    /// Drivers that are not already assigned to a trip on the given date.
    func availableDrivers(at date: Date) -> [Profile] {
        let busyIds = busyDriverIds(at: date)
        return profiles.filter { $0.role == "driver" && !busyIds.contains($0.id) }
    }

    private func busyVehicleIds(at date: Date) -> Set<UUID> {
        Set(trips.filter { isConflicting($0, with: date) }.map { $0.vehicleId })
    }

    private func busyDriverIds(at date: Date) -> Set<UUID> {
        Set(trips.filter { isConflicting($0, with: date) }.compactMap { $0.driverId })
    }

    /// Returns true if a trip blocks usage on the given date.
    private func isConflicting(_ trip: Trip, with date: Date) -> Bool {
        switch trip.status {
        case .active:
            // Currently running — always blocks, regardless of selected date
            return true
        case .scheduled:
            // Only blocks if the scheduled day matches the selected day
            guard let tripDate = trip.startTime else { return false }
            return Calendar.current.isDate(tripDate, inSameDayAs: date)
        default:
            // Completed / cancelled / nil — not a conflict
            return false
        }
    }

    func addTrip(vehicleId: UUID, driverId: UUID, routeId: UUID?, startTime: Date, orderType: OrderType) async throws {
        let newTrip = Trip(
            id: UUID(),
            vehicleId: vehicleId,
            driverId: driverId,
            routeId: routeId,
            startTime: startTime,
            endTime: nil,
            distance: nil,
            status: .scheduled,
            orderType: orderType
        )
        try await TripService.createTrip(newTrip)
        // Send notification to driver
        let notification = Notification(
            id: UUID(),
            userId: driverId,
            title: "Trip Scheduled",
            message: "A new \(orderType.displayName) trip has been assigned to you.",
            type: .info,
            isRead: false,
            referenceId: newTrip.id,
            createdAt: Date()
        )
        try? await NotificationService.createNotification(notification)

        // Assign driver to vehicle
        try? await VehicleService.assignDriver(vehicleId: vehicleId, driverId: driverId)

        await loadData()
    }

    func deleteTrip(_ trip: Trip) async throws {
        try await TripService.deleteTrip(id: trip.id)
        await loadData()
    }
}