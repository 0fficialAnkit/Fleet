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
    @State private var pollingTask:    Task<Void, Never>?  = nil

    var route:       Route? { viewModel.route(for: trip.routeId) }
    var driverName:  String { viewModel.driverName(for: trip.driverId) }
    var vehicleInfo: String { viewModel.vehicleName(for: trip.vehicleId) }
    var isActive:    Bool   { trip.status == .active }

    var formattedDate: String {
        guard let d = trip.startTime else { return "Not Scheduled" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: d)
    }

    // Events for this trip — oldest first, de-duplicated.
    // Works for both active AND completed trips.
    var tripEvents: [TripGeofenceEvent] {
        // If we have fence IDs, filter precisely; otherwise show all fetched events
        let sorted: [TripGeofenceEvent]
        if geofences.isEmpty {
            sorted = gfEvents.sorted { ($0.occurredAt ?? .distantPast) < ($1.occurredAt ?? .distantPast) }
        } else {
            let ids = Set(geofences.map { $0.id })
            sorted = gfEvents
                .filter { ids.contains($0.geofenceId) }
                .sorted { ($0.occurredAt ?? .distantPast) < ($1.occurredAt ?? .distantPast) }
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

            // ── Driver Status — shown for active trips AND completed trips with history ──
            if !tripEvents.isEmpty || isActive {
                Section {
                    if tripEvents.isEmpty {
                        Label("Waiting for driver to enter a zone…",
                              systemImage: "location.magnifyingglass")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(tripEvents) { event in
                            eventRow(event)
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
        .navigationTitle(route?.routeName ?? "Order Details")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await refreshAll() }
        .task {
            await loadAll()          // loads geofences + events for all trip states
            if isActive {
                startPolling()
                RealtimeManager.shared.addGeofenceEventsChangeHandler {
                    Task { await self.refreshGeofenceData() }
                }
                RealtimeManager.shared.addVehicleLocationsChangeHandler {
                    Task { await self.refreshLocations() }
                }
            }
        }
        .onDisappear { pollingTask?.cancel(); pollingTask = nil }
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
            icon = "mappin.circle.fill";      tint = .blue
            title = "📍 Driver Entered Pickup Zone"
            sub   = fence?.name ?? ""
        case "pickup_done":
            icon = "checkmark.circle.fill";   tint = .green
            title = "✅ Pickup Done"
            sub   = "Driver is heading to drop-off"
        case "enter":   // dropoff
            icon = "flag.circle.fill";        tint = .orange
            title = "🏁 Driver Entered Drop-off Zone"
            sub   = fence?.name ?? ""
        case "dropoff_done":
            icon = "flag.checkered.circle.fill"; tint = .teal
            title = "🏁 Drop-off Done"
            sub   = "Trip is ending"
        default:
            icon = "circle.fill";             tint = .secondary
            title = event.eventType;          sub = ""
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

    // MARK: - Data helpers

    private func loadAll() async {
        async let profile = ProfileService.fetchProfile(id: trip.driverId ?? UUID())
        async let locs    = VehicleLocationService.fetchLatestLocations(for: [trip.vehicleId])
        driverProfile  = try? await profile
        liveLocations  = (try? await locs) ?? []
        await refreshGeofenceData()
    }

    private func refreshLocations() async {
        liveLocations = (try? await VehicleLocationService.fetchLatestLocations(for: [trip.vehicleId])) ?? []
    }

    private func refreshGeofenceData() async {
        // fetchAllGeofences includes inactive fences — keeps history visible after trip ends
        geofences = (try? await GeofenceService.fetchAllGeofences(forTrip: trip.id)) ?? []
        gfEvents  = (try? await GeofenceService.fetchEvents(forVehicle: trip.vehicleId, limit: 30)) ?? []
    }

    private func refreshAll() async {
        await refreshLocations()
        await refreshGeofenceData()
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                await refreshAll()
            }
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
