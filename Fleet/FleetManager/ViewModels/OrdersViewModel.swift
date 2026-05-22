import SwiftUI

@MainActor
@Observable
final class OrdersViewModel {
    private(set) var trips: [Trip] = []
    private(set) var routes: [Route] = []
    private(set) var users: [User] = []
    private(set) var vehicles: [Vehicle] = []

    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let t = TripService.fetchAllTrips()
            async let r = RouteService.fetchAllRoutes()
            async let u = UserService.fetchAllUsers()
            async let v = VehicleService.fetchAllVehicles()
            trips = try await t
            routes = try await r
            users = try await u
            vehicles = try await v
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        RealtimeManager.shared.onTripsChange = { [weak self] in
            Task { await self?.loadData() }
        }
    }

    func getStatusColor(for status: TripStatus?) -> Color {
        switch status {
        case .scheduled: return themeModel.info
        case .active: return themeModel.warning
        case .completed: return themeModel.success
        case .cancelled: return themeModel.danger
        case .none: return themeModel.textDisabled
        }
    }

    // MARK: - Lookup helpers

    func route(for routeId: UUID?) -> Route? {
        guard let id = routeId else { return nil }
        return routes.first { $0.id == id }
    }

    func driverName(for driverId: UUID?) -> String {
        guard let id = driverId else { return "Unassigned" }
        return users.first { $0.id == id }?.fullName ?? "Unassigned"
    }

    func vehicleName(for vehicleId: UUID) -> String {
        guard let v = vehicles.first(where: { $0.id == vehicleId }) else { return "Unknown Vehicle" }
        return "\(v.make ?? "") \(v.model ?? "")"
    }

    func driversWithRole() -> [User] {
        let driverRoleId = roles().first { $0.roleName.lowercased() == "driver" }?.id
        guard let roleId = driverRoleId else { return [] }
        return users.filter { $0.roleId == roleId }
    }

    func roles() -> [Role] {
        // We can't easily fetch roles separately in a computed, so we rely on them being pre-loaded
        // The OrdersViewModel loads users; roles can be fetched alongside
        return []
    }

    func availableVehicles(for orderType: OrderType) -> [Vehicle] {
        vehicles.filter { vehicle in
            guard vehicle.status == .active else { return false }
            let model = (vehicle.model ?? "").lowercased()
            switch orderType {
            case .bulkOrderShip:
                return model.contains("prima") || model.contains("boss") || model.contains("blazo")
            case .pickUpAndDrop:
                return model.contains("ace") || model.contains("traveller")
            case .travel:
                return model.contains("traveller")
            }
        }
    }

    func addTrip(vehicleId: UUID, driverId: UUID, routeId: UUID?, startTime: Date, orderType: OrderType) {
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
        Task {
            do {
                try await TripService.createTrip(newTrip)
                // Send notification to driver
                let notification = Notification(
                    id: UUID(),
                    userId: driverId,
                    title: "Trip Scheduled",
                    message: "A new \(orderType.rawValue) trip has been assigned to you.",
                    type: .info,
                    isRead: false,
                    createdAt: Date()
                )
                try? await NotificationService.createNotification(notification)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func deleteTrip(_ trip: Trip) {
        Task {
            do {
                try await TripService.deleteTrip(id: trip.id)
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
