import SwiftUI
import UserNotifications

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var vehicles: [Vehicle] = []
    private(set) var trips: [Trip] = []
    private(set) var workOrders: [WorkOrder] = []
    private(set) var routes: [Route] = []
    private(set) var profiles: [Profile] = []
    private(set) var maintenanceTasks: [MaintenanceTask] = []
    private(set) var vehicleLocations: [VehicleLocation] = []
    private(set) var inspections: [VehicleInspection] = []
    private(set) var issueReports: [IssueReportRecord] = []
    private(set) var maintenanceHistory: [MaintenanceHistory] = []

    /// Predictive alerts derived by the on-device rules engine after each data load.
    private(set) var predictiveAlerts: [PredictiveMaintenanceAlert] = []

    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let v  = VehicleService.fetchAllVehicles()
            async let t  = TripService.fetchAllTrips()
            async let w  = WorkOrderService.fetchAllWorkOrders()
            async let r  = RouteService.fetchAllRoutes()
            async let p  = ProfileService.fetchAllProfiles()
            async let m  = MaintenanceTaskService.fetchAllTasks()
            async let i  = InspectionService.fetchAllInspections()
            async let ir = IssueReportService.fetchAllIssueReports()
            async let mh = MaintenanceHistoryService.fetchAllHistory()
            let fetchedVehicles   = try await v
            trips              = try await t
            workOrders         = try await w
            routes             = try await r
            profiles           = try await p
            maintenanceTasks   = try await m
            inspections        = try await i
            issueReports       = try await ir
            maintenanceHistory = try await mh

            // Sync the shared VehiclesViewModel so Dashboard and Vehicles tab
            // always show the same list.
            VehiclesViewModel.shared.vehicles = fetchedVehicles
            vehicles = VehiclesViewModel.shared.vehicles
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        
        // --- INJECT MOCK DATA FOR DEMO PURPOSES ---
        let mockVehicleId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let mockVehicle = Vehicle(
            id: mockVehicleId,
            make: "Honda",
            model: "Activa (Mock)",
            year: 2024,
            vin: "MOCK1234",
            licensePlate: "MH-12-AB-1234",
            tankCapacity: 5,
            mileage: 45,
            purchaseDate: Date(),
            assignedDriverId: nil,
            adminId: nil,
            status: .active,
            vehicleType: .twoWheeler
        )
        
        let mockTrip = Trip(
            id: UUID(),
            vehicleId: mockVehicleId,
            driverId: nil,
            routeId: nil,
            startTime: Date().addingTimeInterval(-86400 * 2),
            endTime: Date(),
            distance: 3100.0,
            status: .completed,
            orderType: .pickUpAndDrop,
            createdAt: Date()
        )
        
        if !vehicles.contains(where: { $0.vin == "MOCK1234" }) {
            vehicles.append(mockVehicle)
            trips.append(mockTrip)
            // Also keep shared list consistent with mock
            if !VehiclesViewModel.shared.vehicles.contains(where: { $0.vin == "MOCK1234" }) {
                VehiclesViewModel.shared.vehicles.append(mockVehicle)
            }
        }
        // -------------------------------------------

        // Run predictive analysis on updated data
        predictiveAlerts = PredictiveMaintenanceService.analyze(
            vehicles: vehicles,
            trips: trips,
            inspections: inspections,
            issueReports: issueReports,
            maintenanceHistory: maintenanceHistory
        )

        await refreshVehicleLocations()
        checkAndTriggerNotifications()
    }

    /// Call this to pick up vehicles added via VehiclesViewModel.shared without a full reload.
    func syncVehiclesFromShared() {
        vehicles = VehiclesViewModel.shared.vehicles
        predictiveAlerts = PredictiveMaintenanceService.analyze(
            vehicles: vehicles,
            trips: trips,
            inspections: inspections,
            issueReports: issueReports,
            maintenanceHistory: maintenanceHistory
        )
    }
    
    private func checkAndTriggerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                Task { @MainActor in
                    for alert in self.predictiveAlerts {
                        let vehicle = alert.vehicle
                        let content = UNMutableNotificationContent()
                        content.title = alert.severity == .critical
                            ? "Critical Maintenance Alert 🚨"
                            : "Maintenance Warning ⚠️"
                        content.body = "\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? "")): \(alert.reason)"
                        content.sound = .default

                        let request = UNNotificationRequest(
                            identifier: vehicle.id.uuidString,
                            content: content,
                            trigger: nil
                        )
                        try? await UNUserNotificationCenter.current().add(request)
                    }
                }
            }
        }
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addWorkOrdersChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addVehiclesChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addMaintenanceTasksChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addProfilesChangeHandler { [weak self] in Task { await self?.loadData() } }
        // Refresh vehicle pins whenever a driver pushes a new location row
        rt.addVehicleLocationsChangeHandler { [weak self] in
            Task { await self?.refreshVehicleLocations() }
        }
    }

    private func refreshVehicleLocations() async {
        let activeVehicleIds = trips
            .filter { $0.status == .active }
            .map { $0.vehicleId }
        vehicleLocations = (try? await VehicleLocationService.fetchLatestLocations(for: activeVehicleIds)) ?? []
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

    // Calculate total KM traveled for a vehicle (still used by fleet overview stats)
    func totalDistance(for vehicleId: UUID) -> Double {
        let vehicleTrips = trips.filter { $0.vehicleId == vehicleId && $0.status == .completed }
        return vehicleTrips.reduce(0) { $0 + ($1.distance ?? 0) }
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
    case allMaintenanceAlerts
}