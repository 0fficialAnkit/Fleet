import SwiftUI
import MapKit

struct OrderDetailView: View {
    let trip:      Trip
    let viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss

    // Live tracking state
    @State private var liveLocations:  [VehicleLocation]  = []
    @State private var driverProfile:  Profile?            = nil
    @State private var geofences:      [TripGeofence]      = []
    @State private var gfEvents:       [TripGeofenceEvent] = []
    @State private var routeBreaches:  [RouteBreach]       = []
    @State private var incidents:      [TripIncident]      = []
    @State private var pollingTask:    Task<Void, Never>?  = nil
    @State private var isEditingOrder = false

    var route:       Route? { viewModel.route(for: trip.routeId) }
    var driverName:  String { viewModel.driverName(for: trip.driverId) }
    var vehicleInfo: String { viewModel.vehicleName(for: trip.vehicleId) }
    var isActive:    Bool   { trip.status == .active }

    var formattedDate: String {
        guard let d = trip.startTime else { return "Not Scheduled" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: d)
    }

    // Events for this trip in strict milestone order: pickup-enter → pickup-done → dropoff-enter → dropoff-done.
    // Logical priority overrides timestamp so same-second events always display in the correct order.
    var tripEvents: [TripGeofenceEvent] {
        guard !geofences.isEmpty else { return [] }
        let ids    = Set(geofences.map { $0.id })
        let sorted = gfEvents
            .filter { ids.contains($0.geofenceId) }
            .sorted { a, b in
                let pa = logicalPriority(a)
                let pb = logicalPriority(b)
                if pa != pb { return pa < pb }
                return (a.occurredAt ?? .distantPast) < (b.occurredAt ?? .distantPast)
            }

        // Keep only the first occurrence of each logical milestone (dedup)
        var seen    = Set<String>()
        var unique  = [TripGeofenceEvent]()
        for event in sorted {
            let fence    = geofences.first(where: { $0.id == event.geofenceId })
            let isPickup = fence?.zoneType == "pickup"
            let key: String
            switch event.eventType {
            case "enter":       key = isPickup ? "pickup_enter"  : "dropoff_enter"
            case "pickup_done": key = "pickup_done"
            case "dropoff_done":key = "dropoff_done"
            default:            key = event.eventType
            }
            if !seen.contains(key) { seen.insert(key); unique.append(event) }
        }
        return unique
    }

    // Merges ALL driver activity into one chronological timeline:
    //   • Geofence milestones (pickup zone → pickup done → dropoff zone → dropoff done → trip ended)
    //   • Driver-reported incidents (manual form + voice)
    //   • Route boundary breaches
    // Geofence events keep their logical order when timestamps collide (< 1 s apart).
    private var driverStatusTimeline: [DriverStatusItem] {
        let gf       = tripEvents.map    { DriverStatusItem.geofenceEvent($0) }
        let inc      = incidents.map     { DriverStatusItem.incident($0)      }
        let breaches = routeBreaches.map { DriverStatusItem.routeBreach($0)   }
        return (gf + inc + breaches).sorted { a, b in
            let ta = a.timestamp; let tb = b.timestamp
            if abs(ta.timeIntervalSince(tb)) < 1.0 {
                switch (a, b) {
                case (.geofenceEvent(let ea), .geofenceEvent(let eb)):
                    return logicalPriority(ea) < logicalPriority(eb)
                case (.geofenceEvent, _): return true   // milestones always lead
                case (_, .geofenceEvent): return false
                default: return ta < tb
                }
            }
            return ta < tb
        }
    }

    // MARK: - Body

