import SwiftUI
import MapKit

enum TripPhase {
    case scheduled
    case enRouteToPickup
    case nearPickup
    case atPickup
    case enRouteToDropoff
    case nearDropoff
    case completed
    case cancelled
}

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

    // Geofence events and trip geofences
    @State private var geofenceEvents: [TripGeofenceEvent] = []
    @State private var tripGeofences: [TripGeofence] = []

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

    // Dynamic Trip Phase derived from active metrics and database events
    var tripPhase: TripPhase {
        guard let status = currentTrip.status else { return .scheduled }
        switch status {
        case .scheduled:
            return .scheduled
        case .cancelled:
            return .cancelled
        case .completed:
            return .completed
        case .active:
            // Check drop-off proximity
            if let dd = distanceToDropoffKm {
                if dd <= 0.1 {
                    return .completed
                }
                if dd <= geofenceRadiusKm {
                    return .nearDropoff
                }
            }
            
            // Check if we have entered the pickup geofence or are currently there
            let hasEnteredPickup = geofenceEvents.contains { event in
                let fence = tripGeofences.first { $0.id == event.geofenceId }
                return fence?.zoneType == "pickup" && event.eventType == "entered"
            }
            
            let hasExitedPickup = geofenceEvents.contains { event in
                let fence = tripGeofences.first { $0.id == event.geofenceId }
                return fence?.zoneType == "pickup" && event.eventType == "exited"
            }
            
            // Check pickup proximity
            if let dp = distanceToPickupKm {
                if dp <= 0.1 || (hasEnteredPickup && !hasExitedPickup && dp <= 1.0) {
                    return .atPickup
                }
                if dp <= geofenceRadiusKm {
                    return .nearPickup
                }
            }
            
            if hasExitedPickup {
                return .enRouteToDropoff
            }
            
            if let dp = distanceToPickupKm, let dd = distanceToDropoffKm, dd < dp {
                return .enRouteToDropoff
            }
            
            return .enRouteToPickup
        }
    }

    // Straight-line distance calculation between pickup and drop-off
    var routeDistanceKm: Double {
        guard let pc = pickupCoord, let dc = dropoffCoord else { return 5.0 }
        let loc1 = CLLocation(latitude: pc.latitude, longitude: pc.longitude)
        let loc2 = CLLocation(latitude: dc.latitude, longitude: dc.longitude)
        return loc1.distance(from: loc2) / 1000.0
    }

    // Capsule Journey Progress Double Value (0.0 to 1.0)
    var journeyProgress: Double {
        switch tripPhase {
        case .scheduled:
            return 0.0
        case .enRouteToPickup:
            let currentDist = distanceToPickupKm ?? 10.0
            let baseProgress = 0.5 * (1.0 - min(1.0, currentDist / 10.0))
            return max(0.05, min(0.45, baseProgress))
        case .nearPickup:
            return 0.45
        case .atPickup:
            return 0.5
        case .enRouteToDropoff:
            let totalDist = routeDistanceKm
            let remainingDist = distanceToDropoffKm ?? totalDist
            let routeProgress = 1.0 - min(1.0, max(0.0, remainingDist / max(totalDist, 0.1)))
            return 0.5 + 0.5 * routeProgress
        case .nearDropoff:
            return 0.95
        case .completed:
            return 1.0
        case .cancelled:
            return 0.0
        }
    }

    // Calculated Trip Duration Text
    var tripDurationText: String {
        guard let start = currentTrip.startTime else { return "—" }
        let end = currentTrip.endTime ?? Date()
        let diff = end.timeIntervalSince(start)
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    // Dynamic stats values for chips
    var completionText: String {
        switch tripPhase {
        case .scheduled:
            return "0%"
        case .enRouteToPickup, .nearPickup, .atPickup:
            let currentDist = distanceToPickupKm ?? 10.0
            let rawPct = Int((1.0 - min(1.0, currentDist / 10.0)) * 50)
            return "\(max(0, min(49, rawPct)))%"
        case .enRouteToDropoff, .nearDropoff:
            let totalDist = routeDistanceKm
            let remainingDist = distanceToDropoffKm ?? totalDist
            let routeProgress = 1.0 - min(1.0, max(0.0, remainingDist / max(totalDist, 0.1)))
            return "\(Int(50 + 50 * routeProgress))%"
        case .completed:
            return "100%"
        case .cancelled:
            return "0%"
        }
    }

    var remainingDistText: String {
        switch tripPhase {
        case .scheduled:
            return "—"
        case .enRouteToPickup, .nearPickup, .atPickup:
            if let d = distanceToPickupKm {
                return d < 1 ? "\(Int(d * 1000)) m" : String(format: "%.1f km", d)
            }
            return "Locating…"
        case .enRouteToDropoff, .nearDropoff:
            if let d = distanceToDropoffKm {
                return d < 1 ? "\(Int(d * 1000)) m" : String(format: "%.1f km", d)
            }
            return "Locating…"
        case .completed:
            return "0.0 km"
        case .cancelled:
            return "—"
        }
    }

    var coveredDistText: String {
        switch tripPhase {
        case .scheduled:
            return "0.0 km"
        case .enRouteToPickup, .nearPickup, .atPickup:
            if let dp = distanceToPickupKm {
                let covered = max(0.0, 10.0 - dp)
                return covered < 1 ? "\(Int(covered * 1000)) m" : String(format: "%.1f km", covered)
            }
            return "0.0 km"
        case .enRouteToDropoff, .nearDropoff:
            let total = routeDistanceKm
            if let dd = distanceToDropoffKm {
                let covered = max(0.0, total - dd)
                return covered < 1 ? "\(Int(covered * 1000)) m" : String(format: "%.1f km", covered)
            }
            return "0.0 km"
        case .completed:
            return String(format: "%.1f km", routeDistanceKm)
        case .cancelled:
            return "0.0 km"
        }
    }

    var etaText: String {
        switch tripPhase {
        case .scheduled:
            return "—"
        case .enRouteToPickup, .nearPickup, .atPickup:
            return etaToPickupMin.map { "\($0) min" } ?? "—"
        case .enRouteToDropoff, .nearDropoff:
            return etaToDropoffMin.map { "\($0) min" } ?? "—"
        case .completed:
            return "Arrived"
        case .cancelled:
            return "—"
        }
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
                    if tripPhase == .completed {
                        completedSuccessCard
                    } else {
                        statusProgressCard
                    }

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

    // MARK: - Redesigned Live Trip Progress Card (Uber/Samsara/Tesla Style)

    private var statusProgressCard: some View {
        VStack(spacing: 16) {
            // Milestone Header (Above Capsule)
            HStack {
                // Pickup details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(journeyProgress >= 0.5 ? Color.green : Color.blue)
                            .frame(width: 6, height: 6)
                        Text("PICKUP")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    Text(route?.startLocation ?? "Pickup Point")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Dynamic Status Banner Indicator
                if tripPhase == .nearPickup {
                    HStack(spacing: 6) {
                        PulsingDot(color: .green)
                        Text("Near Pickup")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                } else if tripPhase == .atPickup {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.green)
                        Text("Pickup Reached")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                } else if tripPhase == .nearDropoff {
                    HStack(spacing: 6) {
                        PulsingDot(color: .teal)
                        Text("Near Drop-off")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.teal)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: proximityStatus.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(proximityStatus.color)
                        Text(proximityStatus.label)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(proximityStatus.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(proximityStatus.color.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Drop-off details
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("DROP-OFF")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.red)
                    }
                    Text(route?.endLocation ?? "Drop-off Point")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            Divider()
            
            // Horizontal Journey Capsule Tracker
            JourneyCapsuleView(progress: journeyProgress, phase: tripPhase)
                .padding(.vertical, 4)
            
            Divider()
            
            // Statistics Grid (Below Capsule)
            HStack(spacing: 8) {
                statChip(title: "COMPLETED", value: completionText, icon: "percent", color: .blue)
                statChip(title: "REMAINING", value: remainingDistText, icon: "arrow.right.circle", color: .orange)
                statChip(title: "COVERED", value: coveredDistText, icon: "road.lanes", color: .green)
                statChip(title: "ETA", value: etaText, icon: "clock.fill", color: .teal)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Redesigned Mission Control Completed Success View

    private var completedSuccessCard: some View {
        VStack(spacing: 16) {
            // Success Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(Color.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trip Completed Successfully")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Driver reached destination safely.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Full Completed Capsule
            JourneyCapsuleView(progress: 1.0, phase: .completed)
            
            Divider()
            
            // Final stats chips
            HStack(spacing: 8) {
                statChip(title: "TOTAL DISTANCE", value: String(format: "%.1f km", routeDistanceKm), icon: "road.lanes", color: .green)
                statChip(title: "DURATION", value: tripDurationText, icon: "clock.fill", color: .blue)
                statChip(title: "STATUS", value: "Completed", icon: "checkmark.circle.fill", color: .teal)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
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

    private func statChip(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        let fences = (try? await GeofenceService.fetchGeofences(forTrip: currentTrip.id)) ?? []
        tripGeofences = fences

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

// MARK: - Custom Step/Journey Capsule Component

struct JourneyCapsuleView: View {
    let progress: Double // 0.0 to 1.0
    let phase: TripPhase

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progressWidth = max(0, min(width, width * CGFloat(progress)))
            
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                
                // Filled Track (Green)
                Capsule()
                    .fill(Color.green.gradient)
                    .frame(width: progressWidth, height: 14)
                
                // Milestones
                HStack(spacing: 0) {
                    // Milestone 1: Start
                    milestoneNode(icon: "car.fill", isCompleted: progress >= 0.0, label: "Start")
                    Spacer()
                    // Milestone 2: Pickup
                    milestoneNode(icon: "shippingbox.fill", isCompleted: progress >= 0.5, label: "Pickup")
                    Spacer()
                    // Milestone 3: Drop-off
                    milestoneNode(icon: "mappin.and.ellipse", isCompleted: progress >= 1.0, label: "Drop-off")
                }
                .padding(.horizontal, -10)
                
                // Live Vehicle Icon moving smoothly
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 30, height: 30)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.green)
                }
                .offset(x: max(0, min(width - 30, (width - 30) * CGFloat(progress))))
            }
            .frame(height: 30, alignment: .center)
        }
        .frame(height: 30)
    }

    private func milestoneNode(icon: String, isCompleted: Bool, label: String) -> some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Color.green : Color(.systemGray4))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )

            Image(systemName: isCompleted && label != "Drop-off" ? "checkmark" : icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Live Geofence Pulse Animation View

struct PulsingDot: View {
    @State private var animate = false
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 16, height: 16)
                .scaleEffect(animate ? 1.8 : 1.0)
                .opacity(animate ? 0.0 : 0.8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                animate = true
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
