import SwiftUI
import MapKit
import CoreLocation

/// Always-visible fleet manager dashboard map.
///
/// Each active trip gets a unique color.  That same color is used for:
///   • The driving-route polyline  (pickup → drop-off via real roads)
///   • The pickup pin              (circle at the start address)
///   • The drop-off pin            (mappin at the end address)
///
/// The teal truck pin is always teal — it shows the driver's LIVE GPS
/// and is visually separate from the static route color.
///
/// When there is more than one active trip the bottom badge shows a row
/// of colored dots so the fleet manager can match colors to trips.
struct DashboardMapView: View {

    let activeTrips:      [Trip]
    let routes:           [Route]
    let profiles:         [Profile]
    let vehicleLocations: [VehicleLocation]

    // Unique color per trip — cycles if there are more than 6 simultaneous trips
    private let tripColors: [Color] = [
        Color(red: 0.20, green: 0.46, blue: 1.00),  // blue
        Color(red: 1.00, green: 0.55, blue: 0.00),  // orange
        Color(red: 0.60, green: 0.20, blue: 0.90),  // purple
        Color(red: 0.95, green: 0.20, blue: 0.35),  // red-pink
        Color(red: 0.10, green: 0.65, blue: 0.40),  // emerald
        Color(red: 0.80, green: 0.50, blue: 0.10),  // amber-brown
    ]

    private var tripsKey: String {
        activeTrips.map { $0.id.uuidString }.sorted().joined()
    }

    @State private var tripRoutes:          [TripRoute] = []
    @State private var cameraPosition:      MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager      = LocationManager()
    @State private var lastLocationUpdate:  Date? = nil

