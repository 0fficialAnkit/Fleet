import SwiftUI
import MapKit

struct OrderDetailView: View {

    let trip: Trip
    let viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss

    // Live driver location
    @State private var driverCoordinate: CLLocationCoordinate2D?
    @State private var lastLocationUpdate: Date?

    // Route path
    @State private var polyline: MKPolyline?
    @State private var pickupCoord:  CLLocationCoordinate2D?
    @State private var dropoffCoord: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Proximity & ETA
    @State private var distanceToPickupKm:  Double?
    @State private var distanceToDropoffKm: Double?
    @State private var etaToPickupMin:  Int?
    @State private var etaToDropoffMin: Int?

    // Geofence events for this trip
    @State private var geofenceEvents: [TripGeofenceEvent] = []

    // Live pulse indicator state
    @State private var isPulsing = false

    var currentTrip: Trip {
        viewModel.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    var route: Route?        { viewModel.route(for: currentTrip.routeId) }
    var driverName: String   { viewModel.driverName(for: currentTrip.driverId) }
    var vehicleInfo: String  { viewModel.vehicleName(for: currentTrip.vehicleId) }
    var isActive: Bool       { currentTrip.status == .active }

    // Geofence radius in km (must match GeofenceMonitor)
    private let geofenceRadiusKm: Double = 5.0

    // Resolve details
    var vehicle: Vehicle? {
        viewModel.vehicles.first(where: { $0.id == currentTrip.vehicleId })
    }
    
    var driver: Profile? {
        guard let driverId = currentTrip.driverId else { return nil }
        return viewModel.profiles.first(where: { $0.id == driverId })
    }

    var vehicleIcon: String {
        guard let type = vehicle?.vehicleType else { return "car.fill" }
        switch type {
        case .twoWheeler: return "scooter"
        case .threeWheeler: return "car.2.fill"
        case .car: return "car.fill"
        case .truck: return "box.truck.fill"
        }
    }

    // Driver status derived from distances
    var proximityStatus: (label: String, color: Color, icon: String) {
        guard isActive else {
            return (currentTrip.status?.rawValue.capitalized ?? "Unknown", .secondary, "checkmark.circle")
        }
        guard let dp = distanceToPickupKm else {
            return ("Locating driver…", .secondary, "location.circle")
        }
        if dp <= geofenceRadiusKm {
            return ("Driver is at pickup zone", .green,  "mappin.circle.fill")
        }
        if let dd = distanceToDropoffKm, dd <= geofenceRadiusKm {
            return ("Driver is at drop-off zone", .teal, "flag.checkered.circle.fill")
        }
        if dp < 20 {
            return ("Approaching pickup (\(String(format: "%.1f", dp)) km away)", .orange, "location.fill")
        }
        return ("En route to pickup", .blue, "road.lanes")
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Live Map Header ─────────────────────────────────────
            liveMapView
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 8)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

            ScrollView {
                VStack(spacing: 16) {
                    
                    // ── Live Tracking Status ──────────────────────────────
                    HStack {
                        Label("Live Tracking", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if isActive {
                            HStack(spacing: 6) {
                                Circle().fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(isPulsing ? 1.2 : 0.8)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
                                Text(lastLocationUpdate.map { "Updated \(timeAgo($0))" } ?? "Awaiting GPS")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    // ── Proximity & Delivery Progress Card ─────────────────
                    statusProgressCard

                    // ── Route Connected Timeline Section ───────────────────
                    if let start = route?.startLocation, let end = route?.endLocation {
                        DetailCard(title: "Route Details", icon: "map.fill", iconColor: .green) {
                            RouteTimelineView(
                                startLocation: start,
                                endLocation: end,
                                distanceToPickup: distanceToPickupKm,
                                etaToPickup: etaToPickupMin,
                                distanceToDropoff: distanceToDropoffKm,
                                etaToDropoff: etaToDropoffMin,
                                isActive: isActive
                            )
                        }
                    }

                    // ── Order Specifications Card ──────────────────────────
                    DetailCard(title: "Order Details", icon: "doc.text.fill", iconColor: .blue) {
                        VStack(spacing: 12) {
                            rowItem(label: "Order ID", value: "#\(currentTrip.id.uuidString.prefix(8).uppercased())", isMonospaced: true)
                            Divider()
                            rowItem(label: "Type", value: currentTrip.orderType?.displayName ?? "—")
                            Divider()
                            HStack {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                StatusBadge(text: currentTrip.status?.rawValue.capitalized ?? "Unknown",
                                            color: viewModel.getStatusColor(for: currentTrip.status))
                            }
                            if let start = currentTrip.startTime {
                                Divider()
                                rowItem(label: "Scheduled Start", value: start.formatted(date: .abbreviated, time: .shortened))
                            }
                            if let end = currentTrip.endTime {
                                Divider()
                                rowItem(label: "Finished End", value: end.formatted(date: .abbreviated, time: .shortened))
                            }
                            if let dist = currentTrip.distance {
                                Divider()
                                rowItem(label: "Trip Distance", value: String(format: "%.1f km", dist))
                            }
                        }
                    }

                    // ── Assignment Card ────────────────────────────────────
                    DetailCard(title: "Assignment Info", icon: "person.2.fill", iconColor: .teal) {
                        VStack(spacing: 16) {
                            // Driver info with contact link
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.teal.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "person.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.teal)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(driverName)
                                        .font(.body.weight(.semibold))
                                    if let phone = driver?.phone {
                                        Text(phone)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("No phone registered")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if let phone = driver?.phone, let url = URL(string: "tel://\(phone)") {
                                    Link(destination: url) {
                                        Image(systemName: "phone.fill")
                                            .foregroundStyle(.white)
                                            .padding(10)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Vehicle info with license plate
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.indigo.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: vehicleIcon)
                                        .font(.title3)
                                        .foregroundStyle(Color.indigo)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vehicleInfo)
                                        .font(.body.weight(.semibold))
                                    if let plate = vehicle?.licensePlate {
                                        Text(plate)
                                            .font(.system(.footnote, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if let status = vehicle?.status {
                                    Text(status.rawValue.capitalized)
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(status == .active ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                                        .foregroundStyle(status == .active ? Color.green : Color.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // ── Geofence Zone Events Card ──────────────────────────
                    if !geofenceEvents.isEmpty {
                        DetailCard(title: "Zone Events", icon: "location.circle.fill", iconColor: .orange) {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(geofenceEvents) { event in
                                    HStack(alignment: .top, spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(event.eventType == "entered" ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                                                .frame(width: 28, height: 28)
                                            Image(systemName: event.eventType == "entered" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                                .font(.footnote)
                                                .foregroundStyle(event.eventType == "entered" ? Color.green : Color.orange)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.eventType == "entered" ? "Arrived at zone" : "Departed zone")
                                                .font(.subheadline.weight(.semibold))
                                            if let t = event.occurredAt {
                                                Text(t.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
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
        .refreshable {
            await refreshAll()
        }
        .task {
            isPulsing = true
            viewModel.setupRealtime()
            await buildRoute()
            await refreshAll()

            if isActive {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    await refreshDriverLocation()
                    await calculateProximity()
                    await loadGeofenceEvents()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SupabaseTableDidChange_vehicle_locations"))) { _ in
            Task {
                await refreshDriverLocation()
                await calculateProximity()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SupabaseTableDidChange_trips"))) { _ in
            Task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Status & Progress View Panel

    private var statusProgressCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Status icon / badge
                Image(systemName: proximityStatus.icon)
                    .font(.title3)
                    .foregroundStyle(proximityStatus.color)
                    .frame(width: 36, height: 36)
                    .background(proximityStatus.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(proximityStatus.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(proximityStatus.color)
                    
                    if isActive, let dp = distanceToPickupKm {
                        Text(dp <= geofenceRadiusKm ? "Inside pickup zone" : "\(String(format: "%.1f km", dp - geofenceRadiusKm)) to enter zone")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            StepProgressView(currentStatus: currentTrip.status)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Row Helpers

    private func rowItem(label: String, value: String, isMonospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(isMonospaced ? .system(.subheadline, design: .monospaced) : .subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Live Map

    private var liveMapView: some View {
        Map(position: $cameraPosition) {

            // Route polyline
            if let poly = polyline {
                MapPolyline(poly)
                    .stroke(Color.blue.opacity(0.85),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            // Pickup pin
            if let coord = pickupCoord {
                Annotation("Pickup", coordinate: coord, anchor: .bottom) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 32, height: 32)
                                .shadow(radius: 4)
                            Circle()
                                .fill(Color.green)
                                .frame(width: 26, height: 26)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("Pickup")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(radius: 1)
                    }
                }
            }

            // Dropoff pin
            if let coord = dropoffCoord {
                Annotation("Drop-off", coordinate: coord, anchor: .bottom) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 32, height: 32)
                                .shadow(radius: 4)
                            Circle()
                                .fill(Color.red)
                                .frame(width: 26, height: 26)
                            Image(systemName: "mappin")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("Dropoff")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(radius: 1)
                    }
                }
            }

            // Live driver truck pin
            if let coord = driverCoordinate {
                Annotation(driverName, coordinate: coord, anchor: .center) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 38, height: 38)
                                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                            Circle()
                                .fill(Color.teal)
                                .frame(width: 32, height: 32)
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text(driverName)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.regularMaterial)
                            .clipShape(Capsule())
                            .shadow(radius: 1)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls { MapCompass(); MapScaleView() }
    }

    // MARK: - Data Loading

    private func buildRoute() async {
        guard let start = route?.startLocation, let end = route?.endLocation else { return }

        async let srcSearch = geocode(start)
        async let dstSearch = geocode(end)
        guard let src = await srcSearch, let dst = await dstSearch else { return }

        pickupCoord  = src.placemark.coordinate
        dropoffCoord = dst.placemark.coordinate

        // MKDirections for polyline
        let req = MKDirections.Request()
        req.source = src; req.destination = dst
        req.transportType = .automobile
        if let resp = try? await MKDirections(request: req).calculate(),
           let mkRoute = resp.routes.first {
            polyline = mkRoute.polyline
        } else {
            // Straight-line fallback
            var coords = [src.placemark.coordinate, dst.placemark.coordinate]
            polyline = MKPolyline(coordinates: &coords, count: 2)
        }

        fitCamera()
    }

    private func refreshDriverLocation() async {
        guard let loc = try? await VehicleLocationService
            .fetchLatestLocations(for: [currentTrip.vehicleId]).first,
              let lat = loc.latitude, let lon = loc.longitude else { return }

        driverCoordinate  = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        lastLocationUpdate = Date()
        fitCamera()
    }

    private func loadGeofenceEvents() async {
        let events = (try? await GeofenceService.fetchEvents(forVehicle: currentTrip.vehicleId)) ?? []
        geofenceEvents = Array(events.prefix(10))
    }

    private func refreshAll() async {
        await refreshDriverLocation()
        await calculateProximity()
        await loadGeofenceEvents()
    }

    // MARK: - Proximity & ETA

    private func calculateProximity() async {
        guard let driver = driverCoordinate else { return }
        let driverLoc = CLLocation(latitude: driver.latitude, longitude: driver.longitude)

        // Straight-line distances
        if let pc = pickupCoord {
            let pickupLoc = CLLocation(latitude: pc.latitude, longitude: pc.longitude)
            distanceToPickupKm = driverLoc.distance(from: pickupLoc) / 1000.0
        }
        if let dc = dropoffCoord {
            let dropoffLoc = CLLocation(latitude: dc.latitude, longitude: dc.longitude)
            distanceToDropoffKm = driverLoc.distance(from: dropoffLoc) / 1000.0
        }

        // ETA via MKDirections (driving, live traffic)
        if let pc = pickupCoord {
            etaToPickupMin = await fetchETA(from: driver, to: pc)
        }
        if let dc = dropoffCoord {
            etaToDropoffMin = await fetchETA(from: driver, to: dc)
        }
    }

    private func fetchETA(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> Int? {
        let srcItem = MKMapItem(placemark: MKPlacemark(coordinate: from))
        let dstItem = MKMapItem(placemark: MKPlacemark(coordinate: to))
        let req = MKDirections.Request()
        req.source = srcItem; req.destination = dstItem
        req.transportType = .automobile
        req.departureDate = Date()
        guard let resp = try? await MKDirections(request: req).calculate(),
              let route = resp.routes.first else { return nil }
        return Int(route.expectedTravelTime / 60)
    }

    // MARK: - Camera

    private func fitCamera() {
        var coords: [CLLocationCoordinate2D] = []
        if let poly = polyline {
            let pts = poly.points()
            coords = (0..<poly.pointCount).map { pts[$0].coordinate }
        }
        if let d = driverCoordinate { coords.append(d) }
        guard !coords.isEmpty else { return }

        var minLat =  90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0
        for c in coords {
            minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat+maxLat)/2, longitude: (minLon+maxLon)/2),
            span:   MKCoordinateSpan(
                latitudeDelta:  max(maxLat - minLat, 0.02) * 1.4,
                longitudeDelta: max(maxLon - minLon, 0.02) * 1.4)
        ))
    }

    // MARK: - Helpers

    private func geocode(_ address: String) async -> MKMapItem? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address
        req.resultTypes = .address
        return try? await MKLocalSearch(request: req).start().mapItems.first
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(Date().timeIntervalSince(date))
        if s < 60  { return "\(s)s ago" }
        if s < 3600 { return "\(s/60)m ago" }
        return "\(s/3600)h ago"
    }
}

// MARK: - Subviews & Subcomponents

struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.015), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct StepProgressView: View {
    let currentStatus: TripStatus?

    var body: some View {
        HStack {
            stepItem(title: "Scheduled", isCompleted: isStepCompleted(step: .scheduled), isActive: currentStatus == .scheduled, color: .blue)
            progressLine(isCompleted: isStepCompleted(step: .active))
            stepItem(title: "Active", isCompleted: isStepCompleted(step: .active), isActive: currentStatus == .active, color: .green)
            progressLine(isCompleted: isStepCompleted(step: .completed))
            stepItem(title: "Completed", isCompleted: isStepCompleted(step: .completed), isActive: currentStatus == .completed, color: .green)
        }
        .padding(.vertical, 8)
    }

    private func isStepCompleted(step: TripStatus) -> Bool {
        guard let current = currentStatus else { return false }
        switch (current, step) {
        case (.completed, _):
            return true
        case (.active, .scheduled), (.active, .active):
            return true
        case (.scheduled, .scheduled):
            return true
        default:
            return false
        }
    }

    private func stepItem(title: String, isCompleted: Bool, isActive: Bool, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(isCompleted || isActive ? color : Color(.systemGray4), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(isCompleted ? color : Color(.secondarySystemGroupedBackground)))

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else if isActive {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }
            }

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func progressLine(isCompleted: Bool) -> some View {
        Rectangle()
            .fill(isCompleted ? Color.green : Color(.systemGray4))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16) // align with circles
    }
}

struct RouteTimelineView: View {
    let startLocation: String
    let endLocation: String
    let distanceToPickup: Double?
    let etaToPickup: Int?
    let distanceToDropoff: Double?
    let etaToDropoff: Int?
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pickup Row
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)

                    // Vertical line connecting to Dropoff
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 2, height: 44)
                }
                .frame(width: 12)
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pickup Address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        Spacer()
                        if isActive, let dist = distanceToPickup {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 8))
                                Text(dist < 1 ? "\(Int(dist * 1000)) m" : String(format: "%.1f km", dist))
                                if let eta = etaToPickup {
                                    Text("· \(eta) min")
                                }
                            }
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(Color.green)
                            .clipShape(Capsule())
                        }
                    }
                    Text(startLocation)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }

            // Dropoff Row
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.red)
                        .frame(width: 14)
                }
                .frame(width: 12)
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Drop-off Address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        Spacer()
                        if isActive, let dist = distanceToDropoff {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 8))
                                Text(dist < 1 ? "\(Int(dist * 1000)) m" : String(format: "%.1f km", dist))
                                if let eta = etaToDropoff {
                                    Text("· \(eta) min")
                                }
                            }
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(Color.red)
                            .clipShape(Capsule())
                        }
                    }
                    Text(endLocation)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }
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
