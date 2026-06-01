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

        let emoji  = eventType == "entered" ? "📍" : "🚗"
        let action = eventType == "entered"  ? "arrived at" : "departed from"
        print("[GeofenceMonitor] \(emoji) \(action) '\(fence.name)'")

        Task {
            // 1. Log event to Supabase
            let event = TripGeofenceEvent(
                id:         UUID(),
                geofenceId: fence.id,
                vehicleId:  vId,
                driverId:   currentDriverId,
                eventType:  eventType,
                latitude:   nil,
                longitude:  nil,
                occurredAt: Date()
            )
            try? await GeofenceService.createEvent(event)

            // 2. Notify fleet managers
            guard let managers = try? await ProfileService.fetchProfilesByRole(role: "fleet_manager"),
                  !managers.isEmpty else { return }

            for manager in managers {
                let notification = Notification(
                    id:        UUID(),
                    userId:    manager.id,
                    title:     "\(emoji) \(fence.zoneType.capitalized) Zone Alert",
                    message:   "Driver \(action) \(fence.name) — Trip #\(tripId.uuidString.prefix(6).uppercased())",
                    type:      .info,
                    isRead:    false,
                    createdAt: Date()
                )
                try? await NotificationService.createNotification(notification)
            }
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
    func geocode(_ address: String) async -> CLLocationCoordinate2D? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address
        req.resultTypes = .address
        guard let item = try? await MKLocalSearch(request: req).start().mapItems.first else { return nil }
        return item.placemark.coordinate
    }
}
