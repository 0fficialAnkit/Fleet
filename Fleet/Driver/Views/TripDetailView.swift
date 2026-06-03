import SwiftUI
import MapKit

struct TripDetailView: View {

    let trip:         Trip
    let onStart:      (UUID, UUID, String, [String]) -> Void
    let onEnd:        (UUID, UUID, Double?, String, [String]) -> Void
    var onPickupDone: ((UUID, UUID) -> Void)? = nil

    @State private var currentStatus:    TripStatus?
    @State private var showingChecklist: InspectionType? = nil
    @State private var pickupCompleted  = false
    @State private var dropoffCompleted = false

    @State private var route:             Route?
    @State private var vehicle:           Vehicle?
    @State private var estimatedDistance: Double?
    @State private var incidents:         [TripIncident] = []

    init(trip: Trip,
         onStart:      @escaping (UUID, UUID, String, [String]) -> Void,
         onEnd:        @escaping (UUID, UUID, Double?, String, [String]) -> Void,
         onPickupDone: ((UUID, UUID) -> Void)? = nil) {
        self.trip         = trip
        self.onStart      = onStart
        self.onEnd        = onEnd
        self.onPickupDone = onPickupDone
        self._currentStatus = State(initialValue: trip.status)
    }

    // MARK: - Computed

    var isScheduled: Bool { currentStatus == .scheduled }
    var isActive:    Bool { currentStatus == .active    }
    var isCompleted: Bool { currentStatus == .completed }

    var distanceText: String {
        if let d = trip.distance     { return String(format: "%.1f km", d) }
        if let d = estimatedDistance { return String(format: "%.1f km", d) }
        return "Calculating…"
    }

    // MARK: - Body

