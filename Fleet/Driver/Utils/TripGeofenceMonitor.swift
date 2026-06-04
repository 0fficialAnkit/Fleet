import CoreLocation
import UserNotifications

// ─────────────────────────────────────────────────────────────────────────────
// Change this constant to adjust the geofence radius across the whole app.
// ─────────────────────────────────────────────────────────────────────────────
let kGeofenceRadiusMeters: CLLocationDistance = 5000   // 5 km

/// iOS-native geofencing via CLCircularRegion.
/// - @MainActor: all state lives on the main thread.
/// - lazy var manager: CLLocationManager is created on first use (which is
///   always from an @MainActor call), avoiding the background-thread crash.
@MainActor
final class TripGeofenceMonitor: NSObject {

    static let shared = TripGeofenceMonitor()

    // Lazy — CLLocationManager is NEVER created inside init(), so the singleton
    // can safely be initialised from any thread without causing CLLocationManager
    // threading violations.
    private lazy var manager: CLLocationManager = {
        let m = CLLocationManager()
        m.delegate = self
        m.desiredAccuracy = kCLLocationAccuracyHundredMeters
        return m
    }()

    private var fenceMap:         [String: TripGeofence] = [:]   // regionIdentifier → fence
    private var registrationTime: [String: Date]         = [:]   // regionIdentifier → when registered
    private var tripId:    UUID?
    private var vehicleId: UUID?
    private var driverId:  UUID?

    // Route boundary (breach detection)
    private struct RouteBoundaryMeta {
        let tripId: UUID; let vehicleId: UUID; let driverId: UUID?
        let center: CLLocationCoordinate2D; let radius: Double
    }
    private var routeBoundaryMeta: [String: RouteBoundaryMeta] = [:]
    private static let routeBoundaryPrefix = "route_boundary_"

    /// iOS fires a catch-up `didEnterRegion` within ~1-2 s of `startMonitoring`
    /// if the device is already inside the region. We ignore any entry event that
    /// fires within this window to prevent false "zone entered" notifications.
    private let catchUpWindow: TimeInterval = 15

    private override init() { super.init() }

    // MARK: - Public API

    /// Call after `setupGeofences()` writes fences to Supabase.
    func register(tripId: UUID, vehicleId: UUID, driverId: UUID?,
                  fences: [TripGeofence]) {
        // Request "Always" permission for background monitoring.
        // Info.plist already declares NSLocationAlwaysAndWhenInUseUsageDescription.
        // Request Always auth so iOS can wake the app on region boundary crossings.
        // allowsBackgroundLocationUpdates is NOT set — region monitoring uses a
        // separate OS mechanism and does not require that flag (which crashes if the
        // Background Modes > Location Updates capability is not enabled).
        if manager.authorizationStatus == .notDetermined ||
           manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }

        stopAll()
        self.tripId    = tripId
        self.vehicleId = vehicleId
        self.driverId  = driverId

