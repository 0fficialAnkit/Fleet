import CoreLocation
import Observation

/// Wraps CLLocationManager as an @Observable class so SwiftUI views
/// can reactively read the driver's current coordinate.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    /// The driver's most recent coordinate, or nil before first fix.
    var coordinate: CLLocationCoordinate2D?

    /// Speed in m/s from the last location fix, or nil if unavailable.
    var speed: Double?

    /// Current authorization status.
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10          // update every 10 m
        authorizationStatus = manager.authorizationStatus
        // If permission was already granted on a previous launch, start immediately.
        // locationManagerDidChangeAuthorization only fires on *changes*, not on init.
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    /// Request permission. If already granted, starts updates immediately.
    func requestPermission() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()   // already granted — just start
        default:
            manager.requestWhenInUseAuthorization()
        }
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        coordinate = loc.coordinate
        // speed is negative when invalid (e.g. no fix) — store nil in that case
        speed = loc.speed >= 0 ? loc.speed : nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        // Silently ignore — map still works without live location
        print("[LocationManager] error: \(error.localizedDescription)")
    }
}