import SwiftUI
import MapKit
import CoreLocation

/// Shows an Apple Maps preview for a trip.
/// Geocodes the fleet-manager-entered start + end addresses and places
/// two pins — green for pickup, red for drop-off. No route polyline.
/// The "Navigate in Maps" button sends both points to Apple Maps.
struct TripRouteMapView: View {

    let startAddress: String?
    let endAddress: String?

    @State private var originCoord: CLLocationCoordinate2D?
    @State private var destinationCoord: CLLocationCoordinate2D?
    @State private var originMapItem: MKMapItem?
    @State private var destinationMapItem: MKMapItem?
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

            // Show navigate button only when both endpoints are resolved
            if originMapItem != nil && destinationMapItem != nil {
                navigateButton
                    .padding(.bottom, 12)
            }
        }
        // Re-runs whenever addresses change (handles late-arriving route data)
        .task(id: "\(startAddress ?? "")|\(endAddress ?? "")") {
            await resolvePoints()
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: $cameraPosition) {
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
    }

    // MARK: - Geocoding (two pins only — no driving directions needed)

    private func resolvePoints() async {
        isLoading          = true
        errorMessage       = nil
        originCoord        = nil
        destinationCoord   = nil
        originMapItem      = nil
        destinationMapItem = nil

        guard let start = startAddress, !start.isEmpty,
              let end   = endAddress,   !end.isEmpty
        else {
            errorMessage = "No locations assigned to this trip."
            isLoading = false
            return
        }

        // Geocode both concurrently
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

        // Fit camera to frame both pins with comfortable padding
        let oCoord = origin.location.coordinate
        let dCoord = dest.location.coordinate
        let midLat = (oCoord.latitude  + dCoord.latitude)  / 2
        let midLon = (oCoord.longitude + dCoord.longitude) / 2
        let spanLat = max(abs(oCoord.latitude  - dCoord.latitude)  * 2.2, 0.02)
        let spanLon = max(abs(oCoord.longitude - dCoord.longitude) * 2.2, 0.02)
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon),
            span:   MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        ))

        isLoading = false
    }

    private func geocode(_ address: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        request.resultTypes = .address
        return try? await MKLocalSearch(request: request).start().mapItems.first
    }

    // MARK: - Open Apple Maps with pickup → drop-off

    func openAppleMaps() {
        guard let source = originMapItem,
              let dest   = destinationMapItem
        else { return }

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