    var body: some View {
        List {

            // ── Live map ────────────────────────────────────────────────────
            if isActive, let route {
                Section {
                    ZStack(alignment: .topTrailing) {
                        DashboardMapView(
                            activeTrips: [trip],
                            routes: [route],
                            profiles: driverProfile.map { [$0] } ?? [],
                            vehicleLocations: liveLocations
                        )
                        .frame(height: 260)

                        // Live pill badge
                        Label(
                            liveLocations.isEmpty ? "Locating…" : "Live",
                            systemImage: "dot.radiowaves.left.and.right"
                        )
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(
                            liveLocations.isEmpty ? Color.orange : Color.green,
                            in: Capsule()
                        )
                        .padding(10)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            }

            // ── Driver Status — geofence milestones + driver incident reports ──
            if !driverStatusTimeline.isEmpty || isActive {
                Section {
                    if driverStatusTimeline.isEmpty {
                        Label("Waiting for driver to enter a zone…",
                              systemImage: "location.magnifyingglass")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(driverStatusTimeline) { item in
                            switch item {
                            case .geofenceEvent(let event):  eventRow(event)
                            case .incident(let incident):    incidentRow(incident)
                            case .routeBreach(let breach):   routeBreachTimelineRow(breach)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Driver Status")
                        Spacer()
                        if isActive {
                            Text("Real-time")
                                .font(.caption)
                                .foregroundStyle(.teal)
                                .textCase(nil)
                        }
                    }
                }
            }

            // ── Route Deviation — fits the existing List style ────────────────
            if !routeBreaches.isEmpty {
                Section {
                    ForEach(Array(routeBreaches.enumerated()), id: \.element.id) { idx, breach in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                Text("Violation #\(idx + 1)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(spacing: 0) {
                                LabeledContent("Time") {
                                    Text(breach.occurredAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 10)
                                
                                Divider()
                                
                                LabeledContent("Distance Off-Route") {
                                    Text(String(format: "%.1f km", breach.distanceFromCenter / 1000))
                                        .foregroundStyle(severityColor(breach.distanceFromCenter))
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 10)
                                
                                Divider()
                                
                                LabeledContent("Route Boundary Radius") {
                                    Text(String(format: "%.1f km", breach.fenceRadius / 1000))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 10)
                                
                                Divider()
                                
                                LabeledContent("Severity") {
                                    Text(severityLabel(breach.distanceFromCenter))
                                        .foregroundStyle(severityColor(breach.distanceFromCenter))
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 10)
                            }
                            .padding(.horizontal, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    HStack {
                        Text("Route Deviation Alert")
                            .foregroundStyle(.red)
                        Spacer()
                        Text("\(routeBreaches.count)")
                            .font(.caption.weight(.bold)).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(.red, in: Capsule())
                            .textCase(nil)
                    }
                }
            }



            // ── Order details ────────────────────────────────────────────────
            Section("Order Details") {
                LabeledContent("Order ID") {
                    Text("#\(trip.id.uuidString.prefix(8).uppercased())")
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Type") {
                    Text(trip.orderType?.displayName ?? "—")
                }
                LabeledContent("Status") {
                    StatusBadge(
                        text: trip.status?.rawValue.capitalized ?? "—",
                        color: viewModel.getStatusColor(for: trip.status))
                }
                if let d = trip.startTime {
                    LabeledContent("Started") {
                        Text(d.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }

            // ── Route ────────────────────────────────────────────────────────
            Section("Route") {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pickup").font(.caption).foregroundStyle(.secondary)
                        Text(route?.startLocation ?? "Not set")
                    }
                } icon: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drop-off").font(.caption).foregroundStyle(.secondary)
                        Text(route?.endLocation ?? "Not set")
                    }
                } icon: {
                    Image(systemName: "mappin")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.red)
                }
            }

            // ── Assignment ───────────────────────────────────────────────────
            Section("Assignment") {
                LabeledContent("Driver")  { Text(driverName) }
                LabeledContent("Vehicle") { Text(vehicleInfo) }
            }

            // ── Delete ───────────────────────────────────────────────────────
            Section {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteTrip(trip)
                            await MainActor.run { dismiss() }
                        } catch { print("Delete failed: \(error)") }
                    }
                } label: {
                    Label("Delete Order", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await refreshAll() }
        .task {
            await loadAll()

            // Always subscribe to Realtime and poll — the trip may be scheduled
            // when the fleet manager opens this view and become active later.
            // Without this, zone-entry events are missed entirely.
            startPolling()
            RealtimeManager.shared.addGeofenceEventsChangeHandler {
                Task { await self.refreshGeofenceData() }
            }
            RealtimeManager.shared.addRouteBreachHandler {
                // Instant update when a breach is logged — no 15s wait
                Task { await self.refreshRouteBreach() }
            }
            RealtimeManager.shared.addVehicleLocationsChangeHandler {
                Task { await self.refreshLocations() }
            }
            RealtimeManager.shared.addTripIncidentsChangeHandler {
                Task { await self.refreshIncidents() }
            }
        }
        .onDisappear { pollingTask?.cancel(); pollingTask = nil }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if trip.status == .scheduled {
                    Button("Edit") {
                        isEditingOrder = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingOrder) {
            AddOrderView(viewModel: viewModel, tripToEdit: trip)
        }
    }

    // MARK: - Event row (Apple native style)

    private func eventRow(_ event: TripGeofenceEvent) -> some View {
        let fence    = geofences.first(where: { $0.id == event.geofenceId })
        let isPickup = fence?.zoneType == "pickup"

        // Map event type → display properties
        let icon:  String
        let tint:  Color
        let title: String
        let sub:   String

        switch event.eventType {
        case "enter" where isPickup:
            icon = "mappin.circle.fill";         tint = .blue
            title = "Driver Entered Pickup Zone"
            sub   = fence?.name ?? ""
        case "pickup_done":
            icon = "checkmark.circle.fill";      tint = .green
            title = "Pickup Done"
            sub   = "Driver is heading to drop-off"
        case "enter":   // dropoff
            icon = "flag.circle.fill";           tint = .orange
            title = "Driver Entered Drop-off Zone"
            sub   = fence?.name ?? ""
        case "dropoff_done":
            icon = "flag.checkered.circle.fill"; tint = .teal
            title = "Drop-off Done"
            sub   = "Driver completing trip"
        case "trip_ended":
            icon = "checkmark.seal.fill";        tint = .green
            title = "Trip Ended"
            sub   = "Trip completed successfully"
        default:
            icon = "circle.fill";                tint = .secondary
            title = event.eventType;             sub = ""
        }

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if !sub.isEmpty {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let t = event.occurredAt {
                Text(t.formatted(date: .omitted, time: .shortened))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Incident row

    @ViewBuilder
    private func incidentRow(_ incident: TripIncident) -> some View {
        let isVoice = incident.isVoiceReported
        let type    = TripIncidentType(rawValue: incident.incidentType)
        let icon    = isVoice ? "mic.circle.fill" : (type?.icon ?? "exclamationmark.triangle.fill")
        let tint: Color = (type == .breakdown || type == .accident) ? .red : .orange

        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(incident.incidentType)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if isVoice {
                        Text("Voice")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                    }
                }
                if !incident.description.isEmpty {
                    Text(incident.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if !incident.location.isEmpty {
                    Label(incident.location, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(Color(.tertiaryLabel))
                        .lineLimit(1)
                }
            }

            Spacer()

            if let t = incident.createdAt {
                Text(t.formatted(date: .omitted, time: .shortened))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    // Compact route-breach row for the Driver Status timeline.
    // The Route Deviation section below still shows the full detail card.
    @ViewBuilder
    private func routeBreachTimelineRow(_ breach: RouteBreach) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(severityColor(breach.distanceFromCenter))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text("Route Boundary Breached")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(String(format: "%.1f km off route · %@",
                            breach.distanceFromCenter / 1000,
                            severityLabel(breach.distanceFromCenter)))
                    .font(.caption)
                    .foregroundStyle(severityColor(breach.distanceFromCenter))
            }

            Spacer()

            if let t = breach.occurredAt {
                Text(t.formatted(date: .omitted, time: .shortened))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    // Full-detail card shown in the dedicated Incidents section.
    // incidentRow() is the compact inline version for the Driver Status timeline.
    @ViewBuilder
    private func incidentDetailRow(_ incident: TripIncident) -> some View {
        let isVoice = incident.isVoiceReported
        let type    = TripIncidentType(rawValue: incident.incidentType)
        let icon    = isVoice ? "mic.circle.fill" : (type?.icon ?? "exclamationmark.triangle.fill")
        let tint: Color = (type == .breakdown || type == .accident) ? .red : .orange

        VStack(alignment: .leading, spacing: 10) {
            // Header row: icon + type label + source badge + time
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(incident.incidentType)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if isVoice {
                        HStack(spacing: 3) {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                            Text("Voice Report")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.orange)
                    } else {
                        Text("Manual Report")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let t = incident.createdAt {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(t.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(t.formatted(date: .omitted, time: .shortened))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Description
            if !incident.description.isEmpty {
                Text(incident.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Location (if present)
            if !incident.location.isEmpty {
                Label(incident.location, systemImage: "mappin.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    // MARK: - Route breach helpers (follow real fleet-app severity conventions)

    /// < 1 km off = yellow, 1–3 km = orange, > 3 km = red
    private func severityColor(_ distanceFromCenter: Double) -> Color {
        let km = distanceFromCenter / 1000
        if km < 1 { return .yellow }
        if km < 3 { return .orange }
        return .red
    }

    private func severityLabel(_ distanceFromCenter: Double) -> String {
        let km = distanceFromCenter / 1000
        if km < 1 { return "Minor" }
        if km < 3 { return "Moderate" }
        return "Critical"
    }

    private func metricCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.footnote.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    /// Priority 0-3 enforces 1→2→3→4 display order regardless of same-second timestamps.
    private func logicalPriority(_ event: TripGeofenceEvent) -> Int {
        let fence    = geofences.first(where: { $0.id == event.geofenceId })
        let isPickup = fence?.zoneType == "pickup"
        switch event.eventType {
        case "enter"         where isPickup: return 0  // 1. pickup zone entered
        case "pickup_done":                  return 1  // 2. pickup confirmed
        case "enter":                        return 2  // 3. dropoff zone entered
        case "dropoff_done":                 return 3  // 4. dropoff confirmed
        case "trip_ended":                   return 4  // 5. trip ended
        default:                             return 5
        }
    }

    // MARK: - Data helpers

    private func loadAll() async {
        async let profile = ProfileService.fetchProfile(id: trip.driverId ?? UUID())
        async let locs    = VehicleLocationService.fetchLatestLocations(for: [trip.vehicleId])
        driverProfile  = try? await profile
        liveLocations  = (try? await locs) ?? []
        await refreshGeofenceData()
        await refreshIncidents()
    }

    private func refreshLocations() async {
        liveLocations = (try? await VehicleLocationService.fetchLatestLocations(for: [trip.vehicleId])) ?? []
    }

    private func refreshGeofenceData() async {
        // Fetch ALL fences for this trip — active + inactive, survives trip end
        geofences = (try? await GeofenceService.fetchAllGeofences(forTrip: trip.id)) ?? []

        if geofences.isEmpty {
            gfEvents = []
        } else {
            // Query by fence IDs directly — no cross-trip contamination, no row-limit cutoff.
            // This guarantees all historical events survive even for vehicles with many trips.
            let fenceIds = geofences.map { $0.id }
            gfEvents = (try? await GeofenceService.fetchEvents(forFences: fenceIds)) ?? []
        }

        routeBreaches = (try? await RouteBreachService.fetchBreaches(forTrip: trip.id)) ?? []
    }

    private func refreshRouteBreach() async {
        routeBreaches = (try? await RouteBreachService.fetchBreaches(forTrip: trip.id)) ?? []
    }

    private func refreshIncidents() async {
        // fetchIncidents already orders by created_at DESC (newest first)
        incidents = (try? await TripIncidentService.fetchIncidents(forTripId: trip.id)) ?? []
    }

    private func refreshAll() async {
        await refreshLocations()
        await refreshGeofenceData()
        await refreshIncidents()
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                await refreshAll()
                // Stop polling once trip is completed — Realtime handles late stragglers
                if trip.status == .completed { break }
            }
        }
    }
}

// MARK: - Unified Driver Status timeline item

private enum DriverStatusItem: Identifiable {
    case geofenceEvent(TripGeofenceEvent)
    case incident(TripIncident)
    case routeBreach(RouteBreach)

    var id: UUID {
        switch self {
        case .geofenceEvent(let e): return e.id
        case .incident(let i):     return i.id
        case .routeBreach(let b):  return b.id
        }
    }

    var timestamp: Date {
        switch self {
        case .geofenceEvent(let e): return e.occurredAt ?? .distantPast
        case .incident(let i):     return i.createdAt  ?? .distantPast
        case .routeBreach(let b):  return b.occurredAt ?? .distantPast
        }
    }
}

// MARK: - Info row (kept for compatibility)

struct OrderDetailInfoRow: View {
    let icon: String; let title: String; let value: String
    var valueColor: Color = .primary
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 18))
                .foregroundStyle(Color(.tertiaryLabel)).frame(width: 24)
            Text(title).font(.body.weight(.medium)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body).foregroundStyle(valueColor)
        }.padding(.vertical, 8)
    }
}

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
