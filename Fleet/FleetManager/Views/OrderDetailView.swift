import SwiftUI
import MapKit
import CoreLocation

// MARK: - Trip Phase

enum TripPhase {
    case scheduled
    case enRouteToPickup    // active, road dist to pickup > 5 km
    case nearPickup         // active, road dist to pickup ≤ 5 km
    case atPickup           // active, road dist to pickup ≤ 0.5 km
    case enRouteToDropoff   // active, driver closer to dropoff than pickup
    case nearDropoff        // active, road dist to dropoff ≤ 5 km
    case atDropoff          // active, road dist to dropoff ≤ 0.5 km
    case completed
    case cancelled

    var label: String {
        switch self {
        case .scheduled:        return "Scheduled"
        case .enRouteToPickup:  return "En route to pickup"
        case .nearPickup:       return "Near pickup"
        case .atPickup:         return "At pickup"
        case .enRouteToDropoff: return "En route to drop-off"
        case .nearDropoff:      return "Near drop-off"
        case .atDropoff:        return "At drop-off"
        case .completed:        return "Completed"
        case .cancelled:        return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .scheduled:        return .blue
        case .enRouteToPickup:  return .blue
        case .nearPickup:       return .orange
        case .atPickup:         return .green
        case .enRouteToDropoff: return .blue
        case .nearDropoff:      return .orange
        case .atDropoff:        return .teal
        case .completed:        return .green
        case .cancelled:        return .red
        }
    }

    var icon: String {
        switch self {
        case .scheduled:        return "clock"
        case .enRouteToPickup:  return "road.lanes"
        case .nearPickup:       return "location.fill"
        case .atPickup:         return "mappin.circle.fill"
        case .enRouteToDropoff: return "road.lanes"
        case .nearDropoff:      return "location.fill"
        case .atDropoff:        return "flag.checkered.circle.fill"
        case .completed:        return "checkmark.circle.fill"
        case .cancelled:        return "xmark.circle.fill"
        }
    }
}

// MARK: - Order Detail View

struct OrderDetailView: View {

    let trip:      Trip
    let viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss

    // Live location — same data flow as dashboard
    @State private var liveVehicleLocations: [VehicleLocation] = []
    @State private var driverCoordinate:     CLLocationCoordinate2D?
    @State private var lastLocationUpdate:   Date?

    // Geocoded coords for distance calculations
    @State private var pickupCoord:  CLLocationCoordinate2D?
    @State private var dropoffCoord: CLLocationCoordinate2D?

    // Road distances (MKDirections) + ETAs — cached to avoid Apple Maps throttle
    @State private var roadDistToPickupKm:  Double?
    @State private var roadDistToDropoffKm: Double?
    @State private var etaToPickupMin:      Int?
    @State private var etaToDropoffMin:     Int?
    /// Last driver position when MKDirections was called — skip recalc if moved < 500 m
    @State private var lastCalcCoord: CLLocationCoordinate2D?

    // Geofence events
    @State private var geofenceEvents: [TripGeofenceEvent] = []

    // MARK: - Computed

    var currentTrip: Trip { viewModel.trips.first(where: { $0.id == trip.id }) ?? trip }
    var route: Route?     { viewModel.route(for: currentTrip.routeId) }
    var driverName: String { viewModel.driverName(for: currentTrip.driverId) }
    var vehicleInfo: String { viewModel.vehicleName(for: currentTrip.vehicleId) }
    var isActive: Bool    { currentTrip.status == .active }

    var driver: Profile? {
        guard let id = currentTrip.driverId else { return nil }
        return viewModel.profiles.first(where: { $0.id == id })
    }

    var tripPhase: TripPhase {
        switch currentTrip.status {
        case .completed: return .completed
        case .cancelled: return .cancelled
        case .scheduled: return .scheduled
        case .active:    break
        default:         return .scheduled
        }

        guard let dp = roadDistToPickupKm, let dd = roadDistToDropoffKm else {
            return .enRouteToPickup   // locating
        }

        // Driver is closer to dropoff → has passed pickup
        if dd < dp {
            if dd <= 0.5 { return .atDropoff }
            if dd <= 5.0 { return .nearDropoff }
            return .enRouteToDropoff
        }

        // Still heading to pickup
        if dp <= 0.5 { return .atPickup }
        if dp <= 5.0 { return .nearPickup }
        return .enRouteToPickup
    }

    // MARK: - Body

