import SwiftUI
import MapKit
import CoreLocation

struct TripDetailView: View {

    let trip:          Trip
    let onStart:       (UUID, UUID, String, [String]) -> Void
    let onEnd:         (UUID, UUID, Double?, String, [String]) -> Void
    var onPickupDone:  ((UUID, UUID) -> Void)? = nil
    var onDropoffDone: ((UUID, UUID, UUID?) -> Void)? = nil   // tripId, vehicleId, dropoffGeofenceId

    @State private var currentStatus:    TripStatus?
    @State private var showingChecklist: InspectionType? = nil
    @State private var showingReportIncident = false
    @State private var pickupCompleted  = false
    @State private var dropoffCompleted = false
    @State private var dropoffGeofenceId: UUID? = nil   // cached when dropoff zone fires

    // Zone entry — gated by geofence "enter" events from Supabase
    @State private var inPickupZone     = false
    @State private var inDropoffZone    = false
    @State private var zoneTask: Task<Void, Never>? = nil
    @State private var realtimeHandlerRegistered = false

    // Brief confirmation banners
    @State private var showPickupBanner  = false
    @State private var showDropoffBanner = false
    @State private var showVoiceRecordingBanner = false

    @State private var route:             Route?
    @State private var vehicle:           Vehicle?
    @State private var estimatedDistance: Double?
    
    // Voice logging
    @State private var voiceViewModel = VoiceTripLogViewModel()

    init(trip: Trip,
         onStart:       @escaping (UUID, UUID, String, [String]) -> Void,
         onEnd:         @escaping (UUID, UUID, Double?, String, [String]) -> Void,
         onPickupDone:  ((UUID, UUID) -> Void)? = nil,
         onDropoffDone: ((UUID, UUID, UUID?) -> Void)? = nil) {
        self.trip          = trip
        self.onStart       = onStart
        self.onEnd         = onEnd
        self.onPickupDone  = onPickupDone
        self.onDropoffDone = onDropoffDone
        self._currentStatus = State(initialValue: trip.status)
    }

    // MARK: - Zone state persistence (UserDefaults, keyed by trip ID)
    // Survives any @State reset — view recreation, memory pressure, sheet onDisappear.

    private var udPickup:      String { "fleet.zone.pickup.\(trip.id.uuidString)" }
    private var udDropoff:     String { "fleet.zone.dropoff.\(trip.id.uuidString)" }
    private var udPickupDone:  String { "fleet.zone.pkDone.\(trip.id.uuidString)" }
    private var udDropoffDone: String { "fleet.zone.doDone.\(trip.id.uuidString)" }
    private var udDropoffFence:String { "fleet.zone.doFence.\(trip.id.uuidString)" }

    /// Called on every onAppear — restores state instantly with no network round-trip.
    private func restoreZoneFromCache() {
        let ud = UserDefaults.standard
        if ud.bool(forKey: udPickup)     { inPickupZone     = true }
        if ud.bool(forKey: udDropoff)    { inDropoffZone    = true }
        if ud.bool(forKey: udPickupDone) { pickupCompleted  = true }
        if ud.bool(forKey: udDropoffDone){ dropoffCompleted = true }
        if let s = ud.string(forKey: udDropoffFence), let id = UUID(uuidString: s) {
            dropoffGeofenceId = id
        }
    }

    /// Call after any zone flag becomes true.
    private func saveZoneToCache() {
        let ud = UserDefaults.standard
        ud.set(inPickupZone,     forKey: udPickup)
        ud.set(inDropoffZone,    forKey: udDropoff)
        ud.set(pickupCompleted,  forKey: udPickupDone)
        ud.set(dropoffCompleted, forKey: udDropoffDone)
        if let fid = dropoffGeofenceId { ud.set(fid.uuidString, forKey: udDropoffFence) }
    }

    /// Call when trip ends to free up UserDefaults space.
    private func clearZoneCache() {
        let ud = UserDefaults.standard
        [udPickup, udDropoff, udPickupDone, udDropoffDone, udDropoffFence].forEach {
            ud.removeObject(forKey: $0)
        }
    }

    // MARK: - Computed

    var isScheduled: Bool { currentStatus == .scheduled }
    var isActive:    Bool { currentStatus == .active    }
    var isCompleted: Bool { currentStatus == .completed }