    var body: some View {
        List {

            // ── 1. Map ────────────────────────────────────────────────────
            Section {
                TripRouteMapView(
                    startAddress: route?.startLocation,
                    endAddress:   route?.endLocation
                )
                .frame(height: 200)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }

            // ── 3. Active trip status banner ──────────────────────────────
            if isActive {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dropoffCompleted ? "Ready to End Trip"
                                 : pickupCompleted  ? "Heading to Drop-off"
                                                    : "Trip In Progress")
                                .font(.subheadline.weight(.semibold))
                            Text(dropoffCompleted ? "Post-trip checklist opening…"
                                 : pickupCompleted  ? "Mark drop-off done when you arrive"
                                                    : "Mark pickup done after collecting")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: dropoffCompleted ? "flag.checkered.circle.fill"
                              : pickupCompleted  ? "arrow.right.circle.fill"
                                                 : "bolt.circle.fill")
                            .foregroundStyle(dropoffCompleted ? .teal : .green)
                            .font(.title3)
                    }
                    .listRowBackground(
                        (dropoffCompleted ? Color.teal : Color.green).opacity(0.08)
                    )
                }
            }

            // ── 4. Route ─────────────────────────────────────────────────
            Section("Route") {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup").font(.caption).foregroundStyle(.secondary)
                        Text(route?.startLocation ?? "Loading…")
                    }
                } icon: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 10)).foregroundStyle(.green)
                        .frame(width: 28, height: 28)
                        .background(Color.green.opacity(0.12), in: Circle())
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drop-off").font(.caption).foregroundStyle(.secondary)
                        Text(route?.endLocation ?? "Loading…")
                    }
                } icon: {
                    Image(systemName: "mappin")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.red)
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.12), in: Circle())
                }
            }

            // ── 5. Details ───────────────────────────────────────────────
            Section("Details") {
                if let start = trip.startTime {
                    LabeledContent { Text(start.formatted(date: .abbreviated, time: .omitted)) }
                    label: { Label("Date",       systemImage: "calendar") }

                    LabeledContent { Text(start.formatted(date: .omitted, time: .shortened)) }
                    label: { Label("Start Time", systemImage: "clock") }
                }

                LabeledContent { Text(distanceText) }
                label: { Label("Distance",   systemImage: "road.lanes") }

                if let t = trip.orderType {
                    LabeledContent { Text(t.displayName) }
                    label: { Label("Order Type", systemImage: "shippingbox") }
                }
            }

            // ── 6. Vehicle ───────────────────────────────────────────────
            Section("Vehicle") {
                if let v = vehicle {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(v.make ?? "") \(v.model ?? "")").font(.body)
                            Text(v.licensePlate ?? "—").font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "truck.box.fill")
                            .foregroundStyle(.green).font(.title3).frame(width: 28)
                    }

                    NavigationLink(destination: DriverVehicleDetailView(vehicle: v)) {
                        Label("Vehicle Details", systemImage: "info.circle")
                    }

                    if !isActive {
                        NavigationLink(destination: DriverReportIssueView(vehicle: v)) {
                            Label("Report Vehicle Issue",
                                  systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    Label("Loading vehicle info…", systemImage: "truck.box")
                        .foregroundStyle(.secondary)
                }
            }

            // ── 7. Pre-trip checklist button — below vehicle, scheduled only ─
            if isScheduled {
                Section {
                    Button {
                        showingChecklist = .preTrip
                    } label: {
                        Label("Start Pre-Trip Checklist", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            // ── 8. In-trip actions ───────────────────────────────────────
            if isActive && !dropoffCompleted {
                Section {
                    // Phase 1 — Pickup Done
                    if !pickupCompleted {
                        Button {
                            withAnimation(.spring(response: 0.3)) { pickupCompleted = true }
                            onPickupDone?(trip.id, trip.vehicleId)
                        } label: {
                            Label("Pickup Done", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // Phase 2 — Drop-off Done → opens post-trip checklist sheet
                    if pickupCompleted {
                        Button {
                            withAnimation(.spring(response: 0.3)) { dropoffCompleted = true }
                            showingChecklist = .postTrip
                        } label: {
                            Label("Drop-off Done", systemImage: "flag.checkered")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Report Incident
                    NavigationLink(destination: DriverReportIncidentView(trip: trip)) {
                        Label("Report Incident",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            // ── 8. Incidents ─────────────────────────────────────────────
            if !incidents.isEmpty {
                Section("Incident History") {
                    ForEach(incidents) { incident in
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(incident.incidentType)
                                    .font(.subheadline.weight(.medium))
                                Text(incident.description)
                                    .font(.caption).foregroundStyle(.secondary)
                                if let d = incident.createdAt {
                                    Text(d.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                            }
                        } icon: {
                            Image(systemName: TripIncidentType(rawValue: incident.incidentType)?.icon
                                             ?? "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            // ── 9. Completed ─────────────────────────────────────────────
            if isCompleted {
                Section {
                    Label("Trip completed successfully",
                          systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .listRowBackground(Color.green.opacity(0.08))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.large)
        .task {
            async let r = trip.routeId != nil ? RouteService.fetchRoute(id: trip.routeId!) : nil
            async let v = VehicleService.fetchVehicle(id: trip.vehicleId)
            route   = try? await r
            vehicle = try? await v
            if let s = route?.startLocation, let e = route?.endLocation {
                await calculateDistance(from: s, to: e)
            }
            if trip.status == .active {
                let fences = (try? await GeofenceService.fetchGeofences(forTrip: trip.id)) ?? []
                if let pf = fences.first(where: { $0.zoneType == "pickup" }) {
                    let events = (try? await GeofenceService.fetchEvents(forVehicle: trip.vehicleId, limit: 30)) ?? []
                    if events.contains(where: { $0.geofenceId == pf.id && $0.eventType == "pickup_done" }) {
                        pickupCompleted = true
                    }
                }
            }
        }
        .onAppear {
            Task { incidents = (try? await TripIncidentService.fetchIncidents(forTripId: trip.id)) ?? [] }
        }
        .sheet(item: $showingChecklist) { type in
            DriverChecklistView(checklistType: type, vehicle: vehicle) { notes, urls in
                if type == .preTrip {
                    onStart(trip.id, trip.vehicleId, notes, urls)
                    withAnimation { currentStatus = .active }
                    openMapsNavigation()
                } else {
                    onEnd(trip.id, trip.vehicleId, estimatedDistance, notes, urls)
                    withAnimation { currentStatus = .completed }
                }
                showingChecklist = nil
            }
        }
    }

    // MARK: - Helpers

    private func openMapsNavigation() {
        guard let s = route?.startLocation, !s.isEmpty,
              let e = route?.endLocation,   !e.isEmpty else { return }
        Task {
            async let si = geocodeAddress(s); async let di = geocodeAddress(e)
            guard let src = await si, let dst = await di else { return }
            src.name = s; dst.name = e
            MKMapItem.openMaps(with: [src, dst], launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ])
        }
    }

    private func geocodeAddress(_ address: String) async -> MKMapItem? {
        if let range = address.range(of: "@latlng:") {
            let parts = address[range.upperBound...].components(separatedBy: ",")
            if parts.count == 2,
               let lat = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
               let lon = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: .init(latitude: lat, longitude: lon)))
                item.name = address[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                return item
            }
        }
        let req = MKLocalSearch.Request(); req.naturalLanguageQuery = address
        return try? await MKLocalSearch(request: req).start().mapItems.first
    }

    private func calculateDistance(from s: String, to e: String) async {
        guard let si = await geocodeAddress(s), let ei = await geocodeAddress(e) else { return }
        let req = MKDirections.Request()
        req.source = si; req.destination = ei; req.transportType = .automobile
        if let r = try? await MKDirections(request: req).calculate().routes.first {
            await MainActor.run { estimatedDistance = r.distance / 1000.0 }
        }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(
            trip: Trip(id: UUID(), vehicleId: UUID(), driverId: UUID(), routeId: UUID(),
                       startTime: Date(), endTime: nil, distance: nil,
                       status: .scheduled, orderType: .pickUpAndDrop),
            onStart: { _, _, _, _ in },
            onEnd:   { _, _, _, _, _ in }
        )
    }
    .environment(AuthViewModel())
}