    var body: some View {
        List {

            // ── Live Map ──────────────────────────────────────────
            Section {
                DashboardMapView(
                    activeTrips:      [currentTrip],
                    routes:           viewModel.routes,
                    profiles:         viewModel.profiles,
                    vehicleLocations: liveVehicleLocations
                )
                .frame(height: 260)
                .listRowInsets(EdgeInsets())
            } header: {
                HStack {
                    Text("Live Tracking")
                    Spacer()
                    if isActive {
                        HStack(spacing: 5) {
                            Circle().fill(Color.green).frame(width: 7, height: 7)
                            Text(lastLocationUpdate.map { timeAgo($0) } ?? "Awaiting GPS")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // ── Trip Phase / Driver Status ─────────────────────────
            if isActive {
                Section("Driver Status") {
                    // Phase banner
                    HStack(spacing: 12) {
                        Image(systemName: tripPhase.icon)
                            .font(.title3)
                            .foregroundStyle(tripPhase.color)
                            .frame(width: 36, height: 36)
                            .background(tripPhase.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(tripPhase.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(tripPhase.color)
                        Spacer()
                        if driverCoordinate == nil {
                            ProgressView().scaleEffect(0.8)
                        }
                    }

                    // Distance to pickup (road distance)
                    if let d = roadDistToPickupKm {
                        HStack {
                            Label("Pickup", systemImage: "circle.fill")
                                .foregroundStyle(Color.green)
                                .font(.subheadline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatDist(d))
                                    .font(.subheadline.weight(.semibold))
                                if let eta = etaToPickupMin {
                                    Text("~\(eta) min via road")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Distance to dropoff (road distance)
                    if let d = roadDistToDropoffKm {
                        HStack {
                            Label("Drop-off", systemImage: "mappin.circle.fill")
                                .foregroundStyle(Color.red)
                                .font(.subheadline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatDist(d))
                                    .font(.subheadline.weight(.semibold))
                                if let eta = etaToDropoffMin {
                                    Text("~\(eta) min via road")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // ── Order Info ────────────────────────────────────────
            Section("Order") {
                LabeledContent("Order ID",
                               value: "#\(currentTrip.id.uuidString.prefix(8).uppercased())")
                LabeledContent("Type",
                               value: currentTrip.orderType?.displayName ?? "—")
                HStack {
                    Text("Status")
                    Spacer()
                    StatusBadge(text: currentTrip.status?.rawValue.capitalized ?? "—",
                                color: viewModel.getStatusColor(for: currentTrip.status))
                }
                if let start = currentTrip.startTime {
                    LabeledContent("Started",
                                   value: start.formatted(date: .abbreviated, time: .shortened))
                }
                if let end = currentTrip.endTime {
                    LabeledContent("Ended",
                                   value: end.formatted(date: .abbreviated, time: .shortened))
                }
                if let dist = currentTrip.distance, dist > 0 {
                    LabeledContent("Distance travelled",
                                   value: String(format: "%.1f km", dist))
                }
            }

            // ── Route ─────────────────────────────────────────────
            Section("Route") {
                HStack(spacing: 14) {
                    Circle().fill(Color.green).frame(width: 10, height: 10).padding(.leading, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup").font(.caption).foregroundStyle(.secondary)
                        Text(route?.startLocation ?? "—").font(.subheadline)
                    }
                }
                HStack(spacing: 14) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14)).foregroundStyle(.red).frame(width: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drop-off").font(.caption).foregroundStyle(.secondary)
                        Text(route?.endLocation ?? "—").font(.subheadline)
                    }
                }
            }

            // ── Driver ────────────────────────────────────────────
            Section("Driver") {
                LabeledContent("Name", value: driverName)
                if let lic = driver?.licenseNumber, !lic.isEmpty {
                    LabeledContent("Licence", value: lic)
                }
                if let phone = driver?.phone {
                    LabeledContent("Phone", value: phone)
                }
            }

            // ── Vehicle ───────────────────────────────────────────
            Section("Vehicle") {
                LabeledContent("Vehicle", value: vehicleInfo)
                if let type = viewModel.vehicles.first(where: { $0.id == currentTrip.vehicleId })?.vehicleType {
                    LabeledContent("Type", value: type.displayName)
                }
            }

            // ── Zone Events ───────────────────────────────────────
            if !geofenceEvents.isEmpty {
                Section("Zone Events") {
                    ForEach(geofenceEvents) { event in
                        HStack(spacing: 10) {
                            Image(systemName: event.eventType == "entered"
                                  ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(event.eventType == "entered" ? Color.green : Color.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.eventType == "entered" ? "Arrived at zone" : "Departed zone")
                                    .font(.subheadline)
                                if let t = event.occurredAt {
                                    Text(t.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        Task {
                            try? await viewModel.deleteTrip(currentTrip)
                            await MainActor.run { dismiss() }
                        }
                    } label: {
                        Label("Delete Order", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .refreshable { await refreshAll() }
        .task {
            await geocodeRoute()
            await refreshAll()
            if isActive { startLiveUpdates() }
        }
        .onAppear {
            guard isActive else { return }
            RealtimeManager.shared.addVehicleLocationsChangeHandler {
                Task { @MainActor in
                    await refreshDriverLocation()
                    await calculateDistances()
                }
            }
        }
    }

    // MARK: - Data

    private func refreshDriverLocation() async {
        do {
            let locs = try await VehicleLocationService.fetchLatestLocations(for: [currentTrip.vehicleId])
            liveVehicleLocations = locs
            if let loc = locs.first, let lat = loc.latitude, let lon = loc.longitude {
                driverCoordinate   = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                lastLocationUpdate = Date()
            }
        } catch {
            print("[OrderDetail] location fetch error: \(error)")
        }
    }

    private func geocodeRoute() async {
        guard let start = route?.startLocation, let end = route?.endLocation else { return }
        async let src = geocode(start)
        async let dst = geocode(end)
        pickupCoord  = await src?.placemark.coordinate
        dropoffCoord = await dst?.placemark.coordinate
    }

    /// Calculates ROAD distances via MKDirections.
    /// Skips the call if driver hasn't moved more than 500 m since last calculation
    /// — prevents Apple Maps throttling (max 50 requests / 60 s).
    private func calculateDistances() async {
        guard let driver = driverCoordinate else { return }

        // Skip if driver moved < 500 m (saves ~90% of MKDirections calls)
        if let last = lastCalcCoord {
            let moved = CLLocation(latitude: driver.latitude, longitude: driver.longitude)
                .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
            guard moved > 500 else { return }
        }
        lastCalcCoord = driver

        if let pc = pickupCoord,
           let r = await roadDistance(from: driver, to: pc) {
            roadDistToPickupKm = r.distanceKm
            etaToPickupMin     = r.etaMin
        }
        if let dc = dropoffCoord,
           let r = await roadDistance(from: driver, to: dc) {
            roadDistToDropoffKm = r.distanceKm
            etaToDropoffMin     = r.etaMin
        }
    }

    private func refreshAll() async {
        await refreshDriverLocation()
        await calculateDistances()
        let events = (try? await GeofenceService.fetchEvents(forVehicle: currentTrip.vehicleId)) ?? []
        geofenceEvents = Array(events.prefix(10))
    }

    private func startLiveUpdates() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await refreshDriverLocation()
                await calculateDistances()
            }
        }
    }

    // MARK: - Helpers

    private struct RouteResult {
        let distanceKm: Double
        let etaMin: Int
    }

    private func roadDistance(from: CLLocationCoordinate2D,
                              to: CLLocationCoordinate2D) async -> RouteResult? {
        let req = MKDirections.Request()
        req.source          = MKMapItem(placemark: MKPlacemark(coordinate: from))
        req.destination     = MKMapItem(placemark: MKPlacemark(coordinate: to))
        req.transportType   = .automobile
        req.departureDate   = Date()
        guard let resp  = try? await MKDirections(request: req).calculate(),
              let route = resp.routes.first else { return nil }
        return RouteResult(
            distanceKm: route.distance / 1000.0,
            etaMin: Int(route.expectedTravelTime / 60)
        )
    }

    private func geocode(_ address: String) async -> MKMapItem? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address
        req.resultTypes = .address
        return try? await MKLocalSearch(request: req).start().mapItems.first
    }

    private func formatDist(_ km: Double) -> String {
        if km < 1 { return "\(Int(km * 1000)) m" }
        return String(format: "%.1f km", km)
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60   { return "Updated \(s)s ago" }
        if s < 3600 { return "Updated \(s/60)m ago" }
        return "Updated \(s/3600)h ago"
    }
}

// MARK: - Row Helpers

struct OrderDetailInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = Color.primary

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(.tertiaryLabel))
                .frame(width: 24)
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        OrderDetailView(
            trip: Trip(id: UUID(), vehicleId: UUID(), driverId: UUID(), routeId: UUID(),
                       startTime: Date(), endTime: nil, distance: nil,
                       status: .active, orderType: .pickUpAndDrop),
            viewModel: OrdersViewModel()
        )
    }
}
