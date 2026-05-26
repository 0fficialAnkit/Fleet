import SwiftUI
import MapKit
import CoreLocation

/// Shows a live Apple Maps view for a trip route.
/// Geocodes start + end addresses from Supabase — no hardcoded coordinates.
struct TripRouteMapView: View {

    let startAddress: String?
    let endAddress: String?

    // Resolved state
    @State private var originCoord: CLLocationCoordinate2D?
    @State private var destinationCoord: CLLocationCoordinate2D?
    @State private var originMapItem: MKMapItem?
    @State private var destinationMapItem: MKMapItem?
    @State private var mkRoute: MKRoute?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var locationManager = LocationManager()

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isLoading {
                    loadingPlaceholder
                } else if let error = errorMessage {
                    errorPlaceholder(error)
                } else {
                    liveMap
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: 260)

            if originMapItem != nil && destinationMapItem != nil {
                openInMapsButton
                    .padding(.bottom, 12)
            }
        }
        // Re-runs automatically whenever startAddress or endAddress changes,
        // which handles the case where route loads after the view appears.
        .task(id: "\(startAddress ?? "")|\(endAddress ?? "")") {
            locationManager.requestPermission()
            await resolveRoute()
        }
        .onDisappear {
            locationManager.stopUpdating()
        }
    }

    // MARK: - Sub-views

    private var liveMap: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            if let o = originCoord {
                Annotation("Pickup", coordinate: o, anchor: .bottom) {
                    pinView(color: .green, icon: "circle.fill")
                }
            }

            if let d = destinationCoord {
                Annotation("Drop-off", coordinate: d, anchor: .bottom) {
                    pinView(color: .red, icon: "mappin.circle.fill")
                }
            }

            if let route = mkRoute {
                MapPolyline(route.polyline)
                    .stroke(Color.blue, style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round,
                        lineJoin: .round
                    ))
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading route…")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private func errorPlaceholder(_ msg: String) -> some View {
        ZStack {
            Color(.secondarySystemBackground)
            VStack(spacing: 10) {
                Image(systemName: "map.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.green.opacity(0.4))
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var openInMapsButton: some View {
        Button(action: openAppleMapsNavigation) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                Text("Navigate in Maps")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.green)
            .clipShape(Capsule())
            .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
        }
    }

    private func pinView(color: Color, icon: String) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Geocoding

    private func resolveRoute() async {
        // Reset state for fresh resolution
        isLoading = true
        errorMessage = nil
        mkRoute = nil
        originCoord = nil
        destinationCoord = nil
        originMapItem = nil
        destinationMapItem = nil

        guard let start = startAddress, !start.isEmpty,
              let end   = endAddress,   !end.isEmpty
        else {
            errorMessage = "No route assigned to this trip."
            isLoading = false
            return
        }

        // Geocode both addresses concurrently
        async let originResult = geocodeAddress(start)
        async let destResult   = geocodeAddress(end)
        let (origin, destination) = await (originResult, destResult)

        guard let origin, let destination else {
            errorMessage = "Could not find route locations on the map."
            isLoading = false
            return
        }

        originCoord        = origin.location.coordinate
        destinationCoord   = destination.location.coordinate
        originMapItem      = origin
        destinationMapItem = destination

        guard let oCoord = originCoord, let dCoord = destinationCoord else {
            errorMessage = "Could not read route coordinates."
            isLoading = false
            return
        }

        // Request driving directions
        let directionsRequest = MKDirections.Request()
        directionsRequest.source        = origin
        directionsRequest.destination   = destination
        directionsRequest.transportType = .automobile

        do {
            let response = try await MKDirections(request: directionsRequest).calculate()
            mkRoute = response.routes.first

            if let polyline = response.routes.first?.polyline {
                let region = MKCoordinateRegion(
                    polyline.boundingMapRect.insetBy(dx: -8_000, dy: -8_000)
                )
                cameraPosition = .region(region)
            }
        } catch {
            // Directions failed — still show the two pins
            let center = CLLocationCoordinate2D(
                latitude:  (oCoord.latitude  + dCoord.latitude)  / 2,
                longitude: (oCoord.longitude + dCoord.longitude) / 2
            )
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: center,
                    latitudinalMeters: 30_000,
                    longitudinalMeters: 30_000
                )
            )
        }

        isLoading = false
    }

    private func geocodeAddress(_ address: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        request.resultTypes = .address
        return try? await MKLocalSearch(request: request).start().mapItems.first
    }

    // MARK: - Open Apple Maps

    func openAppleMapsNavigation() {
        guard let sourceItem = originMapItem,
              let destItem   = destinationMapItem
        else { return }

        sourceItem.name = startAddress ?? "Pickup"
        destItem.name   = endAddress   ?? "Destination"

        MKMapItem.openMaps(
            with: [sourceItem, destItem],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ]
        )
    }
}

// MARK: - Preview

#Preview("With Route") {
    TripRouteMapView(
        startAddress: "Connaught Place, New Delhi",
        endAddress: "Indira Gandhi International Airport, Delhi"
    )
    .padding()
}

#Preview("No Route") {
    TripRouteMapView(
        startAddress: nil,
        endAddress: nil
    )
    .padding()
}
