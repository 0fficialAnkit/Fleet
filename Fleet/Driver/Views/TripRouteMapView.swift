import SwiftUI
import MapKit
import CoreLocation

/// Shows an Apple Maps preview for a trip.
/// Phase 1 — geocodes pickup + drop-off addresses, shows two pins immediately.
/// Phase 2 — requests a real driving route from MKDirections, overlays the
///            polyline and refits the camera to the actual road path.
/// "Navigate in Maps" button hands both points to Apple Maps with driving mode.
struct TripRouteMapView: View {

    let startAddress: String?
    let endAddress: String?

    @State private var originCoord: CLLocationCoordinate2D?
    @State private var destinationCoord: CLLocationCoordinate2D?
    @State private var originMapItem: MKMapItem?
    @State private var destinationMapItem: MKMapItem?
    @State private var routePolyline: MKPolyline?          // nil until MKDirections responds
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    mapView
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: 260)

            if originMapItem != nil && destinationMapItem != nil {
                navigateButton
                    .padding(.bottom, 12)
            }
        }
        .task(id: "\(startAddress ?? "")|\(endAddress ?? "")") {
            await resolvePoints()
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Driving route polyline — appears once MKDirections responds
            if let polyline = routePolyline {
                MapPolyline(polyline)
                    .stroke(
                        Color.blue.opacity(0.85),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
            }

            // Pickup pin — green
            if let o = originCoord {
                Annotation("Pickup", coordinate: o, anchor: .bottom) {
                    pinView(color: .green, icon: "circle.fill")
                }
            }
            // Drop-off pin — red
            if let d = destinationCoord {
                Annotation("Drop-off", coordinate: d, anchor: .bottom) {
                    pinView(color: .red, icon: "mappin.circle.fill")
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        ZStack {
            Color(.secondarySystemBackground)
            VStack(spacing: 10) {
                ProgressView()
                Text("Loading map…")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private func errorView(_ msg: String) -> some View {
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

    // MARK: - Navigate button

    private var navigateButton: some View {
        Button(action: openAppleMaps) {
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
        .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
    }

    // MARK: - Two-phase resolution

    private func resolvePoints() async {
        // Reset everything
        isLoading          = true
        errorMessage       = nil
        originCoord        = nil
        destinationCoord   = nil
        originMapItem      = nil
        destinationMapItem = nil
        routePolyline      = nil

        guard let start = startAddress, !start.isEmpty,
              let end   = endAddress,   !end.isEmpty
        else {
            errorMessage = "No locations assigned to this trip."
            isLoading = false
            return
        }

        // ── Phase 1: geocode both addresses concurrently ──────────────────
        async let originResult = geocode(start)
        async let destResult   = geocode(end)
        let (origin, dest) = await (originResult, destResult)

        guard let origin, let dest else {
            errorMessage = "Could not find trip locations on the map."
            isLoading = false
            return
        }

        originCoord        = origin.location.coordinate
        destinationCoord   = dest.location.coordinate
        originMapItem      = origin
        destinationMapItem = dest

        // Show pins immediately — fit camera to both points
        let oCoord = origin.location.coordinate
        let dCoord = dest.location.coordinate
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude:  (oCoord.latitude  + dCoord.latitude)  / 2,
                longitude: (oCoord.longitude + dCoord.longitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta:  max(abs(oCoord.latitude  - dCoord.latitude)  * 2.2, 0.02),
                longitudeDelta: max(abs(oCoord.longitude - dCoord.longitude) * 2.2, 0.02)
            )
        ))
        isLoading = false   // ← pins visible now, polyline still loading

        // ── Phase 2: request actual driving route ─────────────────────────
        let req = MKDirections.Request()
        req.source                   = origin
        req.destination              = dest
        req.transportType            = .automobile
        req.requestsAlternateRoutes  = false

        guard let response = try? await MKDirections(request: req).calculate(),
              let mkRoute  = response.routes.first
        else { return }   // pins already visible — just skip polyline on failure

        routePolyline = mkRoute.polyline

        // Refit camera to the actual road path
        let rect   = mkRoute.polyline.boundingMapRect
        let sw     = MKMapPoint(x: rect.minX, y: rect.maxY).coordinate
        let ne     = MKMapPoint(x: rect.maxX, y: rect.minY).coordinate
        let midLat = (sw.latitude  + ne.latitude)  / 2
        let midLon = (sw.longitude + ne.longitude) / 2
        let dLat   = abs(ne.latitude  - sw.latitude)  * 1.35
        let dLon   = abs(ne.longitude - sw.longitude) * 1.35
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
                span:   MKCoordinateSpan(latitudeDelta: max(dLat, 0.01),
                                         longitudeDelta: max(dLon, 0.01))
            ))
        }
    }

    private func geocode(_ address: String) async -> MKMapItem? {
        if let range = address.range(of: "@latlng:") {
            let coordsString = address[range.upperBound...]
            let components = coordsString.components(separatedBy: ",")
            if components.count == 2,
               let lat = Double(components[0].trimmingCharacters(in: .whitespacesAndNewlines)),
               let lon = Double(components[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let placemark = MKPlacemark(coordinate: coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                let name = address[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                mapItem.name = name.isEmpty ? "Location" : name
                return mapItem
            }
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        return try? await MKLocalSearch(request: request).start().mapItems.first
    }

    // MARK: - Open Apple Maps

    func openAppleMaps() {
        guard let source = originMapItem, let dest = destinationMapItem else { return }
        source.name = startAddress ?? "Pickup"
        dest.name   = endAddress   ?? "Drop-off"
        MKMapItem.openMaps(
            with: [source, dest],
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey:   true
            ]
        )
    }
}

// MARK: - Previews

#Preview("With Route") {
    TripRouteMapView(
        startAddress: "Connaught Place, New Delhi",
        endAddress:   "Indira Gandhi International Airport, Delhi"
    )
    .padding()
}

#Preview("No Route") {
    TripRouteMapView(startAddress: nil, endAddress: nil)
        .padding()
}
