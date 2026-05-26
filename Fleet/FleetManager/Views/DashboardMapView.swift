import SwiftUI
import MapKit
import CoreLocation

/// Always-visible Apple Map on the fleet manager dashboard.
///   • Standard Apple Maps — same look as driver's trip detail
///   • Fleet manager's live location — native iOS blue dot
///   • Green pin  = pickup address for each active trip (geocoded once)
///   • Red pin    = drop-off address for each active trip (geocoded once)
///   • Teal truck = driver's LIVE GPS position (real coordinates, updates every 10 s)
struct DashboardMapView: View {

    let activeTrips: [Trip]
    let routes: [Route]
    let profiles: [Profile]
    let vehicleLocations: [VehicleLocation]   // live driver GPS from Supabase

    // Re-geocode only when the set of active trips changes
    private var tripsKey: String {
        activeTrips.map { $0.id.uuidString }.sorted().joined()
    }

    @State private var routePins: [RoutePin] = []   // geocoded pickup / drop-off
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()

    // Driver live pins need no geocoding — vehicleLocations already has coordinates
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

                // Static route pins (pickup green, drop-off red)
                ForEach(routePins) { pin in
                    Annotation(pin.label, coordinate: pin.coordinate, anchor: .bottom) {
                        routePinView(color: pin.color, icon: pin.icon)
                    }
                }

                // Live driver positions — teal truck, updates every 10 s
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

            // Badge shown when active trips exist
            if !activeTrips.isEmpty {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Text("\(activeTrips.count) active trip\(activeTrips.count == 1 ? "" : "s")")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
                .padding(.bottom, 12)
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        // Re-geocode only when trips change (addresses are static)
        .task(id: tripsKey) {
            await geocodeRoutePins()
            fitCamera()
        }
        // Refit camera whenever a driver pushes a new GPS position
        .onChange(of: vehicleLocations) { _, _ in
            fitCamera()
        }
    }

    // MARK: - Geocoding (pickup + drop-off addresses only)

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

    // MARK: - Camera fit

    private func fitCamera() {
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

        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude:  (minLat + maxLat) / 2,
                    longitude: (minLon + maxLon) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta:  max(maxLat - minLat, 0.05) * 2.2,
                    longitudeDelta: max(maxLon - minLon, 0.05) * 2.2
                )
            ))
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
    }

    private func driverPinView(name: String) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
        }
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

private func geocodeAddress(_ address: String?) async -> MKMapItem? {
    guard let address, !address.isEmpty else { return nil }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = address
    request.resultTypes = .address
    return try? await MKLocalSearch(request: request).start().mapItems.first
}
