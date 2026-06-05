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
    @AppStorage private var pickupCompleted:  Bool
    @AppStorage private var dropoffCompleted: Bool
    @AppStorage private var dropoffGeofenceIdStr: String

    // Zone entry — gated by geofence "enter" events from Supabase
    @AppStorage private var inPickupZone:     Bool
    @AppStorage private var inDropoffZone:    Bool
    
    var dropoffGeofenceId: UUID? {
        get { UUID(uuidString: dropoffGeofenceIdStr) }
        nonmutating set { dropoffGeofenceIdStr = newValue?.uuidString ?? "" }
    }
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
    @State private var isHoldingMic       = false
    @State private var recordingSecondsLeft = 10
    @State private var recordingTask: Task<Void, Never>? = nil

    // Pre-trip checklist results
    @State private var preTripNotes: String?
    @State private var preTripUrls: [String]?
    @State private var showingFuelSheet = false

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
        
        // Initialize AppStorage with dynamic trip-specific keys
        self._pickupCompleted = AppStorage(wrappedValue: false, "fleet.zone.pkDone.\(trip.id.uuidString)")
        self._dropoffCompleted = AppStorage(wrappedValue: false, "fleet.zone.doDone.\(trip.id.uuidString)")
        self._inPickupZone = AppStorage(wrappedValue: false, "fleet.zone.pickup.\(trip.id.uuidString)")
        self._inDropoffZone = AppStorage(wrappedValue: false, "fleet.zone.dropoff.\(trip.id.uuidString)")
        self._dropoffGeofenceIdStr = AppStorage(wrappedValue: "", "fleet.zone.doFence.\(trip.id.uuidString)")
    }

    // MARK: - Zone state persistence
    
    /// Call when trip ends to free up UserDefaults space.
    // MARK: - Voice Recording

    @MainActor
    private func stopRecording() {
        recordingTask?.cancel()
        recordingTask = nil
        isHoldingMic = false
        recordingSecondsLeft = 10
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        voiceViewModel.stopAndExtract(
            tripId: trip.id,
            driverId: trip.driverId,
            routeName: "\(route?.startLocation ?? "Origin") → \(route?.endLocation ?? "Destination")"
        )
        withAnimation(.easeOut) { showVoiceRecordingBanner = false }
    }

    private func clearZoneCache() {
        let ud = UserDefaults.standard
        ["fleet.zone.pickup.\(trip.id.uuidString)", "fleet.zone.dropoff.\(trip.id.uuidString)", 
         "fleet.zone.pkDone.\(trip.id.uuidString)", "fleet.zone.doDone.\(trip.id.uuidString)", 
         "fleet.zone.doFence.\(trip.id.uuidString)"].forEach {
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
                        HStack(spacing: 12) {
                            Image(systemName: "truck.box.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(v.make ?? "") \(v.model ?? "")")
                                    .font(.body)
                                Text(v.licensePlate ?? "—")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if !isCompleted {
                        NavigationLink(destination: DriverReportIssueView(vehicle: v)) {
                            Label("Report Vehicle Issue",
                                  systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    Label("Loading vehicle info…", systemImage: "truck.box")
                        .foregroundStyle(.secondary)
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
                        onDropoffDone?(trip.id, trip.vehicleId, dropoffGeofenceId)
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showingFuelSheet = true } label: {
                    Image(systemName: "fuelpump")
                }
            }
        }
        .sheet(isPresented: $showingFuelSheet) {
            DriverFuelView(isReadOnly: isCompleted, vehicleId: trip.vehicleId, tripId: trip.id)
        }
        .refreshable {
            await fetchTripData()
        }
        .safeAreaInset(edge: .bottom) {
            if isActive {
                VStack(spacing: 8) {

                    
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

                    VStack(spacing: 12) {
                        // Voice Log section
                        HStack(spacing: 12) {
                            // Mic button with countdown badge
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: isHoldingMic ? "waveform" : "mic.fill")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 54, height: 54)
                                    .background(isHoldingMic ? Color.red : Color(red: 0.85, green: 0.65, blue: 0.0))
                                    .clipShape(Circle())
                                    .scaleEffect(isHoldingMic ? 0.95 : 1.0)
                                    .animation(.spring(response: 0.3), value: isHoldingMic)

                                // Countdown badge
                                if isHoldingMic {
                                    Text("\(recordingSecondsLeft)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.75))
                                        .clipShape(Capsule())
                                        .offset(x: 4, y: -4)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            if isHoldingMic {
                                if !voiceViewModel.voiceService.liveTranscript.isEmpty {
                                    Text(voiceViewModel.voiceService.liveTranscript)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                } else {
                                    Text("Recording...")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Tap voice to report incident")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isHoldingMic {
                                // Tap while recording → stop early and send
                                stopRecording()
                            } else {
                                // Start recording
                                isHoldingMic = true
                                recordingSecondsLeft = 10
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                voiceViewModel.startVoiceCapture()
                                withAnimation(.spring(response: 0.4)) { showVoiceRecordingBanner = true }

                                recordingTask = Task {
                                    // Tick down every second
                                    for remaining in stride(from: 9, through: 0, by: -1) {
                                        try? await Task.sleep(for: .seconds(1))
                                        guard !Task.isCancelled else { return }
                                        await MainActor.run { recordingSecondsLeft = remaining }
                                    }
                                    // Auto-stop after 10 s
                                    guard !Task.isCancelled else { return }
                                    await MainActor.run { stopRecording() }
                                }
                            }
                        }
                        .disabled(voiceViewModel.isProcessing)
                        
                        // Expanding Post-Trip Checklist button (always active)
                        Button {
                            showingChecklist = .postTrip
                        } label: {
                            Label("Post-Trip Checklist", systemImage: "checklist")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
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
            } else if isScheduled {
                VStack(spacing: 8) {
                    let canStart = canStartTrip
                    
                    Button {
                        showingChecklist = .preTrip
                    } label: {
                        if canStart {
                            Label("Start Pre-Trip Checklist", systemImage: "checklist")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        } else {
                            if let start = trip.startTime {
                                Label("Scheduled for \(start.formatted(date: .abbreviated, time: .shortened))", systemImage: "calendar.badge.clock")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            } else {
                                Label("Start Pre-Trip Checklist", systemImage: "checklist")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(canStart ? .green : .secondary)
                    .buttonBorderShape(.capsule)
                    .disabled(!canStart)
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
        // Instant restore from cache is handled automatically by @AppStorage.
        .onAppear {
        }
        .task {
            await fetchTripData()

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
        }
        .onDisappear {
            zoneTask?.cancel()
            zoneTask = nil
        }
        .sheet(item: $showingChecklist) { type in
            DriverChecklistView(checklistType: type, vehicle: vehicle) { notes, urls in
                if type == .preTrip {
                    preTripNotes = notes
                    preTripUrls = urls
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

    private func fetchTripData() async {
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
    }

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
