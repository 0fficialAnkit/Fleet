import CoreLocation
import Observation

/// Wraps CLLocationManager as an @Observable class so SwiftUI views
/// can reactively read the driver's current coordinate.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    /// The driver's most recent coordinate, or nil before first fix.
    var coordinate: CLLocationCoordinate2D?

    /// Current authorization status.
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 10          // update every 10 m
        authorizationStatus = manager.authorizationStatus
    }

    /// Call once when the map appears to prompt for permission.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
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
        coordinate = locations.last?.coordinate
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
