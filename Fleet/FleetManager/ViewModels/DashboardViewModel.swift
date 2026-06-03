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
    private(set) var recentVoiceLogs: [VoiceTripLog] = []
    private(set) var recentVoiceIncidents: [TripIncident] = []

    /// Predictive alerts derived by the on-device rules engine after each data load.
    private(set) var predictiveAlerts: [PredictiveMaintenanceAlert] = []

    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let v  = try? VehicleService.fetchAllVehicles()
        async let t  = try? TripService.fetchAllTrips()
        async let w  = try? WorkOrderService.fetchAllWorkOrders()
        async let r  = try? RouteService.fetchAllRoutes()
        async let p  = try? ProfileService.fetchAllProfiles()
        async let m  = try? MaintenanceTaskService.fetchAllTasks()
        async let i  = try? InspectionService.fetchAllInspections()
        async let ir = try? IssueReportService.fetchAllIssueReports()
        async let mh = try? MaintenanceHistoryService.fetchAllHistory()
        async let vl = try? VoiceTripLogService.fetchAllRecentLogs(limit: 10)
        async let vi = try? TripIncidentService.fetchRecentVoiceIncidents(limit: 5)
        
        vehicles           = (await v) ?? []
        trips              = (await t) ?? []
        workOrders         = (await w) ?? []
        routes             = (await r) ?? []
        profiles           = (await p) ?? []
        maintenanceTasks   = (await m) ?? []
        inspections        = (await i) ?? []
        issueReports       = (await ir) ?? []
        maintenanceHistory = (await mh) ?? []
        recentVoiceLogs      = (await vl) ?? []
        recentVoiceIncidents = (await vi) ?? []
        
        isLoading = false
        

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
        rt.addVoiceTripLogsChangeHandler { [weak self] in Task { await self?.loadData() } }
        rt.addTripIncidentsChangeHandler { [weak self] in Task { await self?.loadData() } }
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

    /// Vehicles fleet manager has explicitly sent to the service bay (status == .maintenance).
    var inServiceVehicles: Int {
        vehicles.filter { $0.status == .maintenance }.count
    }

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

    func vehicleName(for vehicleId: UUID?) -> String {
        guard let id = vehicleId else { return "Unknown Vehicle" }
        if let v = vehicles.first(where: { $0.id == id }) {
            return "\(v.make ?? "") \(v.model ?? "") (\(v.licensePlate ?? "No Plate"))"
        }
        return "Unknown Vehicle"
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