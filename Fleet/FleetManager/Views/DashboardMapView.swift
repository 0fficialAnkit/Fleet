import SwiftUI
import MapKit
import CoreLocation

/// Always-visible Apple Map on the fleet manager dashboard.
///
/// Pin legend:
///   🟢 circle.fill       = pickup address for each active trip (geocoded once per trip)
///   🔴 mappin.circle.fill = drop-off address for each active trip (geocoded once per trip)
///   🔵 UserAnnotation    = fleet manager's live location (native iOS blue dot)
///   🟦 truck.box.fill    = driver's LIVE GPS position (updates every ~15 s from Supabase)
///
/// Camera behaviour:
///   • Fits to all pins once when trips first load (or change).
///   • Does NOT refit when driver positions update — the truck pin slides smoothly
///     to its new position so the fleet manager's manual zoom/pan is preserved.
struct DashboardMapView: View {

    let activeTrips: [Trip]
    let routes: [Route]
    let profiles: [Profile]
    let vehicleLocations: [VehicleLocation]   // live driver GPS from Supabase

    // Re-geocode only when the set of active trips changes
    private var tripsKey: String {
        activeTrips.map { $0.id.uuidString }.sorted().joined()
    }

    @State private var routePins: [RoutePin] = []
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()
    @State private var lastLocationUpdate: Date? = nil
    @State private var isGeocoding = false

    // Driver live pins — derived directly from vehicleLocations (no geocoding needed)
    private var driverPins: [DriverPin] {
        vehicleLocations.compactMap { loc in
            guard let lat = loc.latitude, let lon = loc.longitude else { return nil }
            let trip    = activeTrips.first { $0.vehicleId == loc.vehicleId }
            let name    = profiles.first { $0.id == trip?.driverId }?.fullName ?? "Driver"
            return DriverPin(
                id: loc.vehicleId,
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

                // Static route pins (pickup = green, drop-off = red)
                // These are geocoded once and cached in routePins.
                ForEach(routePins) { pin in
                    Annotation(pin.label, coordinate: pin.coordinate, anchor: .bottom) {
                        routePinView(color: pin.color, icon: pin.icon)
                    }
                }

                // Live driver positions — teal truck, updates every ~15 s
                // MapKit automatically animates the annotation to the new coordinate
                // when the id is the same, so the pin slides smoothly across the map.
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

            // Bottom badge — shows active trip count + how fresh the data is
            bottomBadge
        }
        .onAppear {
            locationManager.requestPermission()
        }
        // Re-geocode and fit camera only when the set of active trips changes
        .task(id: tripsKey) {
            isGeocoding = true
            await geocodeRoutePins()
            isGeocoding = false
            fitCameraToAllPins(animated: false)
        }
        // When new driver GPS arrives: update the "last refreshed" timestamp.
        // The truck pin slides to its new position automatically — NO camera refit.
        .onChange(of: vehicleLocations) { _, newLocs in
            guard !newLocs.isEmpty else { return }
            lastLocationUpdate = Date()
        }
    }

    // MARK: - Bottom badge

    @ViewBuilder
    private var bottomBadge: some View {
        if !activeTrips.isEmpty || !driverPins.isEmpty {
            HStack(spacing: 6) {
                // Live indicator pulse dot
                Circle()
                    .fill(driverPins.isEmpty ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)

                if driverPins.isEmpty {
                    Text("\(activeTrips.count) trip\(activeTrips.count == 1 ? "" : "s") — awaiting driver GPS")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text("\(driverPins.count) driver\(driverPins.count == 1 ? "" : "s") live")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.secondary)

                    if let ts = lastLocationUpdate {
                        Text("· updated \(relativeTime(ts))")
                            .font(.caption)
                            .foregroundStyle(Color.secondary.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 12)
        }
    }

    // MARK: - Geocoding (pickup + drop-off addresses — fires once per trip set)

    private func geocodeRoutePins() async {
        var resolved: [RoutePin] = []

        await withTaskGroup(of: [RoutePin].self) { group in
            for trip in activeTrips {
                guard let route = routes.first(where: { $0.id == trip.routeId }) else { continue }
                let driverName = profiles.first { $0.id == trip.driverId }?.fullName ?? "Driver"

                group.addTask {
                    var tripPins: [RoutePin] = []
                    async let startItem = geocodeAddress(route.startLocation)
                    async let endItem   = geocodeAddress(route.endLocation)

                    if let item = await startItem {
                        tripPins.append(RoutePin(
                            id: trip.id.uuidString + "_start",
                            label: "Pickup · \(driverName)",
                            coordinate: item.location.coordinate,
                            color: .green,
                            icon: "circle.fill"
                        ))
                    }
                    if let item = await endItem {
                        tripPins.append(RoutePin(
                            id: trip.id.uuidString + "_end",
                            label: "Drop-off · \(driverName)",
                            coordinate: item.location.coordinate,
                            color: .red,
                            icon: "mappin.circle.fill"
                        ))
                    }
                    return tripPins
                }
            }
            for await tripPins in group {
                resolved.append(contentsOf: tripPins)
            }
        }

        routePins = resolved
    }

    // MARK: - Camera — called only once when trips load (not on every GPS update)

    private func fitCameraToAllPins(animated: Bool) {
        var coords: [CLLocationCoordinate2D] = []
        coords += routePins.map(\.coordinate)
        coords += driverPins.map(\.coordinate)
        if let mgr = locationManager.coordinate { coords.append(mgr) }

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

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude:  (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta:  max(maxLat - minLat, 0.05) * 2.2,
                longitudeDelta: max(maxLon - minLon, 0.05) * 2.2
            )
        )

        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }

    // MARK: - Pin views

    private func routePinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
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

    // MARK: - Helpers

    private func relativeTime(_ date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 5  { return "just now" }
        if secs < 60 { return "\(secs)s ago" }
        return "\(secs / 60)m ago"
    }
}

// MARK: - Models

private struct RoutePin: Identifiable {
    let id: String
    let label: String
    let coordinate: CLLocationCoordinate2D
    let color: Color
    let icon: String
}

private struct DriverPin: Identifiable {
    let id: UUID
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
