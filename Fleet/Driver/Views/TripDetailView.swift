import SwiftUI
import MapKit

struct TripDetailView: View {

    let trip: Trip
    let onStart: (UUID, UUID, String, [String]) -> Void
    let onEnd: (UUID, UUID, String, [String]) -> Void

    @State private var currentStatus: TripStatus?
    @State private var showingChecklist: InspectionType? = nil
    @State private var showingTripIssue = false

    @State private var route: Route?
    @State private var vehicle: Vehicle?
    @State private var mapView: TripRouteMapView?
    @State private var estimatedDistance: Double?

    @Environment(AuthViewModel.self) private var authViewModel

    init(trip: Trip, onStart: @escaping (UUID, UUID, String, [String]) -> Void, onEnd: @escaping (UUID, UUID, String, [String]) -> Void) {
        self.trip = trip
        self.onStart = onStart
        self.onEnd = onEnd
        self._currentStatus = State(initialValue: trip.status)
    }

    // MARK: - Computed helpers

    var statusColor: Color {
        switch currentStatus {
        case .scheduled: return Color.blue
        case .active:    return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        default:         return Color(UIColor.quaternaryLabel)
        }
    }

    var statusText: String {
        switch currentStatus {
        case .scheduled: return "Pending"
        case .active:    return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        default:         return "Unknown"
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // ── Header ─────────────────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route #\(trip.id.uuidString.prefix(6).uppercased())")
                            .font(.title2.bold())
                            .foregroundStyle(Color.primary)
                        StatusBadge(text: statusText, color: statusColor)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: "truck.box.fill")
                            .font(.title2)
                            .foregroundStyle(Color.green)
                    }
                }

                Divider()

                // ── Schedule ────────────────────────────────────────
                sectionTitle("Schedule")

                HStack(spacing: 12) {
                    infoTile(icon: "calendar",    label: "Date",
                             value: trip.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "Today",
                             color: Color.purple)
                    infoTile(icon: "clock.fill",  label: "Start Time",
                             value: trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "09:00 AM",
                             color: Color.green)
                    infoTile(icon: "road.lanes",  label: "Distance",
                             value: trip.distance != nil
                                ? String(format: "%.1f km", trip.distance!)
                                : (estimatedDistance != nil ? String(format: "%.1f km", estimatedDistance!) : "Calculating..."),
                             color: Color.orange)
                }

                // ── Route Details ──────────────────────────────────
                sectionTitle("Route Details")

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.12)).frame(width: 38, height: 38)
                            Image(systemName: "circle.fill").font(.caption).foregroundStyle(Color.green)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pickup / Origin").font(.caption).foregroundStyle(Color.secondary)
                            Text(route?.startLocation ?? "No start location")
                                .font(.subheadline.weight(.medium)).foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }

                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(width: 2, height: 28)
                        .padding(.leading, 18)

                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.red.opacity(0.12)).frame(width: 38, height: 38)
                            Image(systemName: "mappin.circle.fill").font(.title3).foregroundStyle(Color.red)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Drop-off / Destination").font(.caption).foregroundStyle(Color.secondary)
                            Text(route?.endLocation ?? "No destination")
                                .font(.subheadline.weight(.medium)).foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // ── Assigned Vehicle ───────────────────────────────
                sectionTitle("Assigned Vehicle")

                if let vehicle {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            Image(systemName: "truck.box.fill")
                                .font(.title2).foregroundStyle(Color.green)
                                .frame(width: 42, height: 42)
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(vehicle.make ?? "Vehicle") \(vehicle.model ?? "")")
                                    .font(.headline).foregroundStyle(Color.primary)
                                Text(vehicle.licensePlate ?? "—")
                                    .font(.subheadline).foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }

                        Divider()

                        HStack(spacing: 12) {
                            NavigationLink(destination: DriverVehicleDetailView(vehicle: vehicle)) {
                                Label("View Details", systemImage: "info.circle")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.green)
                                    .padding(.vertical, 8).padding(.horizontal, 14)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: DriverReportIssueView(vehicle: vehicle)) {
                                Label("Report Issue", systemImage: "exclamationmark.triangle")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.red)
                                    .padding(.vertical, 8).padding(.horizontal, 14)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    HStack(spacing: 12) {
                        ProgressView().scaleEffect(0.8)
                        Text("Loading vehicle info…")
                            .font(.subheadline).foregroundStyle(Color.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // ── Route Map ─────────────────────────────────────
                sectionTitle("Route Map")

                TripRouteMapView(
                    startAddress: route?.startLocation,
                    endAddress:   route?.endLocation
                )

                // ── Action Buttons ─────────────────────────────────
                actionSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.large)
        .task {
            async let fetchedRoute   = trip.routeId != nil ? RouteService.fetchRoute(id: trip.routeId!) : nil
            async let fetchedVehicle = VehicleService.fetchVehicle(id: trip.vehicleId)
            route   = try? await fetchedRoute
            vehicle = try? await fetchedVehicle
            if let start = route?.startLocation, let end = route?.endLocation {
                await calculateDistance(from: start, to: end)
            }
        }
        .sheet(item: $showingChecklist) { type in
            DriverChecklistView(checklistType: type, vehicle: vehicle) { notes, urls in
                if type == .preTrip {
                    onStart(trip.id, trip.vehicleId, notes, urls)
                    withAnimation { currentStatus = .active }
                    openMapsNavigation()
                } else {
                    onEnd(trip.id, trip.vehicleId, notes, urls)
                    withAnimation { currentStatus = .completed }
                }
                showingChecklist = nil
            }
        }
        .sheet(isPresented: $showingTripIssue) {
            DriverTripIssueView(trip: trip)
                .environment(authViewModel)
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    var actionSection: some View {
        switch currentStatus {
        case .scheduled:
            Button { showingChecklist = .preTrip } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Trip").font(.headline)
                }
                .frame(maxWidth: .infinity).padding(16)
                .background(Color.green).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .shadow(color: Color.green.opacity(0.35), radius: 10, y: 4)

        case .active:
            VStack(spacing: 12) {
                // In-progress banner
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill").foregroundStyle(Color.green)
                    Text("Trip is currently in progress")
                        .font(.subheadline.weight(.medium)).foregroundStyle(Color.green)
                    Spacer()
                }
                .padding(14)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Report delay / issue
                Button { showingTripIssue = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.exclamationmark").font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Report Delay / Issue").font(.subheadline.weight(.semibold))
                            Text("Notify your fleet manager now").font(.caption).opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).opacity(0.7)
                    }
                    .foregroundStyle(.white).padding(14)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                // End trip
                Button { showingChecklist = .postTrip } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                        Text("End Trip").font(.headline)
                    }
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color.red).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .shadow(color: Color.red.opacity(0.35), radius: 10, y: 4)
            }

        case .completed:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
                Text("Trip completed successfully")
                    .font(.subheadline.weight(.medium)).foregroundStyle(Color.green)
                Spacer()
            }
            .padding(14)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        default:
            EmptyView()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    func sectionTitle(_ text: String) -> some View {
        Text(text).font(.headline).foregroundStyle(Color.primary)
    }

    // MARK: - Apple Maps Navigation

    private func openMapsNavigation() {
        guard let startAddr = route?.startLocation, !startAddr.isEmpty,
              let endAddr   = route?.endLocation,   !endAddr.isEmpty else { return }
        Task {
            async let sourceResult = geocodeAddress(startAddr)
            async let destResult   = geocodeAddress(endAddr)
            guard let sourceItem = await sourceResult, let destItem = await destResult else { return }
            sourceItem.name = startAddr; destItem.name = endAddr
            MKMapItem.openMaps(with: [sourceItem, destItem], launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ])
        }
    }

    private func geocodeAddress(_ address: String) async -> MKMapItem? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address; req.resultTypes = .address
        return try? await MKLocalSearch(request: req).start().mapItems.first
    }

    private func calculateDistance(from startAddr: String, to endAddr: String) async {
        guard let startItem = await geocodeAddress(startAddr),
              let endItem   = await geocodeAddress(endAddr) else { return }
        let request = MKDirections.Request()
        request.source = startItem; request.destination = endItem
        request.transportType = .automobile
        if let response = try? await MKDirections(request: request).calculate(),
           let route = response.routes.first {
            await MainActor.run { self.estimatedDistance = route.distance / 1000.0 }
        }
    }

    @ViewBuilder
    func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(Color.secondary)
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(Color.primary)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TripDetailView(
            trip: Trip(id: UUID(), vehicleId: UUID(), driverId: UUID(), routeId: UUID(),
                       startTime: Date(), endTime: nil, distance: nil, status: .scheduled, orderType: .pickUpAndDrop),
            onStart: { _, _, _, _ in },
            onEnd:   { _, _, _, _ in }
        )
    }
    .environment(AuthViewModel())
}
