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

    // Zone entry — gated by geofence "enter" events from Supabase
    @State private var inPickupZone     = false
    @State private var inDropoffZone    = false
    @State private var zoneTask: Task<Void, Never>? = nil

    // Brief confirmation banners
    @State private var showPickupBanner  = false
    @State private var showDropoffBanner = false

    @State private var route:             Route?
    @State private var vehicle:           Vehicle?
    @State private var estimatedDistance: Double?
    @State private var incidents:         [TripIncident] = []
    
    // Voice logging
    @State private var voiceViewModel = VoiceTripLogViewModel()

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

            // ── 8. In-trip actions ────────────────────────────────────────
            if isActive {

                Section {
                    // ── Pickup toggle ─────────────────────────────────────
                    TripZoneToggleRow(
                        label:    "Pickup",
                        locked:   !inPickupZone,
                        done:     pickupCompleted,
                        tint:     .green,
                        lockHint: "Enter the pickup zone to enable",
                        doneHint: "Pickup confirmed"
                    ) {
                        withAnimation(.spring(response: 0.3)) { pickupCompleted = true }
                        onPickupDone?(trip.id, trip.vehicleId)
                        withAnimation(.spring(response: 0.4)) { showPickupBanner = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.easeOut) { showPickupBanner = false }
                        }
                    }

                    // ── Drop-off toggle (only after pickup confirmed) ──────
                    if pickupCompleted {
                        TripZoneToggleRow(
                            label:    "Drop-off",
                            locked:   !inDropoffZone,
                            done:     dropoffCompleted,
                            tint:     .indigo,
                            lockHint: "Enter the drop-off zone to enable",
                            doneHint: "Drop-off confirmed"
                        ) {
                            withAnimation(.spring(response: 0.3)) { dropoffCompleted = true }
                            showingChecklist = .postTrip
                        }
                    }
                }

                // Report Incident (Voice Command) Button
                Section {
                    Button {
                        if voiceViewModel.voiceService.isRecording {
                            voiceViewModel.stopAndExtract(
                                tripId: trip.id,
                                driverId: trip.driverId,
                                routeName: "\(route?.startLocation ?? "Origin") → \(route?.endLocation ?? "Destination")"
                            )
                        } else {
                            voiceViewModel.startVoiceCapture()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: voiceViewModel.voiceService.isRecording ? "stop.fill" : "mic.fill")
                            Text(voiceViewModel.voiceService.isRecording ? "Stop & Send Alert" : "Report Incident (Voice)")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(voiceViewModel.voiceService.isRecording ? .red : .orange)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .disabled(voiceViewModel.isProcessing)
                    
                    // Native processing and live transcript feedback
                    if voiceViewModel.voiceService.isRecording && !voiceViewModel.voiceService.liveTranscript.isEmpty {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text(voiceViewModel.voiceService.liveTranscript)
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
                    }
                    
                    if voiceViewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView().tint(.purple)
                            Text("Analyzing voice report...")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.purple)
                        }
                    }
                    
                    if voiceViewModel.justSaved {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.orange)
                            Text("Alert sent to fleet!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.orange)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
        // ── Pickup confirmation banner ─────────────────────────────────
        .overlay(alignment: .top) {
            if showPickupBanner {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Pickup Done")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.green, in: Capsule())
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.4), value: showPickupBanner)
        .navigationBarTitleDisplayMode(.large)
        .task {
            async let r = trip.routeId != nil ? RouteService.fetchRoute(id: trip.routeId!) : nil
            async let v = VehicleService.fetchVehicle(id: trip.vehicleId)
            route   = try? await r
            vehicle = try? await v
            if let s = route?.startLocation, let e = route?.endLocation {
                await calculateDistance(from: s, to: e)
            }
            // Restore state from Supabase
            await refreshZoneStatus()
            // Subscribe to geofence events for live zone entry detection
            if trip.status == .active {
                startZonePolling()
                RealtimeManager.shared.addGeofenceEventsChangeHandler {
                    Task { await self.refreshZoneStatus() }
                }
            }
        }
        .onAppear {
            Task { incidents = (try? await TripIncidentService.fetchIncidents(forTripId: trip.id)) ?? [] }
        }
        // Instant unlock when zone is entered — no Supabase round-trip
        .onReceive(NotificationCenter.default.publisher(for: .gfZoneEntered)) { note in
            guard let type = note.userInfo?["zoneType"] as? String else { return }
            withAnimation(.spring(response: 0.35)) {
                if type == "pickup"  { inPickupZone  = true }
                if type == "dropoff" { inDropoffZone = true }
            }
        }
        .onDisappear {
            zoneTask?.cancel()
            zoneTask = nil
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
        .onChange(of: voiceViewModel.justSaved) { _, saved in
            if saved {
                // Refresh incidents in case a voice incident was just filed
                Task {
                    incidents = (try? await TripIncidentService.fetchIncidents(forTripId: trip.id)) ?? []
                }
            }
        }
    }

    // MARK: - Zone status (gates button visibility)

    /// Reads geofence events from Supabase and updates inPickupZone / inDropoffZone.
    /// Also restores pickupCompleted so the correct phase shows after app restart.
    private func refreshZoneStatus() async {
        let fences = (try? await GeofenceService.fetchAllGeofences(forTrip: trip.id)) ?? []
        guard !fences.isEmpty else { return }

        let pFence = fences.first(where: { $0.zoneType == "pickup"  })
        let dFence = fences.first(where: { $0.zoneType == "dropoff" })
        let fenceIds = Set(fences.map { $0.id })

        let all    = (try? await GeofenceService.fetchEvents(forVehicle: trip.vehicleId, limit: 30)) ?? []
        let events = all.filter { fenceIds.contains($0.geofenceId) }

        withAnimation(.spring(response: 0.35)) {
            // Driver entered pickup zone?
            inPickupZone = events.contains {
                $0.geofenceId == pFence?.id && $0.eventType == "enter"
            }
            // Driver entered dropoff zone?
            inDropoffZone = events.contains {
                $0.geofenceId == dFence?.id && $0.eventType == "enter"
            }
            // Pickup already completed?
            if !pickupCompleted {
                pickupCompleted = events.contains {
                    $0.geofenceId == pFence?.id && $0.eventType == "pickup_done"
                }
            }
        }
    }

    private func startZonePolling() {
        zoneTask?.cancel()
        zoneTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                await refreshZoneStatus()
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