    // Driver live pins — real GPS, no geocoding
    private var driverPins: [DriverPin] {
        vehicleLocations.compactMap { loc in
            guard let lat = loc.latitude, let lon = loc.longitude else { return nil }
            let trip = activeTrips.first { $0.vehicleId == loc.vehicleId }
            let name = profiles.first { $0.id == trip?.driverId }?.fullName ?? "Driver"
            return DriverPin(
                id:         loc.vehicleId,
                driverName: name,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {

                // Fleet manager — native blue dot
                UserAnnotation()

                // ── Per-trip: polyline + pickup pin + drop-off pin ────────
                ForEach(tripRoutes) { route in
                    // Driving route polyline in the trip's unique color
                    MapPolyline(route.polyline)
                        .stroke(
                            route.color.opacity(0.85),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )

                    // Pickup pin
                    Annotation(route.pickupLabel, coordinate: route.pickupCoord, anchor: .bottom) {
                        routePinView(color: route.color, icon: "circle.fill")
                    }

                    // Drop-off pin
                    Annotation(route.dropoffLabel, coordinate: route.dropoffCoord, anchor: .bottom) {
                        routePinView(color: route.color, icon: "mappin.circle.fill")
                    }
                }

                // ── Driver live positions — teal truck ────────────────────
                ForEach(driverPins) { pin in
                    Annotation(pin.driverName, coordinate: pin.coordinate, anchor: .bottom) {
                        driverPinView(name: pin.driverName)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: 260)

            bottomBadge
        }
        .onAppear { locationManager.requestPermission() }
        // Rebuild routes (geocode + directions) only when the trip set changes
        .task(id: tripsKey) {
            await buildTripRoutes()
            fitCamera()
        }
        // Driver pin slides to new position automatically — only update timestamp
        .onChange(of: vehicleLocations) { _, newLocs in
            if !newLocs.isEmpty { lastLocationUpdate = Date() }
        }
    }

    // MARK: - Bottom badge

    @ViewBuilder
    private var bottomBadge: some View {
        if !activeTrips.isEmpty || !driverPins.isEmpty {
            HStack(spacing: 8) {
                // Live pulse dot
                Circle()
                    .fill(driverPins.isEmpty ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)

                if driverPins.isEmpty {
                    Text("\(activeTrips.count) trip\(activeTrips.count == 1 ? "" : "s") — awaiting GPS")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text("\(driverPins.count) driver\(driverPins.count == 1 ? "" : "s") live")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.secondary)
                    if let ts = lastLocationUpdate {
                        Text("· \(relativeTime(ts))")
                            .font(.caption)
                            .foregroundStyle(Color.secondary.opacity(0.8))
                    }
                }

                // Color legend — one dot per trip when there are multiple
                if tripRoutes.count > 1 {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 12)
                    ForEach(Array(tripRoutes.enumerated()), id: \.offset) { _, route in
                        Circle()
                            .fill(route.color)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 12)
        }
    }

    // MARK: - Build trip routes (geocode addresses + request driving directions)

    private func buildTripRoutes() async {
        var resolved: [TripRoute] = []

        await withTaskGroup(of: TripRoute?.self) { group in
            for (index, trip) in activeTrips.enumerated() {
                guard let route = routes.first(where: { $0.id == trip.routeId }) else { continue }
                let driverName = profiles.first { $0.id == trip.driverId }?.fullName ?? "Driver"
                let color      = tripColors[index % tripColors.count]
                let tripId     = trip.id

                group.addTask {
                    // Geocode pickup + drop-off concurrently
                    async let startItem = geocodeAddress(route.startLocation)
                    async let endItem   = geocodeAddress(route.endLocation)

                    guard let origin = await startItem,
                          let dest   = await endItem else { return nil }

                    // Request real driving route
                    let req = MKDirections.Request()
                    req.source                  = origin
                    req.destination             = dest
                    req.transportType           = .automobile
                    req.requestsAlternateRoutes = false

                    let polyline: MKPolyline
                    if let response = try? await MKDirections(request: req).calculate(),
                       let mkRoute  = response.routes.first {
                        polyline = mkRoute.polyline
                    } else {
                        // Fallback: straight line so pins still appear even if directions fail
                        var coords = [origin.location.coordinate, dest.location.coordinate]
                        polyline = MKPolyline(coordinates: &coords, count: 2)
                    }

                    return TripRoute(
                        id:           tripId,
                        polyline:     polyline,
                        color:        color,
                        pickupLabel:  "Pickup · \(driverName)",
                        pickupCoord:  origin.location.coordinate,
                        dropoffLabel: "Drop-off · \(driverName)",
                        dropoffCoord: dest.location.coordinate
                    )
                }
            }

            for await route in group {
                if let route { resolved.append(route) }
            }
        }

        tripRoutes = resolved
    }

    // MARK: - Camera — fits to the bounding box of all route polylines + driver pins

    private func fitCamera() {
        var coords: [CLLocationCoordinate2D] = []

        // Use every point in every polyline for a tight fit on the actual roads
        for route in tripRoutes {
            let pts = route.polyline.points()
            for i in 0..<route.polyline.pointCount {
                coords.append(pts[i].coordinate)
            }
        }
        coords += driverPins.map(\.coordinate)
        if let mgr = locationManager.coordinate { coords.append(mgr) }

        // If polylines haven't loaded yet fall back to pickup/drop-off points
        if coords.isEmpty {
            coords = tripRoutes.flatMap { [$0.pickupCoord, $0.dropoffCoord] }
        }

        guard !coords.isEmpty else {
            cameraPosition = .userLocation(fallback: .automatic)
            return
        }

        var minLat =  90.0, maxLat = -90.0
        var minLon = 180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }

        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude:  (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta:  max(maxLat - minLat, 0.02) * 1.35,
                longitudeDelta: max(maxLon - minLon, 0.02) * 1.35
            )
        ))
    }

    // MARK: - Pin views

    private func routePinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
        }
        .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
    }

    private func driverPinView(name: String) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }
            .shadow(color: Color.teal.opacity(0.25), radius: 4, y: 2)
            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 5  { return "just now" }
        if secs < 60 { return "\(secs)s ago" }
        return "\(secs / 60)m ago"
    }
}

// MARK: - Models

private struct TripRoute: Identifiable {
    let id:           UUID          // trip ID
    let polyline:     MKPolyline
    let color:        Color
    let pickupLabel:  String
    let pickupCoord:  CLLocationCoordinate2D
    let dropoffLabel: String
    let dropoffCoord: CLLocationCoordinate2D
}

private struct DriverPin: Identifiable {
    let id:         UUID
    let driverName: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Geocoding helper

private func geocodeAddress(_ address: String?) async -> MKMapItem? {
    guard let address, !address.isEmpty else { return nil }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = address
    request.resultTypes = .address
    return try? await MKLocalSearch(request: request).start().mapItems.first
}
