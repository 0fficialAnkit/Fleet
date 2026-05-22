import SwiftUI

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var vehicles: [Vehicle] = []
    private(set) var trips: [Trip] = []
    private(set) var workOrders: [WorkOrder] = []
    private(set) var routes: [Route] = []
    private(set) var users: [User] = []
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
            async let u = UserService.fetchAllUsers()
            async let m = MaintenanceTaskService.fetchAllTasks()
            vehicles = try await v
            trips = try await t
            workOrders = try await w
            routes = try await r
            users = try await u
            maintenanceTasks = try await m
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.onTripsChange = { [weak self] in Task { await self?.loadData() } }
        rt.onWorkOrdersChange = { [weak self] in Task { await self?.loadData() } }
        rt.onVehiclesChange = { [weak self] in Task { await self?.loadData() } }
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
        Array(trips.prefix(3))
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
        return users.first { $0.id == id }?.fullName ?? "Unassigned"
    }

    func maintenanceTask(for vehicleId: UUID) -> MaintenanceTask? {
        maintenanceTasks.first { $0.vehicleId == vehicleId && $0.status != .completed }
    }
}
