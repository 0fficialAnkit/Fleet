import SwiftUI
import MapKit
import CoreLocation

// MARK: - Dashboard preview card

/// Compact map card shown on the fleet manager dashboard.
/// Tapping anywhere on the card opens a full-screen interactive map.
///
/// Pin / polyline legend:
///   Colored polyline  = actual driving route per trip (unique color per trip)
///   Matching circle   = pickup address
///   Matching mappin   = drop-off address
///   Teal truck        = driver's LIVE GPS (updates every ~15 s)
///   Blue dot          = fleet manager's own location
struct DashboardMapView: View {

    let activeTrips:      [Trip]
    let routes:           [Route]
    let profiles:         [Profile]
    let vehicleLocations: [VehicleLocation]

    // 6 distinct colors — cycles for more than 6 simultaneous trips
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

    @State private var tripRoutes:         [TripRoute] = []
    @State private var cameraPosition:     MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager     = LocationManager()
    @State private var lastLocationUpdate: Date? = nil
    @State private var showFullscreen      = false

    private var driverPins: [DriverPin] {
        makeDriverPins(from: vehicleLocations, activeTrips: activeTrips, profiles: profiles)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapCard
            bottomBadge
        }
        .onAppear { locationManager.requestPermission() }
        .task(id: tripsKey) {
            await buildTripRoutes()
            fitCamera()
        }
        .onChange(of: vehicleLocations) { _, newLocs in
            if !newLocs.isEmpty { lastLocationUpdate = Date() }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            DashboardMapFullscreenView(
                tripRoutes:      tripRoutes,
                activeTrips:     activeTrips,
                profiles:        profiles,
                vehicleLocations: vehicleLocations
            )
        }
    }

    // MARK: - Map card

    private var mapCard: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(tripRoutes) { route in
                MapPolyline(route.polyline)
                    .stroke(route.color.opacity(0.85),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                Annotation(route.pickupLabel, coordinate: route.pickupCoord, anchor: .bottom) {
                    routePinView(color: .green, icon: "circle.fill", size: 32)
                }
                Annotation(route.dropoffLabel, coordinate: route.dropoffCoord, anchor: .bottom) {
                    routePinView(color: .red, icon: "mappin.circle.fill", size: 32)
                }
            }

            ForEach(driverPins) { pin in
                Annotation(pin.driverName, coordinate: pin.coordinate, anchor: .bottom) {
                    driverPinView(name: pin.driverName, size: 36)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls { EmptyView() }          // controls live in the fullscreen view
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(height: 260)
        // Tap overlay — captures the whole card; map gesture still renders underneath
        .overlay {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { showFullscreen = true }
        }
        // Expand icon badge — top-right corner
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(7)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .padding(10)
                .allowsHitTesting(false)   // let taps pass through to the clear overlay
        }
    }

    // MARK: - Bottom badge

    @ViewBuilder
    private var bottomBadge: some View {
        if !activeTrips.isEmpty || !driverPins.isEmpty {
            HStack(spacing: 8) {
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

    // MARK: - Route builder (geocode + MKDirections)

    private func buildTripRoutes() async {
        var resolved: [TripRoute] = []
        await withTaskGroup(of: TripRoute?.self) { group in
            for (index, trip) in activeTrips.enumerated() {
                guard let route = routes.first(where: { $0.id == trip.routeId }) else { continue }
                let driverName = profiles.first { $0.id == trip.driverId }?.fullName ?? "Driver"
                let color      = tripColors[index % tripColors.count]
                let tripId     = trip.id

                group.addTask {
                    async let startItem = geocodeAddress(route.startLocation)
                    async let endItem   = geocodeAddress(route.endLocation)
                    guard let origin = await startItem, let dest = await endItem else { return nil }

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
            for await route in group { if let route { resolved.append(route) } }
        }
        tripRoutes = resolved
    }

    // MARK: - Camera

    private func fitCamera() {
        // Build bounding box from routes + live driver pins only.
        // Do NOT include the manager's own location — if the manager is on a
        // simulator set to Apple Park (California) and the routes are in India,
        // mixing both coordinates creates a half-globe bounding box.
        var coords = allPolylineCoords(from: tripRoutes)
        coords += driverPins.map(\.coordinate)

        // Fallback: use pickup/drop-off coords when polylines aren't ready yet
        if coords.isEmpty {
            coords = tripRoutes.flatMap { [$0.pickupCoord, $0.dropoffCoord] }
        }

        guard !coords.isEmpty else {
            // No routes at all — zoom in on the manager's own location
            if let mgr = locationManager.coordinate {
                cameraPosition = .region(MKCoordinateRegion(
                    center: mgr,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ))
            } else {
                cameraPosition = .userLocation(fallback: .automatic)
            }
            return
        }

        cameraPosition = .region(boundingRegion(for: coords, padding: 1.35))
    }

    // MARK: - Pin views

    private func routePinView(color: Color, icon: String, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(color.opacity(0.18)).frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(color)
        }
        .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
    }

    private func driverPinView(name: String, size: CGFloat) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().fill(Color.teal.opacity(0.18)).frame(width: size, height: size)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }
            .shadow(color: Color.teal.opacity(0.25), radius: 4, y: 2)
            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
        }
    }
}

// MARK: - Full-screen interactive map

struct DashboardMapFullscreenView: View {

    let tripRoutes:       [TripRoute]
    let activeTrips:      [Trip]
    let profiles:         [Profile]
    let vehicleLocations: [VehicleLocation]

    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition = MapCameraPosition.automatic
    @State private var locationManager = LocationManager()

    private var driverPins: [DriverPin] {
        makeDriverPins(from: vehicleLocations, activeTrips: activeTrips, profiles: profiles)
    }

    var body: some View {
        ZStack {
            // ── Full-screen map ──────────────────────────────────────────
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(tripRoutes) { route in
                    MapPolyline(route.polyline)
                        .stroke(route.color.opacity(0.85),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    Annotation(route.pickupLabel, coordinate: route.pickupCoord, anchor: .bottom) {
                        fullscreenPin(color: .green, icon: "circle.fill")
                    }
                    Annotation(route.dropoffLabel, coordinate: route.dropoffCoord, anchor: .bottom) {
                        fullscreenPin(color: .red, icon: "mappin.circle.fill")
                    }
                }

                ForEach(driverPins) { pin in
                    Annotation(pin.driverName, coordinate: pin.coordinate, anchor: .bottom) {
                        fullscreenDriverPin(name: pin.driverName)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                // MapUserLocationButton removed — using custom button below (bottom-right)
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            // ── Close button — top-left, red (native iOS style) ──────────
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.red)
                        }
                        .shadow(color: Color.black.opacity(0.15), radius: 6, y: 2)
                    }
                    Spacer()
                    // Trip color legend (multi-trip only)
                    if tripRoutes.count > 1 {
                        HStack(spacing: 5) {
                            ForEach(Array(tripRoutes.enumerated()), id: \.offset) { _, route in
                                Circle()
                                    .fill(route.color)
                                    .frame(width: 11, height: 11)
                                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.regularMaterial, in: Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
                Spacer()
            }

            // ── My Location button — bottom-right ─────────────────────────
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            cameraPosition = .userLocation(fallback: .automatic)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial,
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, tripRoutes.isEmpty ? 48 : 160)
                }
            }

            // ── Bottom legend panel ────────────────────────────────────────
            VStack {
                Spacer()
                if !tripRoutes.isEmpty {
                    bottomLegend
                        .padding(.bottom, 36)
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
            fitCamera()
        }
    }

    // MARK: - Bottom legend

    private var bottomLegend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(tripRoutes) { route in
                HStack(spacing: 10) {
                    // Colored route swatch
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(route.color)
                        .frame(width: 24, height: 4)

                    // Pickup → Drop-off label
                    let pickup  = route.pickupLabel.replacingOccurrences(of: "Pickup · ", with: "")
                    let dropoff = route.dropoffLabel.replacingOccurrences(of: "Drop-off · ", with: "")
                    Text(pickup == dropoff ? pickup : "\(pickup)  →  \(dropoff)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Show truck if driver is live
                    if driverPins.first(where: { pin in
                        activeTrips.first { $0.routeId == nil || true }?.vehicleId == pin.id
                    }) != nil {
                        Image(systemName: "truck.box.fill")
                            .font(.caption)
                            .foregroundStyle(Color.teal)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Camera

    private func fitCamera() {
        // Build bounding box from routes + live driver pins only.
        // Do NOT include the manager's own location — if the manager is on a
        // simulator set to Apple Park (California) and the routes are in India,
        // mixing both coordinates creates a half-globe bounding box.
        var coords = allPolylineCoords(from: tripRoutes)
        coords += driverPins.map(\.coordinate)

        // Fallback: use pickup/drop-off coords when polylines aren't ready yet
        if coords.isEmpty {
            coords = tripRoutes.flatMap { [$0.pickupCoord, $0.dropoffCoord] }
        }

        guard !coords.isEmpty else {
            // No routes at all — zoom in on the manager's own location
            if let mgr = locationManager.coordinate {
                cameraPosition = .region(MKCoordinateRegion(
                    center: mgr,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                ))
            } else {
                cameraPosition = .userLocation(fallback: .automatic)
            }
            return
        }

        cameraPosition = .region(boundingRegion(for: coords, padding: 1.3))
    }

    // MARK: - Pin views

    private func fullscreenPin(color: Color, icon: String) -> some View {
        ZStack {
            Circle().fill(color.opacity(0.18)).frame(width: 42, height: 42)
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
        }
        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }

    private func fullscreenDriverPin(name: String) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().fill(Color.teal.opacity(0.18)).frame(width: 50, height: 50)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }
            .shadow(color: Color.teal.opacity(0.3), radius: 5, y: 2)
            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.regularMaterial, in: Capsule())
        }
    }
}

// MARK: - Shared model types

struct TripRoute: Identifiable {
    let id:           UUID
    let polyline:     MKPolyline
    let color:        Color
    let pickupLabel:  String
    let pickupCoord:  CLLocationCoordinate2D
    let dropoffLabel: String
    let dropoffCoord: CLLocationCoordinate2D
}

struct DriverPin: Identifiable {
    let id:         UUID
    let driverName: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Shared helpers

/// Builds driver GPS pins from the current vehicleLocations snapshot.
func makeDriverPins(from vehicleLocations: [VehicleLocation],
                    activeTrips: [Trip],
                    profiles: [Profile]) -> [DriverPin] {
    vehicleLocations.compactMap { loc in
        guard let lat = loc.latitude, let lon = loc.longitude else { return nil }
        let trip = activeTrips.first { $0.vehicleId == loc.vehicleId }
        let name = profiles.first { $0.id == trip?.driverId }?.fullName ?? "Driver"
        return DriverPin(id: loc.vehicleId, driverName: name,
                         coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
}

/// Extracts every coordinate from every polyline in a TripRoute array.
func allPolylineCoords(from routes: [TripRoute]) -> [CLLocationCoordinate2D] {
    routes.flatMap { route -> [CLLocationCoordinate2D] in
        let pts = route.polyline.points()
        return (0..<route.polyline.pointCount).map { pts[$0].coordinate }
    }
}

/// Returns an MKCoordinateRegion that tightly wraps all given coordinates,
/// expanded by `padding` (e.g. 1.35 = 35 % breathing room on each axis).
func boundingRegion(for coords: [CLLocationCoordinate2D],
                    padding: Double) -> MKCoordinateRegion {
    var minLat =  90.0, maxLat = -90.0
    var minLon = 180.0, maxLon = -180.0
    for c in coords {
        minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
        minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
    }
    return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude:  (minLat + maxLat) / 2,
                                       longitude: (minLon + maxLon) / 2),
        span: MKCoordinateSpan(latitudeDelta:  max(maxLat - minLat, 0.02) * padding,
                               longitudeDelta: max(maxLon - minLon, 0.02) * padding)
    )
}

/// Returns a human-readable "Xs ago / Xm ago / just now" string.
func relativeTime(_ date: Date) -> String {
    let secs = Int(Date().timeIntervalSince(date))
    if secs < 5  { return "just now" }
    if secs < 60 { return "\(secs)s ago" }
    return "\(secs / 60)m ago"
}

/// Geocodes a free-text address to the first matching MKMapItem.
func geocodeAddress(_ address: String?) async -> MKMapItem? {
    guard let address, !address.isEmpty else { return nil }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = address
    request.resultTypes = .address
    return try? await MKLocalSearch(request: request).start().mapItems.first
}
