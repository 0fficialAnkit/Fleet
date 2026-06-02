import Foundation
import CoreLocation
import MapKit

// MARK: - Geofence Monitor
// Uses CLLocationManager's native region monitoring — works in the background,
// battery-efficient (cell towers + WiFi, not continuous GPS).
// iOS limit: 20 monitored regions per device.

final class GeofenceMonitor: NSObject {

    static let shared = GeofenceMonitor()

    private let manager = CLLocationManager()

    // Active trip context
    private var currentTripId:   UUID?
    private var currentVehicleId: UUID?
    private var currentDriverId: UUID?
    private var geofenceMap: [String: TripGeofence] = [:]   // regionId → fence

    private override init() {
        super.init()
        manager.delegate        = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // allowsBackgroundLocationUpdates requires the Background Modes → Location
        // capability in the app target. Only set it when authorised.
        if manager.authorizationStatus == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }
    }

    // MARK: - Public API

    /// Register geofences for a newly started trip.
    /// Call AFTER geofences are created in Supabase.
    func register(
        tripId:    UUID,
        vehicleId: UUID,
        driverId:  UUID?,
        fences:    [TripGeofence]
    ) {
        // Ensure notification permission so driver alerts can fire
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }

        // Request Always permission if not already granted
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }

        stopAll()
        currentTripId   = tripId
        currentVehicleId = vehicleId
        currentDriverId = driverId

        for fence in fences.prefix(20) {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude),
                radius: fence.radiusMeters,
                identifier: fence.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit  = true
            manager.startMonitoring(for: region)
            geofenceMap[fence.id.uuidString] = fence
        }

        print("[GeofenceMonitor] ✅ Registered \(min(fences.count, 20)) zones for trip \(tripId.uuidString.prefix(6).uppercased())")
    }

    /// Stop all monitoring and clear context. Call when trip ends.
    func stopAll() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        geofenceMap.removeAll()
        currentTripId    = nil
        currentVehicleId = nil
        currentDriverId  = nil
        print("[GeofenceMonitor] 🛑 All zones cleared")
    }

    /// Resume monitoring for a trip already in progress (e.g. app re-launch mid-trip).
    func resumeIfNeeded(tripId: UUID, vehicleId: UUID, driverId: UUID?) async {
        guard manager.monitoredRegions.isEmpty else { return }
        do {
            let fences = try await GeofenceService.fetchGeofences(forTrip: tripId)
            guard !fences.isEmpty else { return }
            register(tripId: tripId, vehicleId: vehicleId, driverId: driverId, fences: fences)
        } catch {
            print("[GeofenceMonitor] resume error: \(error)")
        }
    }

    // MARK: - Event Handling (background-safe)

    private func handle(regionId: String, eventType: String) {
        guard let fence   = geofenceMap[regionId],
              let tripId  = currentTripId,
              let vId     = currentVehicleId else { return }

        let isEntry   = eventType == "entered"
        let emoji     = isEntry  ? "📍" : "🚗"
        let action    = isEntry  ? "arrived at" : "departed from"
        let isPickup  = fence.zoneType == "pickup"
        print("[GeofenceMonitor] \(emoji) \(action) '\(fence.name)'")

        Task {
            // 1. Log event to Supabase
            let event = TripGeofenceEvent(
                id: UUID(), geofenceId: fence.id, vehicleId: vId,
                driverId: currentDriverId, eventType: eventType,
                latitude: nil, longitude: nil, occurredAt: Date()
            )
            try? await GeofenceService.createEvent(event)

            // 2. Notify fleet managers (in-app)
            if let managers = try? await ProfileService.fetchProfilesByRole(role: "fleet_manager") {
                for manager in managers {
                    let msg = isEntry
                        ? "Driver approaching \(fence.name) — \(isPickup ? "ready to pick up" : "delivering now")"
                        : "Driver left \(fence.name) — \(isPickup ? "heading to drop-off" : "trip nearly complete")"
                    let notification = Notification(
                        id: UUID(), userId: manager.id,
                        title: "\(emoji) \(fence.zoneType.capitalized) Zone — Trip #\(tripId.uuidString.prefix(6).uppercased())",
                        message: msg, type: .info, isRead: false, createdAt: Date()
                    )
                    try? await NotificationService.createNotification(notification)
                }
            }

            // 3. Local notification to the driver's device
            sendDriverLocalNotification(fence: fence, isEntry: isEntry, isPickup: isPickup)
        }
    }

    private func sendDriverLocalNotification(fence: TripGeofence, isEntry: Bool, isPickup: Bool) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.sound = .default

        if isEntry && isPickup {
            content.title = "📍 Approaching Pickup"
            content.body  = "You are within 5 km of your pickup: \(fence.name). Prepare to arrive."
        } else if isEntry && !isPickup {
            content.title = "🏁 Approaching Drop-off"
            content.body  = "You are within 5 km of your destination: \(fence.name)."
        } else if !isEntry && isPickup {
            content.title = "🚗 Departed Pickup"
            content.body  = "You have left the pickup zone. Head to your drop-off location."
        } else {
            content.title = "✅ Departed Drop-off"
            content.body  = "You have left the drop-off zone. Please complete your trip."
        }

        let req = UNNotificationRequest(
            identifier: "geofence_\(fence.id.uuidString)_\(isEntry ? "enter" : "exit")",
            content: content,
            trigger: nil   // deliver immediately
        )
        center.add(req) { error in
            if let error { print("[GeofenceMonitor] local notif error: \(error)") }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceMonitor: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        handle(regionId: region.identifier, eventType: "entered")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        handle(regionId: region.identifier, eventType: "exited")
    }

    func locationManager(_ manager: CLLocationManager,
                         monitoringDidFailFor region: CLRegion?,
                         withError error: Error) {
        print("[GeofenceMonitor] ❌ Monitor failed \(region?.identifier ?? "?"): \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
            print("[GeofenceMonitor] ✅ Always-on location granted — background geofences active")
        case .authorizedWhenInUse:
            print("[GeofenceMonitor] ⚠️ When-in-use only — geofences work only while app is open")
        case .denied, .restricted:
            print("[GeofenceMonitor] ❌ Location denied — geofencing disabled")
        default:
            break
        }
    }
}

// MARK: - Geocoding helper (reusable within this module)

extension GeofenceMonitor {

    /// Resolves a free-text address to a coordinate. Returns nil on failure.
    /// Resolves a free-text address to a coordinate. Returns nil on failure.
    func geocode(_ address: String, biasedTo coordinate: CLLocationCoordinate2D? = nil) async -> CLLocationCoordinate2D? {
        let decoded = LocationParser.decode(address)
        if let coord = decoded.coordinate {
            return coord
        }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = decoded.address
        req.resultTypes = .address
        if let coord = coordinate {
            req.region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
            )
        }
        guard let item = try? await MKLocalSearch(request: req).start().mapItems.first else { return nil }
        return item.location.coordinate
    }
}
