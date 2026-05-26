import SwiftUI
import MapKit
import CoreLocation

// MARK: - Compact dashboard card

struct FleetMapView: View {

    let vehicleLocations: [VehicleLocation]
    let activeTrips: [Trip]
    let profiles: [Profile]

    @State private var showFullscreen = false
    // Writable binding — required for .userLocation camera mode to track the manager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()

    private var vehicleKey: String {
        vehicleLocations.map { $0.vehicleId.uuidString }.sorted().joined()
    }

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(pins) { pin in
                Annotation(pin.driverName, coordinate: pin.coordinate, anchor: .bottom) {
                    driverPin
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Transparent tap overlay — does NOT disable the map itself
        .overlay {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { showFullscreen = true }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(7)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 7))
                .padding(10)
                .allowsHitTesting(false)   // don't block the tap overlay
        }
        .onAppear {
            locationManager.requestPermission()
        }
        // Re-fit camera whenever active vehicles change
        .task(id: vehicleKey) {
            updateCamera()
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FleetMapFullscreenView(
                vehicleLocations: vehicleLocations,
                activeTrips: activeTrips,
                profiles: profiles
            )
        }
    }

    // MARK: - Camera

    private func updateCamera() {
        guard !pins.isEmpty else {
            // No active vehicles — stay on manager's live location
            cameraPosition = .userLocation(fallback: .automatic)
            return
        }
        var coords = pins.map(\.coordinate)
        if let mgr = locationManager.coordinate { coords.append(mgr) }

        var minLat =  90.0, maxLat = -90.0
        var minLon = 180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude:  (minLat + maxLat) / 2,
                    longitude: (minLon + maxLon) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta:  max(maxLat - minLat, 0.05) * 1.7,
                    longitudeDelta: max(maxLon - minLon, 0.05) * 1.7
                )
            ))
        }
    }

    // MARK: - Pins

    private var pins: [VehiclePin] {
        vehicleLocations.compactMap { loc in
            guard let lat = loc.latitude, let lon = loc.longitude else { return nil }
            let trip = activeTrips.first { $0.vehicleId == loc.vehicleId }
            let name = profiles.first { $0.id == trip?.driverId }?.fullName ?? "Driver"
            return VehiclePin(id: loc.vehicleId, driverName: name,
                              coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    private var driverPin: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.18))
                .frame(width: 36, height: 36)
            Image(systemName: "truck.box.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.green)
        }
        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }
}

// MARK: - Full-screen view

struct FleetMapFullscreenView: View {

    let vehicleLocations: [VehicleLocation]
    let activeTrips: [Trip]
    let profiles: [Profile]

    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = LocationManager()

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(pins) { pin in
                    Annotation(pin.driverName, coordinate: pin.coordinate, anchor: .bottom) {
                        VStack(spacing: 3) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.18))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "truck.box.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color.green)
                            }
                            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                            Text(pin.driverName)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.regularMaterial, in: Capsule())
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            // Top bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 34, height: 34)
                        .background(.regularMaterial, in: Circle())
                }
                Spacer()
                Text("Live Fleet")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                Spacer()
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)

            // Bottom badge
            if !pins.isEmpty {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("\(pins.count) vehicle\(pins.count == 1 ? "" : "s") on route")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
            fitCamera()
        }
    }

    private var pins: [VehiclePin] {
        vehicleLocations.compactMap { loc in
            guard let lat = loc.latitude, let lon = loc.longitude else { return nil }
            let trip = activeTrips.first { $0.vehicleId == loc.vehicleId }
            let name = profiles.first { $0.id == trip?.driverId }?.fullName ?? "Driver"
            return VehiclePin(id: loc.vehicleId, driverName: name,
                              coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }

    private func fitCamera() {
        guard !pins.isEmpty else { return }
        var coords = pins.map(\.coordinate)
        if let mgr = locationManager.coordinate { coords.append(mgr) }

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
                latitudeDelta:  max(maxLat - minLat, 0.05) * 1.7,
                longitudeDelta: max(maxLon - minLon, 0.05) * 1.7
            )
        ))
    }
}

// MARK: - Model

private struct VehiclePin: Identifiable {
    let id: UUID
    let driverName: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview

#Preview {
    FleetMapView(vehicleLocations: [], activeTrips: [], profiles: [])
        .padding()
}
