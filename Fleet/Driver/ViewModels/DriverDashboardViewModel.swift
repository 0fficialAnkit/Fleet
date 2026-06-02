import SwiftUI
import CoreLocation
import MapKit

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
                locationManager.resetDistance()
                await loadData()   // resumeTrackingIfNeeded() inside loadData starts tracking
                // Set up geofences for pickup + dropoff
                await setupGeofences(tripId: id, vehicleId: vehicleId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func endTrip(id: UUID, vehicleId: UUID, notes: String, imageUrls: [String]) {
        Task {
            do {
                try await TripService.endTrip(id: id)
                stopLocationTracking()
                GeofenceMonitor.shared.stopAll()
                try? await GeofenceService.deactivateGeofences(forTrip: id)

                // Save trip distance = road distance from pickup → dropoff
                // (GPS accumulation gives 0 on simulator; route distance is always reliable)
                await saveTripDistance(tripId: id)

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

    /// Calculates road distance (pickup → dropoff) and persists it to the trip record.
    /// Uses region-biased geocoding so both ends resolve in the same city,
    /// preventing MKLocalSearch from matching a same-named place in another city.
    private func saveTripDistance(tripId: UUID) async {
        guard let trip  = trips.first(where: { $0.id == tripId }),
              let rId   = trip.routeId,
              let route = routes[rId],
              let start = route.startLocation, !start.isEmpty,
              let end   = route.endLocation,   !end.isEmpty else {
            print("[endTrip] No route info — distance not saved")
            return
        }

        // Step 1: geocode pickup without bias (let it find the real location)
        let srcReq = MKLocalSearch.Request()
        srcReq.naturalLanguageQuery = start
        srcReq.resultTypes = .address
        guard let src = try? await MKLocalSearch(request: srcReq).start().mapItems.first else {
            print("[endTrip] Pickup geocoding failed — distance not saved")
            return
        }

        // Step 2: geocode dropoff BIASED to pickup's coordinate
        // This prevents "Mysore Palace" matching a "Palace Road" 120 km away
        let pickupCoord = src.placemark.coordinate
        let dstReq = MKLocalSearch.Request()
        dstReq.naturalLanguageQuery = end
        dstReq.resultTypes = .address
        dstReq.region = MKCoordinateRegion(
            center: pickupCoord,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)  // ~200 km radius
        )
        guard let dst = try? await MKLocalSearch(request: dstReq).start().mapItems.first else {
            print("[endTrip] Dropoff geocoding failed — distance not saved")
            return
        }

        // Step 3: road distance via MKDirections
        let dirReq = MKDirections.Request()
        dirReq.source = src; dirReq.destination = dst
        dirReq.transportType = .automobile
        guard let resp    = try? await MKDirections(request: dirReq).calculate(),
              let mkRoute = resp.routes.first else {
            print("[endTrip] MKDirections failed — distance not saved")
            return
        }

        let distanceKm = mkRoute.distance / 1000.0
        print("[endTrip] ✅ Route distance: \(String(format: "%.2f", distanceKm)) km — saving")
        try? await TripService.updateTripDistance(id: tripId, distanceKm: distanceKm)
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
        // Resume geofence monitoring for the active trip
        Task {
            await GeofenceMonitor.shared.resumeIfNeeded(
                tripId:    activeTrip.id,
                vehicleId: activeTrip.vehicleId,
                driverId:  currentUserId
            )
        }
    }

    // MARK: - Geofencing

    private func setupGeofences(tripId: UUID, vehicleId: UUID) async {
        // Find the route for this trip
        guard let trip  = trips.first(where: { $0.id == tripId }),
              let rId   = trip.routeId,
              let route = routes[rId],
              let pickup  = route.startLocation, !pickup.isEmpty,
              let dropoff = route.endLocation,   !dropoff.isEmpty
        else { return }

        let monitor = GeofenceMonitor.shared
        async let pickupCoord  = monitor.geocode(pickup)
        async let dropoffCoord = monitor.geocode(dropoff)

        guard let pc = await pickupCoord, let dc = await dropoffCoord else {
            print("[Geofence] ❌ Could not geocode pickup/dropoff for trip \(tripId)")
            return
        }

        let fences: [TripGeofence] = [
            TripGeofence(id: UUID(), tripId: tripId, vehicleId: vehicleId,
                         driverId: currentUserId,
                         name: pickup, latitude: pc.latitude, longitude: pc.longitude,
                         radiusMeters: 5000, zoneType: "pickup", isActive: true, createdAt: Date()),
            TripGeofence(id: UUID(), tripId: tripId, vehicleId: vehicleId,
                         driverId: currentUserId,
                         name: dropoff, latitude: dc.latitude, longitude: dc.longitude,
                         radiusMeters: 5000, zoneType: "dropoff", isActive: true, createdAt: Date())
        ]

        // Save to Supabase (best-effort — never blocks the trip)
        for fence in fences { try? await GeofenceService.createGeofence(fence) }

        // Register with iOS native region monitoring
        monitor.register(tripId: tripId, vehicleId: vehicleId, driverId: currentUserId, fences: fences)
        print("[Geofence] ✅ Pickup + dropoff zones active for trip \(tripId.uuidString.prefix(6).uppercased())")
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