    var canStartTrip: Bool {
        guard let scheduledTime = trip.startTime else { return true }
        return Date.now >= scheduledTime
    }

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
                    NavigationLink(destination: DriverVehicleDetailView(vehicle: v)) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(v.make ?? "") \(v.model ?? "")").font(.body)
                                Text(v.licensePlate ?? "—").font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "truck.box.fill")
                                .foregroundStyle(.green).font(.title3).frame(width: 28)
                        }
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
                    let canStart = canStartTrip
                    Button {
                        showingChecklist = .preTrip
                    } label: {
                        if canStart {
                            Label("Start Pre-Trip Checklist", systemImage: "checklist")
                                .frame(maxWidth: .infinity)
                        } else {
                            if let start = trip.startTime {
                                Label("Cannot Start Yet (Scheduled for \(start.formatted(date: .abbreviated, time: .shortened)))", systemImage: "calendar.badge.clock")
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label("Start Pre-Trip Checklist", systemImage: "checklist")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(canStart ? .green : .secondary)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .disabled(!canStart)
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
                        saveZoneToCache()
                        onPickupDone?(trip.id, trip.vehicleId)
                        withAnimation(.spring(response: 0.4)) { showPickupBanner = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation(.easeOut) { showPickupBanner = false }
                        }
                    }

                    // ── Drop-off toggle (always visible) ─────────────────
                    TripZoneToggleRow(
                        label:    "Drop-off",
                        locked:   !inDropoffZone || !pickupCompleted,
                        done:     dropoffCompleted,
                        tint:     .indigo,
                        lockHint: !pickupCompleted ? "Complete pickup first" : "Enter the drop-off zone to enable",
                        doneHint: "Drop-off confirmed"
                    ) {
                        withAnimation(.spring(response: 0.3)) { dropoffCompleted = true }
                        saveZoneToCache()
                        onDropoffDone?(trip.id, trip.vehicleId, dropoffGeofenceId)
                    }
                }

                Section {
                    Button {
                        showingReportIncident = true
                    } label: {
                        Label("Report Incident", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.85, green: 0.65, blue: 0.0)) // dark yellow / gold
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if isActive {
                VStack(spacing: 8) {
                    // Recording transcript feedback
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

                    HStack(spacing: 12) {
                        // Circular mic button
                        Button {
                            if voiceViewModel.voiceService.isRecording {
                                voiceViewModel.stopAndExtract(
                                    tripId: trip.id,
                                    driverId: trip.driverId,
                                    routeName: "\(route?.startLocation ?? "Origin") → \(route?.endLocation ?? "Destination")"
                                )
                            } else {
                                voiceViewModel.startVoiceCapture()
                                withAnimation(.spring(response: 0.4)) { showVoiceRecordingBanner = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                    withAnimation(.easeOut) { showVoiceRecordingBanner = false }
                                }
                            }
                        } label: {
                            Image(systemName: voiceViewModel.voiceService.isRecording ? "stop.fill" : "mic.fill")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 54, height: 54)
                                .background(voiceViewModel.voiceService.isRecording ? Color.red : Color.orange)
                                .clipShape(Circle())
                                .shadow(radius: 1.5)
                        }
                        .buttonStyle(.plain)
                        .disabled(voiceViewModel.isProcessing)
                        
                        // Expanding Post-Trip Checklist button (always active)
                        Button {
                            showingChecklist = .postTrip
                        } label: {
                            Label("Post-Trip Checklist", systemImage: "checklist")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(voiceViewModel.voiceService.isRecording)
                        .buttonBorderShape(.capsule)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
        }
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
        .overlay(alignment: .top) {
            if showVoiceRecordingBanner {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                    Text("Record message to send directly to the fleet manager.")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange, in: Capsule())
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.4), value: showVoiceRecordingBanner)
        .navigationBarTitleDisplayMode(.large)
        // Instant restore from cache — runs before .task's async work completes.
        // Prevents locked buttons during the network round-trip on every re-appear.
        .onAppear {
            restoreZoneFromCache()
        }
        .task {
            // Route and vehicle fetches start immediately (concurrent)
            async let r = trip.routeId != nil ? RouteService.fetchRoute(id: trip.routeId!) : nil
            async let v = VehicleService.fetchVehicle(id: trip.vehicleId)

            // Zone restore runs concurrently with the above fetches.
            // CRITICAL: this must NOT be placed after calculateDistance — MKDirections
            // can take 5-10 seconds, and if the driver navigates away before it finishes
            // the task is cancelled and zone state is never restored from DB.
            await refreshZoneStatus()

            // Now collect the concurrent results
            route   = try? await r
            vehicle = try? await v

            // Distance calc is display-only — run last so it never blocks zone UI
            if let s = route?.startLocation, let e = route?.endLocation {
                await calculateDistance(from: s, to: e)
            }

            if currentStatus == .active {
                startZonePolling()
                if !realtimeHandlerRegistered {
                    realtimeHandlerRegistered = true
                    RealtimeManager.shared.addGeofenceEventsChangeHandler {
                        Task { await self.refreshZoneStatus() }
                    }
                }
            }
        }
        // Instant unlock when zone is entered — no Supabase round-trip
        .onReceive(NotificationCenter.default.publisher(for: .gfZoneEntered)) { note in
            guard let type = note.userInfo?["zoneType"] as? String else { return }
            let fenceIdStr = note.userInfo?["geofenceId"] as? String
            withAnimation(.spring(response: 0.35)) {
                if type == "pickup"  { inPickupZone  = true }
                if type == "dropoff" {
                    inDropoffZone    = true
                    if let s = fenceIdStr { dropoffGeofenceId = UUID(uuidString: s) }
                }
            }
            saveZoneToCache()   // persist so re-appear restores instantly
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
                    clearZoneCache()
                }
                showingChecklist = nil
            }
        }
        .navigationDestination(isPresented: $showingReportIncident) {
            DriverReportIncidentView(trip: trip)
        }
    }

    // MARK: - Zone status (gates button visibility)

    /// Reads geofence events from Supabase and updates zone state.
    /// Zone flags (inPickupZone / inDropoffZone) are ONE-DIRECTIONAL — once true they
    /// never revert to false via a DB refresh. This means a failed or empty fetch never
    /// re-locks a button the driver already unlocked by physically entering the zone.
    private func refreshZoneStatus() async {
        let fences = (try? await GeofenceService.fetchAllGeofences(forTrip: trip.id)) ?? []
        guard !fences.isEmpty else { return }

        let pFence   = fences.first(where: { $0.zoneType == "pickup"  })
        let dFence   = fences.first(where: { $0.zoneType == "dropoff" })
        let fenceIds = fences.map { $0.id }

        // Query directly by fence IDs — no cross-trip contamination, no limit cutoff.
        guard let events = try? await GeofenceService.fetchEvents(forFences: fenceIds) else { return }

        // Multiple fences of the same type can exist (e.g. if setup ran twice).
        // Check ANY pickup/dropoff fence so we don't miss the event.
        let pFenceIds = fences.filter { $0.zoneType == "pickup"  }.map { $0.id }
        let dFenceIds = fences.filter { $0.zoneType == "dropoff" }.map { $0.id }

        withAnimation(.spring(response: 0.35)) {
            // Only promote false → true. A DB refresh can never re-lock a button.
            if events.contains(where: { pFenceIds.contains($0.geofenceId) && $0.eventType == "enter" }) {
                inPickupZone = true
            }
            if events.contains(where: { dFenceIds.contains($0.geofenceId) && $0.eventType == "enter" }) {
                inDropoffZone     = true
                dropoffGeofenceId = dFence?.id
            }
            if !pickupCompleted {
                pickupCompleted = events.contains {
                    pFenceIds.contains($0.geofenceId) && $0.eventType == "pickup_done"
                }
            }
            if !dropoffCompleted {
                dropoffCompleted = events.contains {
                    dFenceIds.contains($0.geofenceId) && $0.eventType == "dropoff_done"
                }
            }
        }
        saveZoneToCache()   // write to UserDefaults after every DB-driven update
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
                let item = MKMapItem(location: CLLocation(latitude: lat, longitude: lon), address: nil)
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
            onEnd:   { _, _, _, _, _ in },
            onPickupDone: { _, _ in },
            onDropoffDone: { _, _, _ in }
        )
    }
    .environment(AuthViewModel())
}
