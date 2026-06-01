import SwiftUI
import MapKit

struct TripDetailView: View {

    let trip: Trip
    let onStart: (UUID, UUID, String, [String]) -> Void
    let onEnd:   (UUID, UUID, String, [String]) -> Void

    @State private var currentStatus: TripStatus?
    @State private var showingChecklist: InspectionType? = nil
    @State private var showingTripIssue = false

    @State private var route: Route?
    @State private var vehicle: Vehicle?
    @State private var estimatedDistance: Double?

    @Environment(AuthViewModel.self) private var authViewModel

    init(trip: Trip,
         onStart: @escaping (UUID, UUID, String, [String]) -> Void,
         onEnd:   @escaping (UUID, UUID, String, [String]) -> Void) {
        self.trip    = trip
        self.onStart = onStart
        self.onEnd   = onEnd
        self._currentStatus = State(initialValue: trip.status)
    }

    // MARK: - Helpers

    var statusColor: Color {
        switch currentStatus {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return .green
        case .cancelled: return .red
        default:         return Color(.quaternaryLabel)
        }
    }

    var statusLabel: String {
        switch currentStatus {
        case .scheduled: return "Scheduled"
        case .active:    return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        default:         return "Unknown"
        }
    }

    var distanceText: String {
        if let d = trip.distance, d > 0 { return String(format: "%.1f km", d) }
        if let d = estimatedDistance     { return String(format: "≈ %.1f km", d) }
        return "Calculating…"
    }

    var tripDuration: String? {
        guard let s = trip.startTime, let e = trip.endTime else { return nil }
        let mins = Int(e.timeIntervalSince(s) / 60)
        return mins >= 60 ? "\(mins/60)h \(mins%60)m" : "\(mins) min"
    }

    // MARK: - Body

    var body: some View {
        List {

            // ── Identity ──────────────────────────────────────────
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(statusColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.orderType?.displayName ?? "Trip")
                            .font(.headline)
                        Text("ID \(trip.id.uuidString.prefix(8).uppercased())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontDesign(.monospaced)
                    }

                    Spacer()

                    Text(statusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            }

            // ── Trip Info ─────────────────────────────────────────
            Section("Trip Info") {
                if let date = trip.startTime {
                    LabeledContent("Date") {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                    }
                    LabeledContent("Start Time") {
                        Text(date.formatted(date: .omitted, time: .shortened))
                    }
                }
                if let end = trip.endTime {
                    LabeledContent("End Time") {
                        Text(end.formatted(date: .omitted, time: .shortened))
                    }
                }
                if let dur = tripDuration {
                    LabeledContent("Duration") { Text(dur) }
                }
                LabeledContent("Distance") { Text(distanceText) }
            }

            // ── Route ─────────────────────────────────────────────
            Section("Route") {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .padding(.leading, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(route?.startLocation ?? "—")
                            .font(.subheadline)
                    }
                }

                HStack(spacing: 14) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .frame(width: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drop-off")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(route?.endLocation ?? "—")
                            .font(.subheadline)
                    }
                }
            }

            // ── Map ───────────────────────────────────────────────
            Section {
                TripRouteMapView(
                    startAddress: route?.startLocation,
                    endAddress:   route?.endLocation
                )
                .frame(height: 230)
                .listRowInsets(EdgeInsets())
            } header: {
                Text("Route Map")
            }

            // ── Vehicle ───────────────────────────────────────────
            Section("Vehicle") {
                if let v = vehicle {
                    HStack(spacing: 14) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(v.make ?? "") \(v.model ?? "")")
                                .font(.body.weight(.medium))
                            Text(v.licensePlate ?? "—")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)

                    NavigationLink {
                        DriverVehicleDetailView(vehicle: v)
                    } label: {
                        Label("View Vehicle Details", systemImage: "info.circle")
                    }

                    NavigationLink {
                        DriverReportIssueView(vehicle: v)
                            .environment(authViewModel)
                    } label: {
                        Label("Report Vehicle Issue", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                } else {
                    HStack(spacing: 10) {
                        ProgressView().scaleEffect(0.85)
                        Text("Loading vehicle…").foregroundStyle(.secondary)
                    }
                }
            }

            // ── Actions ───────────────────────────────────────────
            actionSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let fetchedRoute   = trip.routeId != nil ? RouteService.fetchRoute(id: trip.routeId!) : nil
            async let fetchedVehicle = VehicleService.fetchVehicle(id: trip.vehicleId)
            route   = try? await fetchedRoute
            vehicle = try? await fetchedVehicle
            if let s = route?.startLocation, let e = route?.endLocation {
                await calculateDistance(from: s, to: e)
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
    private var actionSection: some View {
        switch currentStatus {

        case .scheduled:
            Section {
                Button {
                    showingChecklist = .preTrip
                } label: {
                    HStack {
                        Spacer()
                        Label("Start Trip", systemImage: "play.fill")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.green)
            }

        case .active:
            Section {
                Button {
                    showingTripIssue = true
                } label: {
                    Label("Report Delay / Issue", systemImage: "clock.badge.exclamationmark")
                        .foregroundStyle(.black)
                }
                .listRowBackground(Color.yellow)
            }

            Section {
                Button {
                    showingChecklist = .postTrip
                } label: {
                    HStack {
                        Spacer()
                        Label("End Trip", systemImage: "stop.fill")
                            .font(.body.bold())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.red)
            }

        case .completed:
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Trip completed successfully")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                }
                .listRowBackground(Color.green.opacity(0.08))
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Navigation helpers (logic unchanged)

    private func openMapsNavigation() {
        guard let s = route?.startLocation, !s.isEmpty,
              let e = route?.endLocation,   !e.isEmpty else { return }
        Task {
            async let src = geocode(s)
            async let dst = geocode(e)
            guard let si = await src, let di = await dst else { return }
            si.name = s; di.name = e
            MKMapItem.openMaps(with: [si, di], launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ])
        }
    }

    private func geocode(_ address: String) async -> MKMapItem? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address
        req.resultTypes = .address
        return try? await MKLocalSearch(request: req).start().mapItems.first
    }

    private func calculateDistance(from start: String, to end: String) async {
        guard let s = await geocode(start), let e = await geocode(end) else { return }
        let req = MKDirections.Request()
        req.source = s; req.destination = e; req.transportType = .automobile
        if let resp = try? await MKDirections(request: req).calculate(),
           let r = resp.routes.first {
            await MainActor.run { estimatedDistance = r.distance / 1000 }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TripDetailView(
            trip: Trip(
                id: UUID(), vehicleId: UUID(), driverId: UUID(), routeId: UUID(),
                startTime: Date(), endTime: nil, distance: nil,
                status: .active, orderType: .pickUpAndDrop
            ),
            onStart: { _, _, _, _ in },
            onEnd:   { _, _, _, _ in }
        )
    }
    .environment(AuthViewModel())
}
