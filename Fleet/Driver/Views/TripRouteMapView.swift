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
    @State private var originMapItem: MKMapItem?       // used for Navigate in Maps (source)
    @State private var destinationMapItem: MKMapItem?  // used for Navigate in Maps (destination)
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

            // "Navigate" pill — shown once both addresses are resolved
            if originMapItem != nil && destinationMapItem != nil {
                openInMapsButton
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            Task { await resolveRoute() }
        }
        .onDisappear {
            locationManager.stopUpdating()
        }
    }

    // MARK: - Sub-views

    private var liveMap: some View {
        Map(position: $cameraPosition) {

            // Driver's live blue dot
            UserAnnotation()

            // Origin pin
            if let o = originCoord {
                Annotation("Pickup", coordinate: o, anchor: .bottom) {
                    pinView(color: .green, icon: "circle.fill")
                }
            }

            // Destination pin
            if let d = destinationCoord {
                Annotation("Drop-off", coordinate: d, anchor: .bottom) {
                    pinView(color: .red, icon: "mappin.circle.fill")
                }
            }

            // Driving-directions polyline
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
                    .font(.system(size: 16, weight: .regular, design: .rounded))
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
                    .font(.system(size: 16, weight: .regular, design: .rounded))
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
                    .font(.system(size: 16, weight: .medium, design: .rounded))
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
        // Geocode both addresses concurrently
        async let originItem = geocodeAddress(startAddress)
        async let destItem   = geocodeAddress(endAddress)

        let (origin, destination) = await (originItem, destItem)

        guard let origin, let destination else {
            errorMessage = startAddress == nil && endAddress == nil
                ? "No route assigned to this trip."
                : "Could not resolve route addresses."
            isLoading = false
            return
        }

        originCoord        = origin.location.coordinate
        destinationCoord   = destination.location.coordinate
        originMapItem      = origin       // store for Navigate in Maps
        destinationMapItem = destination  // store for Navigate in Maps

        guard let oCoord = originCoord, let dCoord = destinationCoord else {
            errorMessage = "Could not read route coordinates."
            isLoading = false
            return
        }

        // Calculate driving directions
        let request = MKDirections.Request()
        request.source        = origin
        request.destination   = destination
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
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
                MKCoordinateRegion(center: center,
                                   latitudinalMeters: 30_000,
                                   longitudinalMeters: 30_000)
            )
        }

        isLoading = false
    }

    private func geocodeAddress(_ address: String?) async -> MKMapItem? {
        guard let address, !address.isEmpty else { return nil }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        request.resultTypes = .address
        return try? await MKLocalSearch(request: request).start().mapItems.first
    }

    // MARK: - Open Apple Maps with exact fleet-manager-specified route

    func openAppleMapsNavigation() {
        guard let sourceItem = originMapItem,
              let destItem   = destinationMapItem
        else { return }

        // Label with the real addresses from the order
        sourceItem.name = startAddress ?? "Pickup"
        destItem.name   = endAddress   ?? "Destination"

        // Pass BOTH points so Apple Maps routes from the fleet-manager's
        // start location to the fleet-manager's end location exactly
        MKMapItem.openMaps(
            with: [sourceItem, destItem],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ]
        )
    }
}