        for fence in fences {
            let region = CLCircularRegion(
                center: .init(latitude: fence.latitude, longitude: fence.longitude),
                radius: fence.radiusMeters,
                identifier: fence.id.uuidString)
            region.notifyOnEntry = true
            region.notifyOnExit  = false   // only entry needed per spec
            manager.startMonitoring(for: region)
            fenceMap[fence.id.uuidString]         = fence
            registrationTime[fence.id.uuidString] = Date()
        }
        print("[GeofenceMonitor] ✅ \(fences.count) zones registered (\(Int(kGeofenceRadiusMeters/1000)) km)")
    }

    /// Called when driver taps "Pickup Done".
    /// 1. Removes pickup CLCircularRegion (prevents iOS catch-up duplicate events).
    /// 2. Registers the dropoff CLCircularRegion.
    func transitionToDropoff(fence: TripGeofence, tripId: UUID, vehicleId: UUID, driverId: UUID?) {
        // Stop pickup region FIRST — iOS fires catch-up didEnterRegion for regions
        // you're currently inside when new monitoring starts, which would create a
        // duplicate "Entered Pickup Zone" event.
        for region in manager.monitoredRegions {
            if let f = fenceMap[region.identifier], f.zoneType == "pickup" {
                manager.stopMonitoring(for: region)
                fenceMap.removeValue(forKey: region.identifier)
            }
        }

        // Now register dropoff — no catch-up from pickup since it's removed
        let region = CLCircularRegion(
            center: .init(latitude: fence.latitude, longitude: fence.longitude),
            radius: fence.radiusMeters,
            identifier: fence.id.uuidString)
        region.notifyOnEntry = true
        region.notifyOnExit  = false
        manager.startMonitoring(for: region)
        fenceMap[fence.id.uuidString] = fence
        // NOTE: registrationTime is intentionally NOT set for dropoff.
        // We want the iOS catch-up to fire immediately if the driver is already
        // inside the dropoff zone — this is the correct behaviour after pickup.
        print("[GeofenceMonitor] 🏁 Transitioned to dropoff zone (\(Int(fence.radiusMeters/1000)) km)")
    }

    /// Registers a route-boundary circle around the midpoint of pickup ↔ drop-off.
    /// Radius = 2 000 m + (pickup-to-dropoff distance / 2).
    /// Fires `didExitRegion` when driver goes outside → breach alert.
    func registerRouteBoundary(
        tripId:        UUID,
        vehicleId:     UUID,
        driverId:      UUID?,
        pickupCoord:   CLLocationCoordinate2D,
        dropoffCoord:  CLLocationCoordinate2D
    ) {
        let centerLat = (pickupCoord.latitude  + dropoffCoord.latitude)  / 2
        let centerLon = (pickupCoord.longitude + dropoffCoord.longitude) / 2
        let center    = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

        let pickupLoc  = CLLocation(latitude: pickupCoord.latitude,  longitude: pickupCoord.longitude)
        let dropoffLoc = CLLocation(latitude: dropoffCoord.latitude, longitude: dropoffCoord.longitude)
        let routeDistance = pickupLoc.distance(from: dropoffLoc)   // metres

        // Formula: 2 km + half the route distance
        let radius = 2_000 + routeDistance / 2

        let regionId = "\(TripGeofenceMonitor.routeBoundaryPrefix)\(tripId.uuidString)"
        let region   = CLCircularRegion(center: center, radius: radius, identifier: regionId)
        region.notifyOnEntry = false  // driver starts inside — suppress catch-up enter
        region.notifyOnExit  = true   // breach = crossing outward

        manager.startMonitoring(for: region)
        routeBoundaryMeta[regionId] = RouteBoundaryMeta(
            tripId: tripId, vehicleId: vehicleId, driverId: driverId,
            center: center, radius: radius
        )
        print("[GeofenceMonitor] 🔵 Route boundary: centre (\(String(format:"%.4f",centerLat)),\(String(format:"%.4f",centerLon))) radius \(String(format:"%.1f",radius/1000)) km")
    }

    func stopAll() {
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
        fenceMap.removeAll()
        registrationTime.removeAll()
        routeBoundaryMeta.removeAll()
        tripId = nil; vehicleId = nil; driverId = nil
    }

    /// Restores monitoring after app relaunch mid-trip.
    func resumeIfNeeded(tripId: UUID, vehicleId: UUID, driverId: UUID?) async {
        guard manager.monitoredRegions.isEmpty else { return }
        let fences = (try? await GeofenceService.fetchGeofences(forTrip: tripId)) ?? []
        guard !fences.isEmpty else { return }
        register(tripId: tripId, vehicleId: vehicleId, driverId: driverId, fences: fences)
    }

    // MARK: - Internal

    private func didEnter(regionId: String) {
        // Block iOS catch-up events fired immediately after region registration.
        // iOS fires didEnterRegion within ~1-2 s when the device is already inside
        // the region. We reject any entry within `catchUpWindow` seconds of registration.
        if let regTime = registrationTime[regionId],
           Date().timeIntervalSince(regTime) < catchUpWindow {
            print("[GeofenceMonitor] ⏭ Catch-up event blocked for region registered \(String(format:"%.1f", Date().timeIntervalSince(regTime)))s ago")
            return
        }

        guard let fence = fenceMap[regionId],
              let tId   = tripId,
              let vId   = vehicleId else { return }

        let isPickup = fence.zoneType == "pickup"
        let emoji    = isPickup ? "📍" : "🏁"
        let label    = isPickup ? "Pickup" : "Drop-off"
        let title    = "\(emoji) Driver Entered \(label) Zone"
        let body     = "Driver is within \(Int(kGeofenceRadiusMeters/1000)) km of the \(label.lowercased()): \(fence.name)"
        let dId      = driverId

        Task {
            // Strict ordering: dropoff entry only fires AFTER pickup_done is confirmed in DB.
            if fence.zoneType == "dropoff" {
                let tripFences = (try? await GeofenceService.fetchAllGeofences(forTrip: fence.tripId)) ?? []
                let pickupIds = Set(tripFences.filter { $0.zoneType == "pickup" }.map { $0.id })
                
                let recent    = (try? await GeofenceService.fetchEvents(forVehicle: vId, limit: 30)) ?? []
                let pickupDone = recent.contains { pickupIds.contains($0.geofenceId) && $0.eventType == "pickup_done" }
                guard pickupDone else {
                    print("[GeofenceMonitor] ⏭ Dropoff entry blocked — pickup_done not yet in DB")
                    return
                }
            }
            // 1 – log to Supabase
            try? await GeofenceService.createEvent(TripGeofenceEvent(
                id: UUID(), geofenceId: fence.id, vehicleId: vId,
                driverId: dId, eventType: "enter", occurredAt: Date()))

            // 2 – in-app notification to fleet managers
            try? await NotificationService.notifyManager(
                forVehicle: vId,
                title: title, message: body,
                type: .info
            )

            // 3 – local notification to driver
            let content   = UNMutableNotificationContent()
            content.title = title; content.body = body; content.sound = .default
            try? await UNUserNotificationCenter.current().add(
                UNNotificationRequest(
                    identifier: "gf_enter_\(fence.zoneType)_\(tId)",
                    content: content, trigger: nil))
        }
        // Notify TripDetailView instantly — include fenceId so toggle uses it directly
        NotificationCenter.default.post(
            name: .gfZoneEntered,
            object: nil,
            userInfo: ["zoneType": fence.zoneType, "geofenceId": fence.id.uuidString])
        print("[GeofenceMonitor] \(emoji) Entered \(label) zone — trip \(tId.uuidString.prefix(6))")
    }
}

