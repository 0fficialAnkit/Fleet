import Foundation

// Using NSNotification.Name to avoid conflict with the app's own Notification model
extension NSNotification.Name {
    /// Posted when the driver crosses a pickup/dropoff zone boundary.
    /// userInfo["zoneType"] = "pickup" | "dropoff"
    static let gfZoneEntered = NSNotification.Name("com.fleet.gfZoneEntered")

    /// Posted when the driver exits the route-boundary circle (route deviation).
    /// userInfo["distanceOutside"] = Double (metres outside)
    static let routeBoundaryBreached = NSNotification.Name("com.fleet.routeBoundaryBreached")
}
