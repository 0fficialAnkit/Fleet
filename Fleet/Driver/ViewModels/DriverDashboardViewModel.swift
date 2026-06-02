import SwiftUI
import CoreLocation

@MainActor
@Observable
final class DriverDashboardViewModel {
    private(set) var trips: [Trip] = []
    private(set) var routes: [UUID: Route] = [:]
    private(set) var vehicles: [UUID: Vehicle] = [:]
    private(set) var assignedVehicle: Vehicle?

    var isLoading = false
    var errorMessage: String?
    var currentUserId: UUID?
    var driverName: String = "Driver"

    // MARK: - Live location tracking
    private var locationManager = LocationManager()
    private var trackingTask: Task<Void, Never>?

    // MARK: - Computed stats

    /// Currently active trip (should be at most 1)
    var activeTrip: Trip? {
        trips.first(where: { $0.status == .active })
    }

    /// Active + scheduled trips for today
    var todaysTrips: [Trip] {
        let cal = Calendar.current
        return trips
            .filter { trip in
                guard trip.status == .active || trip.status == .scheduled else { return false }
                if let start = trip.startTime {
                    return cal.isDateInToday(start)
                }
                // If no start time, include scheduled trips (they're assigned for today)
                return trip.status == .scheduled
            }
            .sorted { ($0.startTime ?? .distantFuture) < ($1.startTime ?? .distantFuture) }
    }

    var todayScheduledCount: Int {
        trips.filter { trip in
            let cal = Calendar.current
            if let start = trip.startTime {
                return cal.isDateInToday(start) && (trip.status == .scheduled || trip.status == .active)
            }
            return trip.status == .scheduled
        }.count
    }

    var todayCompletedCount: Int {
        trips.filter { trip in
            let cal = Calendar.current
            if let end = trip.endTime {
                return cal.isDateInToday(end) && trip.status == .completed
            }
            return false
        }.count
    }

    var totalCompletedTrips: Int {
        trips.filter { $0.status == .completed }.count
    }

    var currentTime: Date = Date()
    private var liveTimer: Timer?

    var totalDistanceKm: Double {
        let completed = trips
            .filter { $0.status == .completed }
            .compactMap { $0.distance }
            .reduce(0, +)
        let live = (activeTrip != nil) ? (locationManager.totalDistanceTraveled / 1000.0) : 0.0
        return completed + live
    }

    var totalHoursActive: Double {
        let completed = trips
            .filter { $0.status == .completed }
            .compactMap { trip -> Double? in
                guard let start = trip.startTime, let end = trip.endTime else { return nil }
                return end.timeIntervalSince(start) / 3600.0
            }
            .reduce(0.0, +)
            
        let live: Double
        if let active = activeTrip, let start = active.startTime {
            live = currentTime.timeIntervalSince(start) / 3600.0
        } else {
            live = 0.0
        }
        return completed + live
    }
    