// MARK: - CLLocationManagerDelegate

extension TripGeofenceMonitor: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didEnterRegion region: CLRegion) {
        Task { @MainActor in self.didEnter(regionId: region.identifier) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didExitRegion region: CLRegion) {
        // Route boundary exit = driver deviated from route
        if region.identifier.hasPrefix(TripGeofenceMonitor.routeBoundaryPrefix) {
            let currentLoc = manager.location
            Task { @MainActor in self.handleRouteBreach(regionId: region.identifier, location: currentLoc) }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // No action needed — region monitoring works without allowsBackgroundLocationUpdates
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     monitoringDidFailFor region: CLRegion?,
                                     withError error: Error) {
        print("[GeofenceMonitor] ⚠️ \(error.localizedDescription)")
    }
}

// MARK: - Route breach handler

extension TripGeofenceMonitor {

    private func handleRouteBreach(regionId: String, location: CLLocation?) {
        guard let meta = routeBoundaryMeta[regionId] else { return }

        let lat = location?.coordinate.latitude  ?? 0
        let lon = location?.coordinate.longitude ?? 0

        // Distance from centre
        let driverLoc  = CLLocation(latitude: lat, longitude: lon)
        let centerLoc  = CLLocation(latitude: meta.center.latitude, longitude: meta.center.longitude)
        let distOutside = max(0, driverLoc.distance(from: centerLoc) - meta.radius)

        print("[GeofenceMonitor] 🚨 Route breach! Driver is \(Int(distOutside))m outside the boundary.")

        // Notify driver immediately on-device
        NotificationCenter.default.post(
            name: .routeBoundaryBreached,
            object: nil,
            userInfo: ["distanceOutside": distOutside]
        )

        Task {
            // 1. Log to Supabase
            let breach = RouteBreach(
                id: UUID(),
                tripId:             meta.tripId,
                vehicleId:          meta.vehicleId,
                driverId:           meta.driverId,
                latitude:           lat,
                longitude:          lon,
                distanceFromCenter: driverLoc.distance(from: centerLoc),
                fenceRadius:        meta.radius,
                occurredAt:         Date()
            )
            try? await RouteBreachService.logBreach(breach)

            // 2. Notify fleet managers
            try? await NotificationService.notifyManager(
                forVehicle: meta.vehicleId,
                title: "🚨 Route Deviation Alert",
                message: "Driver has left the route boundary. Currently \(Int(distOutside / 1000 * 10) / 10) km outside the permitted area.",
                type: .alert
            )

            // 3. Local push to driver
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Route Deviation"
            content.body  = "You have left the assigned route boundary. Please return to the route."
            content.sound = .defaultCritical
            try? await UNUserNotificationCenter.current().add(
                UNNotificationRequest(
                    identifier: "breach_\(meta.tripId)",
                    content: content, trigger: nil))
        }
    }
}
