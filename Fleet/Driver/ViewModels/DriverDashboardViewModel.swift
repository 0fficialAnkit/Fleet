import SwiftUI
import CoreLocation
import MapKit
import UserNotifications

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

    // MARK: - Geofence distance state (backup for CLCircularRegion)
    private struct GFDistState {
        var pickupCoord:    CLLocationCoordinate2D
        var dropoffCoord:   CLLocationCoordinate2D
        var pickupFenceId:  UUID
        var dropoffFenceId: UUID
        var vehicleId:      UUID
        var tripId:         UUID
        var firedPickup    = false   // true once pickup zone-enter is logged
        var firedDropoff   = false   // true once dropoff zone-enter is logged
        // Dropoff monitoring only starts AFTER driver taps "Pickup Done"
        var pickupPhaseDone = false
    }
    private var gfDistState: GFDistState?

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
                guard let self else { return }
                Task { @MainActor in
                    self.currentTime = Date()
                }
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
        // Sync pickupPhaseDone when pickup_done is saved by DriverTripsViewModel
        rt.addGeofenceEventsChangeHandler { [weak self] in Task { await self?.syncPickupPhaseDone() } }
    }

    private func syncPickupPhaseDone() async {
        guard let state = gfDistState, !state.pickupPhaseDone,
              let trip  = activeTrip else { return }
        let events = (try? await GeofenceService.fetchEvents(forVehicle: trip.vehicleId, limit: 20)) ?? []
        let ids    = Set([state.pickupFenceId, state.dropoffFenceId])
        if events.contains(where: { ids.contains($0.geofenceId) && $0.eventType == "pickup_done" }) {
            gfDistState?.pickupPhaseDone = true
            print("[Geofence] 🔄 pickupPhaseDone synced from Realtime")
        }
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
                Task { await gf_setupZones(tripId: id, vehicleId: vehicleId) }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func endTrip(id: UUID, vehicleId: UUID, distance: Double?, notes: String, imageUrls: [String]) {
        print("[DriverDashboardViewModel] endTrip called with distance: \(String(describing: distance))")
        Task {
            do {
                // Log trip_ended before ending trip (using the dropoff geofence ID)
                let fences = (try? await GeofenceService.fetchGeofences(forTrip: id)) ?? []
                if let df = fences.first(where: { $0.zoneType == "dropoff" }) {
                    try? await GeofenceService.createEvent(TripGeofenceEvent(
                        id: UUID(), geofenceId: df.id, vehicleId: vehicleId,
                        driverId: currentUserId, eventType: "trip_ended", occurredAt: Date()))
                    let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
                    for mgr in managers {
                        try? await NotificationService.createNotification(Fleet.Notification(
                            id: UUID(), userId: mgr.id,
                            title: "🏁 Trip Ended",
                            message: "Driver has completed the trip. Trip is now ending.",
                            type: .info, isRead: false, createdAt: Date()))
                    }
                }

                try await TripService.endTrip(id: id, distance: distance)
                stopLocationTracking()
                TripGeofenceMonitor.shared.stopAll()
                gfDistState = nil
                try? await GeofenceService.deactivateGeofences(forTrip: id)
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
        Task { await TripGeofenceMonitor.shared.resumeIfNeeded(
            tripId: activeTrip.id, vehicleId: activeTrip.vehicleId, driverId: currentUserId) }
        // Set up geofence zones whenever an active trip is detected —
        // covers trips started from DriverTripsView (which bypasses startTrip in this VM)
        // and app-relaunch-mid-trip scenarios.
        if gfDistState == nil {
            Task { await gf_setupZones(tripId: activeTrip.id, vehicleId: activeTrip.vehicleId) }
        }
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
                    // Distance-based fallback: fires zone events even when CLCircularRegion can't
                    await self?.gf_checkDistance(coord: coord)
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

    // MARK: - Geofencing (additive — does not touch any existing logic)

    /// Geocodes pickup & dropoff, saves 5 km zones to Supabase, registers CLCircularRegions.
    private func gf_setupZones(tripId: UUID, vehicleId: UUID) async {
        // Only set up geofences for ACTIVE trips — never for scheduled or completed.
        // This prevents events from appearing before the driver has started the trip.
        guard let trip    = trips.first(where: { $0.id == tripId }),
              trip.status == .active,                 // ← hard gate
              let routeId = trip.routeId,
              let route   = routes[routeId],
              let pickup  = route.startLocation, !pickup.isEmpty,
              let dropoff = route.endLocation,   !dropoff.isEmpty else { return }

        guard let pickupCoord = await gf_geocode(pickup) else { return }
        guard let dropCoord   = await gf_geocode(dropoff, near: pickupCoord) else { return }

        let pId = UUID(), dId = UUID()
        try? await GeofenceService.createGeofence(TripGeofence(
            id: pId, tripId: tripId, vehicleId: vehicleId, driverId: currentUserId,
            name: pickup, latitude: pickupCoord.latitude, longitude: pickupCoord.longitude,
            radiusMeters: kGeofenceRadiusMeters, zoneType: "pickup",
            isActive: true, createdAt: Date()))
        try? await GeofenceService.createGeofence(TripGeofence(
            id: dId, tripId: tripId, vehicleId: vehicleId, driverId: currentUserId,
            name: dropoff, latitude: dropCoord.latitude, longitude: dropCoord.longitude,
            radiusMeters: kGeofenceRadiusMeters, zoneType: "dropoff",
            isActive: true, createdAt: Date()))

        let pFence = TripGeofence(id: pId, tripId: tripId, vehicleId: vehicleId,
            driverId: currentUserId, name: pickup,
            latitude: pickupCoord.latitude, longitude: pickupCoord.longitude,
            radiusMeters: kGeofenceRadiusMeters, zoneType: "pickup", isActive: true, createdAt: Date())
        // Only register pickup zone initially — dropoff is activated when driver taps "Pickup Done"
        TripGeofenceMonitor.shared.register(tripId: tripId, vehicleId: vehicleId,
                                             driverId: currentUserId, fences: [pFence])

        // Register route-boundary circle (breach detection)
        // Radius = 2 km + half the straight-line distance between pickup and dropoff
        TripGeofenceMonitor.shared.registerRouteBoundary(
            tripId:       tripId,
            vehicleId:    vehicleId,
            driverId:     currentUserId,
            pickupCoord:  pickupCoord,
            dropoffCoord: dropCoord
        )

        // Also set up distance state for the fallback check in the GPS loop
        gfDistState = GFDistState(
            pickupCoord:    pickupCoord,
            dropoffCoord:   dropCoord,
            pickupFenceId:  pId,
            dropoffFenceId: dId,
            vehicleId:      vehicleId,
            tripId:         tripId)
        print("[Geofence] ✅ Distance fallback ready — pickup: \(pickup)  dropoff: \(dropoff)")
    }

    /// Checks distance every 15 s as a backup when CLCircularRegion doesn't fire.
    /// Deduplicates by checking the in-memory `firedPickup`/`firedDropoff` flags.
    private func gf_checkDistance(coord: CLLocationCoordinate2D) async {
        guard var state = gfDistState else { return }
        let driver  = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let pickup  = CLLocation(latitude: state.pickupCoord.latitude,  longitude: state.pickupCoord.longitude)
        let dropoff = CLLocation(latitude: state.dropoffCoord.latitude, longitude: state.dropoffCoord.longitude)
        var dirty   = false

        // Phase 1: monitor pickup zone only
        if !state.firedPickup, driver.distance(from: pickup) <= kGeofenceRadiusMeters {
            state.firedPickup = true; dirty = true
            await gf_fireZoneEvent(fenceId: state.pickupFenceId, vehicleId: state.vehicleId,
                                   tripId: state.tripId, zoneType: "pickup")
        }

        // Phase 2: monitor dropoff zone ONLY after driver has completed pickup
        if state.pickupPhaseDone,
           !state.firedDropoff,
           driver.distance(from: dropoff) <= kGeofenceRadiusMeters {
            state.firedDropoff = true; dirty = true
            await gf_fireZoneEvent(fenceId: state.dropoffFenceId, vehicleId: state.vehicleId,
                                   tripId: state.tripId, zoneType: "dropoff")
        }
        if dirty { gfDistState = state }
    }

    private func gf_fireZoneEvent(fenceId: UUID, vehicleId: UUID,
                                   tripId: UUID, zoneType: String) async {
        // Strict ordering: dropoff entry only fires AFTER pickup_done is confirmed in DB.
        if zoneType == "dropoff", let state = gfDistState {
            let recent   = (try? await GeofenceService.fetchEvents(forVehicle: vehicleId, limit: 30)) ?? []
            let pickupDone = recent.contains { $0.geofenceId == state.pickupFenceId && $0.eventType == "pickup_done" }
            guard pickupDone else {
                print("[Geofence] ⏭ Dropoff entry blocked — pickup_done not yet confirmed")
                return
            }
        }

        let isPickup = zoneType == "pickup"
        let emoji    = isPickup ? "📍" : "🏁"
        let label    = isPickup ? "Pickup" : "Drop-off"
        let title    = "\(emoji) Driver Entered \(label) Zone"
        let body     = "Driver is within \(Int(kGeofenceRadiusMeters/1000)) km of the \(label.lowercased()) location."
        // Notify TripDetailView instantly — include fenceId so toggle uses it directly
        NotificationCenter.default.post(
            name: .gfZoneEntered,
            object: nil,
            userInfo: ["zoneType": zoneType, "geofenceId": fenceId.uuidString])
        // Save event
        try? await GeofenceService.createEvent(TripGeofenceEvent(
            id: UUID(), geofenceId: fenceId, vehicleId: vehicleId,
            driverId: currentUserId, eventType: "enter", occurredAt: Date()))
        // Notify fleet managers
        let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
        for mgr in managers {
            try? await NotificationService.createNotification(Fleet.Notification(
                id: UUID(), userId: mgr.id,
                title: title, message: body,
                type: .info, isRead: false, createdAt: Date()))
        }
        print("[Geofence] \(emoji) Fired zone-enter (distance fallback) — \(label)")
    }

    /// Called when driver taps "Pickup Done".
    /// Flips to Phase 2: activates dropoff zone monitoring.
    func gf_pickupDone(tripId: UUID, vehicleId: UUID) {
        gfDistState?.pickupPhaseDone = true
        // Capture the valid pickup fence ID BEFORE the async Task starts.
        // Using gfDistState avoids an extra DB round-trip and guarantees a
        // valid FK (the fence was already inserted by gf_setupZones).
        let capturedPickupFenceId = gfDistState?.pickupFenceId

        Task {
            // Resolve a valid pickup fence ID (required by trip_geofence_events FK)
            let resolvedPickupId: UUID?
            if let id = capturedPickupFenceId {
                resolvedPickupId = id   // fast path: already known
            } else {
                // Fallback: look for the pickup fence or last enter event in DB
                let fences = (try? await GeofenceService.fetchGeofences(forTrip: tripId)) ?? []
                if let pf = fences.first(where: { $0.zoneType == "pickup" }) {
                    resolvedPickupId = pf.id
                } else {
                    let recent = (try? await GeofenceService.fetchEvents(forVehicle: vehicleId, limit: 10)) ?? []
                    resolvedPickupId = recent.first(where: { $0.eventType == "enter" })?.geofenceId
                }
            }

            // Save pickup_done event only if we have a valid (non-random) FK
            if let pId = resolvedPickupId {
                try? await GeofenceService.createEvent(TripGeofenceEvent(
                    id: UUID(), geofenceId: pId, vehicleId: vehicleId,
                    driverId: currentUserId, eventType: "pickup_done", occurredAt: Date()))
                print("[Geofence] ✅ pickup_done event saved")
            } else {
                print("[Geofence] ⚠️ No valid pickup fence ID — pickup_done event skipped")
            }

            // Transition CLCircularRegion from pickup → dropoff
            let fences = (try? await GeofenceService.fetchGeofences(forTrip: tripId)) ?? []
            if let df = fences.first(where: { $0.zoneType == "dropoff" }) {
                TripGeofenceMonitor.shared.transitionToDropoff(fence: df,
                    tripId: tripId, vehicleId: vehicleId, driverId: currentUserId)
            }

            // Notify fleet managers
            let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
            for mgr in managers {
                try? await NotificationService.createNotification(Fleet.Notification(
                    id: UUID(), userId: mgr.id,
                    title: "✅ Pickup Completed",
                    message: "Driver completed pickup and is now heading to drop-off.",
                    type: .info, isRead: false, createdAt: Date()))
            }
        }
    }

    /// Called when driver flips the Drop-off toggle ON.
    func gf_dropoffDone(tripId: UUID, vehicleId: UUID, geofenceId: UUID?) {
        Task {
            var dropoffFenceId: UUID? = nil
            let allFences = (try? await GeofenceService.fetchAllGeofences(forTrip: tripId)) ?? []
            if let df = allFences.first(where: { $0.zoneType == "dropoff" }) {
                dropoffFenceId = df.id
            } else if let passed = geofenceId {
                dropoffFenceId = passed
            }

            guard let gfId = dropoffFenceId else {
                print("[Geofence] ❌ gf_dropoffDone: dropoff fence not found in trip_geofences — event not saved")
                return
            }

            do {
                try await GeofenceService.createEvent(TripGeofenceEvent(
                    id: UUID(), geofenceId: gfId, vehicleId: vehicleId,
                    driverId: currentUserId, eventType: "dropoff_done", occurredAt: Date()))
                print("[Geofence] ✅ dropoff_done saved (fence: \(gfId.uuidString.prefix(6)))")
            } catch {
                print("[Geofence] ❌ dropoff_done save failed: \(error)")
            }

            let managers = (try? await ProfileService.fetchProfilesByRole(role: "fleet_manager")) ?? []
            for mgr in managers {
                try? await NotificationService.createNotification(Fleet.Notification(
                    id: UUID(), userId: mgr.id,
                    title: "🏁 Drop-off Completed",
                    message: "Driver has completed the drop-off.",
                    type: .info, isRead: false, createdAt: Date()))
            }
        }
    }


    private func gf_geocode(_ address: String,
                             near bias: CLLocationCoordinate2D? = nil) async -> CLLocationCoordinate2D? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address; req.resultTypes = .address
        if let b = bias {
            req.region = MKCoordinateRegion(center: b,
                                            latitudinalMeters: 300_000, longitudinalMeters: 300_000)
        }
        return try? await MKLocalSearch(request: req).start().mapItems.first?.location.coordinate
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
