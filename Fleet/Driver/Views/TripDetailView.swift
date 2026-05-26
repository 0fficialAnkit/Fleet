import SwiftUI
import MapKit

struct TripDetailView: View {

    let trip: Trip
    let onStart: (UUID, UUID, String) -> Void
    let onEnd: (UUID, UUID, String) -> Void

    // Local status so UI reacts immediately after start/end
    @State private var currentStatus: TripStatus?
    @State private var showingChecklist: InspectionType? = nil

    // Route loaded from Supabase
    @State private var route: Route?
    @State private var mapView: TripRouteMapView?

    init(trip: Trip, onStart: @escaping (UUID, UUID, String) -> Void, onEnd: @escaping (UUID, UUID, String) -> Void) {
        self.trip = trip
        self.onStart = onStart
        self.onEnd = onEnd
        self._currentStatus = State(initialValue: trip.status)
    }

    // MARK: - Computed helpers

    var statusColor: Color {
        switch currentStatus {
        case .scheduled: return Color.yellow
        case .active:    return Color.green
        case .completed: return Color.green
        case .cancelled: return Color.red
        default:         return Color(.quaternaryLabel)
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
                            .font(.title.bold())
                            .foregroundStyle(Color.primary)
                        StatusBadge(text: statusText, color: statusColor)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.green)
                    }
                }

                Divider()
                    .overlay(Color(.separator))

                // ── Date & Time ────────────────────────────────────
                sectionTitle("Schedule")

                HStack(spacing: 12) {
                    infoTile(
                        icon: "calendar",
                        label: "Date",
                        value: trip.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "Today",
                        color: Color.purple
                    )
                    infoTile(
                        icon: "clock.fill",
                        label: "Start Time",
                        value: trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "09:00 AM",
                        color: Color.green
                    )
                    infoTile(
                        icon: "clock.badge.checkmark.fill",
                        label: "Est. End",
                        value: trip.endTime?.formatted(date: .omitted, time: .shortened) ?? "N/A",
                        color: Color.green
                    )
                }

                // ── Route ──────────────────────────────────────────
                sectionTitle("Route Details")

                VStack(alignment: .leading, spacing: 0) {
                    // Origin
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.green)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pickup / Origin")
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                            Text("Warehouse A, Sector 12")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }

                    // Connector line
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: 2, height: 32)
                        .padding(.leading, 19)

                    // Destination
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.red)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Drop-off / Destination")
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                            Text("Distribution Center, Zone B")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )

                // ── Distance Info ──────────────────────────────────
                HStack(spacing: 12) {
                    infoTile(
                        icon: "road.lanes",
                        label: "Distance",
                        value: trip.distance != nil ? String(format: "%.1f km", trip.distance!) : "42 km",
                        color: Color.yellow
                    )
                    infoTile(
                        icon: "timer",
                        label: "Est. Duration",
                        value: "~38 min",
                        color: Color.purple
                    )
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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.large)
        .task {
            // Load the associated route so the map has real addresses
            if let routeId = trip.routeId {
                route = try? await RouteService.fetchRoute(id: routeId)
            }
        }
        .sheet(item: $showingChecklist) { type in
            DriverChecklistView(checklistType: type) { notes in
                if type == .preTrip {
                    onStart(trip.id, trip.vehicleId, notes)
                    withAnimation { currentStatus = .active }
                    // Open Apple Maps with turn-by-turn navigation to destination
                    openMapsNavigation()
                } else {
                    onEnd(trip.id, trip.vehicleId, notes)
                    withAnimation { currentStatus = .completed }
                }
                showingChecklist = nil
            }
        }
    }

    // MARK: - Action Section

    @ViewBuilder
    var actionSection: some View {
        switch currentStatus {
        case .scheduled:
            Button {
                showingChecklist = .preTrip
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Trip")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

        case .active:
            VStack(spacing: 12) {
                // In-progress banner
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.green)
                    Text("Trip is currently in progress")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.green)
                    Spacer()
                }
                .padding(16)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // End Trip button
                Button {
                    showingChecklist = .postTrip
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                        Text("End Trip")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            }

        case .completed:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                Text("Trip completed successfully")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.green)
                Spacer()
            }
            .padding(16)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        default:
            EmptyView()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.primary)
    }

    // MARK: - Apple Maps Navigation

    /// Geocodes the route's destination using iOS 26 MKGeocodingRequest
    /// and opens Apple Maps with driving turn-by-turn navigation.
    private func openMapsNavigation() {
        guard let destination = route?.endLocation, !destination.isEmpty else { return }
        Task {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = destination
            searchRequest.resultTypes = .address
            guard let mapItem = try? await MKLocalSearch(request: searchRequest).start().mapItems.first
            else { return }
            mapItem.name = destination
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsShowsTrafficKey: true
            ])
        }
    }

    @ViewBuilder
    func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
