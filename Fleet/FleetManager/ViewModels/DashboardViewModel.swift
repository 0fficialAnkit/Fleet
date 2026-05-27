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
        }
        // -------------------------------------------
        
        await refreshVehicleLocations()
        checkAndTriggerNotifications()
    }
    
    private func checkAndTriggerNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Task { @MainActor in
                    for vehicle in self.maintenanceVehicles {
                        let totalKMTraveled = self.totalDistance(for: vehicle.id)
                        let threshold = vehicle.vehicleType?.maintenanceThresholdKM ?? 10000
                        if totalKMTraveled >= threshold {
                            let content = UNMutableNotificationContent()
                            content.title = "Maintenance Due 🚨"
                            content.body = "\(vehicle.make ?? "") \(vehicle.model ?? "") (\(vehicle.licensePlate ?? "")) has crossed its \(Int(threshold)) km threshold!"
                            content.sound = .default
                            
                            let request = UNNotificationRequest(identifier: vehicle.id.uuidString, content: content, trigger: nil) // Fire immediately
                            try? await UNUserNotificationCenter.current().add(request)
                        }
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

    var maintenanceVehicles: [Vehicle] {
        // A vehicle needs maintenance if its status is manually set to maintenance, OR
        // if its total KM traveled exceeds the maintenance threshold for its type.
        
        vehicles.filter { vehicle in
            if vehicle.status == .maintenance { return true }
            
            let totalKMTraveled = totalDistance(for: vehicle.id)
            let threshold = vehicle.vehicleType?.maintenanceThresholdKM ?? 10000 // Default to 10000 if type is nil
            
            // Allow a small buffer (e.g. 500 km) to flag it just before it hits the exact limit,
            // or we just check if it crossed the interval.
            // Example: 22,000 km % 20,000 km threshold = 2,000 km.
            // If they haven't serviced it, we should track when it was last serviced.
            // Since we don't have full maintenance history loaded here yet, we will
            // flag it if (totalKM % threshold) > (threshold - 500) OR totalKM >= threshold
            
            if totalKMTraveled >= threshold {
                return true
            }
            return false
        }
    }
    
    // Calculate total KM traveled for a vehicle
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
}