    private func setupLiveTimer() {
        liveTimer?.invalidate()
        if activeTrip != nil {
            liveTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.currentTime = Date()
            }
        }
    }

    var upcomingTrip: Trip? {
        trips
            .filter { $0.status == .scheduled }
            .sorted { ($0.startTime ?? Date.distantFuture) < ($1.startTime ?? Date.distantFuture) }
            .first
    }

    // MARK: - Data loading

    func loadData() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        errorMessage = nil
        do {
            trips = try await TripService.fetchTripsForDriver(driverId: userId)
            assignedVehicle = try? await VehicleService.fetchVehicleForDriver(driverId: userId)
            await loadEnrichmentData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        // Resume GPS tracking if a trip was already active when the app launched
        resumeTrackingIfNeeded()
        setupLiveTimer()
    }

    /// Batch-fetch routes and vehicles referenced by trips
    private func loadEnrichmentData() async {
        let routeIds = Set(trips.compactMap { $0.routeId })
        let vehicleIds = Set(trips.map { $0.vehicleId })

        // Fetch routes in parallel
        await withTaskGroup(of: (UUID, Route?).self) { group in
            for routeId in routeIds where routes[routeId] == nil {
                group.addTask {
                    let route = try? await RouteService.fetchRoute(id: routeId)
                    return (routeId, route)
                }
            }
            for await (id, route) in group {
                if let route { routes[id] = route }
            }
        }

        // Fetch vehicles in parallel
        await withTaskGroup(of: (UUID, Vehicle?).self) { group in
            for vehicleId in vehicleIds where vehicles[vehicleId] == nil {
                group.addTask {
                    let vehicle = try? await VehicleService.fetchVehicle(id: vehicleId)
                    return (vehicleId, vehicle)
                }
            }
            for await (id, vehicle) in group {
                if let vehicle { vehicles[id] = vehicle }
            }
        }
    }

    func setupRealtime() {
        let rt = RealtimeManager.shared
        rt.addTripsChangeHandler { [weak self] in Task { await self?.loadData() } }
    }

    func startTrip(id: UUID, vehicleId: UUID, notes: String, imageUrls: [String]) {
        Task {
            do {
                try await TripService.startTrip(id: id)
                let inspectionId = UUID()
                let inspection = VehicleInspection(id: inspectionId, vehicleId: vehicleId, driverId: currentUserId, tripId: id, inspectionType: .preTrip, notes: notes, createdAt: Date())
                try? await InspectionService.createInspection(inspection)
                for url in imageUrls {
                    let photo = InspectionPhoto(id: UUID(), inspectionId: inspectionId, imageUrl: url)
                    try? await InspectionService.createInspectionPhoto(photo)
                }
                await loadData()
                locationManager.resetDistance()
                startLocationTracking(vehicleId: vehicleId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func endTrip(id: UUID, vehicleId: UUID, distance: Double?, notes: String, imageUrls: [String]) {
        print("[DriverDashboardViewModel] endTrip called with distance: \(String(describing: distance))")
        Task {
            do {
                try await TripService.endTrip(id: id, distance: distance)
                stopLocationTracking()
                let inspectionId = UUID()
                let inspection = VehicleInspection(id: inspectionId, vehicleId: vehicleId, driverId: currentUserId, tripId: id, inspectionType: .postTrip, notes: notes, createdAt: Date())
                try? await InspectionService.createInspection(inspection)
                for url in imageUrls {
                    let photo = InspectionPhoto(id: UUID(), inspectionId: inspectionId, imageUrl: url)
                    try? await InspectionService.createInspectionPhoto(photo)
                }
                await loadData()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Location tracking

    /// Request location permission as soon as the driver app loads.
    /// Called from the view's .task — shows the system prompt early, not buried in trip start.
    func requestLocationPermission() {
        locationManager.requestPermission()
    }

    /// Call after loadData if an active trip is already in progress (e.g. app relaunch mid-trip).
    func resumeTrackingIfNeeded() {
        guard let activeTrip else { return }
        startLocationTracking(vehicleId: activeTrip.vehicleId)
    }

    private func startLocationTracking(vehicleId: UUID) {
        stopLocationTracking()
        locationManager.requestPermission()
        print("[LocationTracking] 🚛 Started tracking for vehicle \(vehicleId)")

        trackingTask = Task { [weak self] in
            // Wait up to 20 s for first GPS fix before entering the main loop.
            // The simulator provides a location instantly; a real device may need
            // a few seconds to acquire a satellite fix.
            var waited = 0
            while !Task.isCancelled, waited < 20 {
                if self?.locationManager.coordinate != nil { break }
                print("[LocationTracking] ⏳ Waiting for GPS fix… (\(waited)s)")
                try? await Task.sleep(for: .seconds(1))
                waited += 1
            }

            // Push immediately on trip start, then every 15 seconds.
            // 15 s = good balance: ~125 m between updates at city speed,
            // low battery drain, manageable Supabase write volume.
            while !Task.isCancelled {
                if let coord = self?.locationManager.coordinate {
                    print("[LocationTracking] 📍 Pushing location — lat:\(String(format: "%.5f", coord.latitude)) lon:\(String(format: "%.5f", coord.longitude))")
                    await VehicleLocationService.insertLocation(
                        vehicleId: vehicleId,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        speed: self?.locationManager.speed
                    )
                } else {
                    print("[LocationTracking] ⚠️ No GPS fix yet — retrying in 5 s")
                    try? await Task.sleep(for: .seconds(5))
                    continue
                }
                try? await Task.sleep(for: .seconds(15))
            }
            print("[LocationTracking] 🛑 Tracking stopped for vehicle \(vehicleId)")
        }
    }

    private func stopLocationTracking() {
        trackingTask?.cancel()
        trackingTask = nil
    }

    // MARK: - Helpers

    func routeForTrip(_ trip: Trip) -> Route? {
        guard let routeId = trip.routeId else { return nil }
        return routes[routeId]
    }

    func vehicleForTrip(_ trip: Trip) -> Vehicle? {
        vehicles[trip.vehicleId]
    }

    func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Night"
        }
    }
}

// MARK: - Navigation destinations

enum DriverDestination: Hashable {
    case profile
    case notifications
    case tripDetail(Trip)
    case vehicleDetail(Vehicle)
    case reportIssue(Vehicle)
}
