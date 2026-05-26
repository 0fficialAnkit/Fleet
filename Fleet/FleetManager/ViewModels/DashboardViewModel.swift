import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var vehicles: [Vehicle] = []
    private(set) var trips: [Trip] = []
    private(set) var workOrders: [WorkOrder] = []
    private(set) var routes: [Route] = []
    private(set) var profiles: [Profile] = []
    private(set) var maintenanceTasks: [MaintenanceTask] = []

    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let v = VehicleService.fetchAllVehicles()
            async let t = TripService.fetchAllTrips()
            async let w = WorkOrderService.fetchAllWorkOrders()
            async let r = RouteService.fetchAllRoutes()
            async let p = ProfileService.fetchAllProfiles()
            async let m = MaintenanceTaskService.fetchAllTasks()
            vehicles = try await v
            trips = try await t
            workOrders = try await w
            routes = try await r
            profiles = try await p
            maintenanceTasks = try await m
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addWorkOrdersChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addMaintenanceTasksChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addProfilesChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    // MARK: - Computed

    var totalVehicles: Int { vehicles.count }

    var activeTrips: Int {
        trips.filter { $0.status == .active }.count
    }

    var pendingOrders: Int {
        trips.filter { $0.status == .scheduled }.count
    }

    var driversOnTrip: Int {
        Set(trips.filter { $0.status == .active }.compactMap { $0.driverId }).count
    }

    var recentOrders: [Trip] {
        let sorted = trips.sorted {
            let lhs = $0.startTime ?? .distantPast
            let rhs = $1.startTime ?? .distantPast
            return lhs > rhs
        }
        return Array(sorted.prefix(3))
    }

    var maintenanceVehicles: [Vehicle] {
        vehicles.filter { $0.status == .maintenance }
    }

    // MARK: - Lookup helpers

    func routeName(for routeId: UUID?) -> String {
        guard let id = routeId else { return "Unknown Route" }
        return routes.first { $0.id == id }?.routeName ?? "Unknown Route"
    }

    func driverName(for driverId: UUID?) -> String {
        guard let id = driverId else { return "Unassigned" }
        return profiles.first { $0.id == id }?.fullName ?? "Unassigned"
    }

    func maintenanceTask(for vehicleId: UUID) -> MaintenanceTask? {
        maintenanceTasks.first { $0.vehicleId == vehicleId && $0.status != .completed }
    }
}

enum DashboardDestination: Hashable {
    case vehiclesRoot
    case orderDetail(Trip)
}