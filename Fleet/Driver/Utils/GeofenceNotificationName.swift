import Foundation

// Using NSNotification.Name to avoid conflict with the app's own Notification model
extension NSNotification.Name {
    /// Posted (in-process) when the driver crosses a geofence boundary.
    /// userInfo["zoneType"] = "pickup" | "dropoff"
    static let gfZoneEntered = NSNotification.Name("com.fleet.gfZoneEntered")
}
