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

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let t = TripService.fetchAllTrips()
            async let r = RouteService.fetchAllRoutes()
            async let p = ProfileService.fetchAllProfiles()
            async let v = VehicleService.fetchAllVehicles()
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
        case .active: return Color.yellow
        case .completed: return Color.green
        case .cancelled: return Color.red
        case .none: return Color(UIColor.quaternaryLabel)
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

    /// Returns all profiles with role == "driver"
    func driversWithRole() -> [Profile] {
        profiles.filter { $0.role == "driver" }
    }

    func availableVehicles(for orderType: OrderType) -> [Vehicle] {
        vehicles.filter { $0.status == .active }
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
