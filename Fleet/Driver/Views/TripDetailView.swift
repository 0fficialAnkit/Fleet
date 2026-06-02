import SwiftUI
import MapKit

struct TripDetailView: View {

    let trip: Trip
    let onStart: (UUID, UUID, String, [String]) -> Void
    let onEnd: (UUID, UUID, String, [String]) -> Void

    // Local status so UI reacts immediately after start/end
    @State private var currentStatus: TripStatus?
    @State private var showingChecklist: InspectionType? = nil

    // Route loaded from Supabase
    @State private var route: Route?
    @State private var vehicle: Vehicle?
    @State private var mapView: TripRouteMapView?
    @State private var estimatedDistance: Double?
    @State private var incidents: [TripIncident] = []

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
                            .frame(width: 56, height: 56)
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.green)
                    }
                }

                Divider()
                    .overlay(Color(UIColor.separator))

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
                        icon: "road.lanes",
                        label: "Distance",
                        value: trip.distance != nil ? String(format: "%.1f km", trip.distance!) : (estimatedDistance != nil ? String(format: "%.1f km", estimatedDistance!) : "Calculating..."),
                        color: Color.yellow
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
                                .font(.body)
                                .foregroundStyle(Color.secondary)
                            Text(route?.startLocation ?? "No start location")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }

                    // Connector line
                    Rectangle()
                        .fill(Color(UIColor.separator))
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
                                .font(.body)
                                .foregroundStyle(Color.secondary)
                            Text(route?.endLocation ?? "No destination")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.primary)
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
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.green)
                                .frame(width: 44, height: 44)
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(vehicle.make ?? "Vehicle") \(vehicle.model ?? "")")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                                Text(vehicle.licensePlate ?? "—")
                                    .font(.body)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                        }

                        Divider().background(Color(UIColor.separator))

                        HStack(spacing: 16) {
                            NavigationLink(destination: DriverVehicleDetailView(vehicle: vehicle)) {
                                Label("View Details", systemImage: "info.circle")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.green)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.green.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: DriverReportIssueView(vehicle: vehicle)) {
                                Label("Report Issue", systemImage: "exclamationmark.triangle")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.red)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    HStack(spacing: 10) {
                        ProgressView().scaleEffect(0.8)
                        Text("Loading vehicle info…")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
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
                
                // ── Incidents ─────────────────────────────────────
                if !incidents.isEmpty {
                    sectionTitle("Incident History")
                    
                    VStack(spacing: 12) {
                        ForEach(incidents) { incident in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: TripIncidentType(rawValue: incident.incidentType)?.icon ?? "exclamationmark.triangle.fill")
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(incident.incidentType)
                                        .font(.headline)
                                        .foregroundStyle(Color.primary)
                                    Text(incident.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if let date = incident.createdAt {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        }
                    }
                }

                // ── Action Buttons ─────────────────────────────────
                actionSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.large)
        .task {
            // Load route and vehicle details
            async let fetchedRoute = trip.routeId != nil ? RouteService.fetchRoute(id: trip.routeId!) : nil
            async let fetchedVehicle = VehicleService.fetchVehicle(id: trip.vehicleId)

            route = try? await fetchedRoute
            vehicle = try? await fetchedVehicle
            
            if let start = route?.startLocation, let end = route?.endLocation {
                await calculateDistance(from: start, to: end)
            }
        }
        .onAppear {
            Task {
                incidents = (try? await TripIncidentService.fetchIncidents(forTripId: trip.id)) ?? []
            }
        }
        .sheet(item: $showingChecklist) { type in
            DriverChecklistView(checklistType: type, vehicle: vehicle) { notes, urls in
                if type == .preTrip {
                    onStart(trip.id, trip.vehicleId, notes, urls)
                    withAnimation { currentStatus = .active }
                    // Open Apple Maps with turn-by-turn navigation to destination
                    openMapsNavigation()
                } else {
                    onEnd(trip.id, trip.vehicleId, notes, urls)
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
            .shadow(color: Color.green.opacity(0.35), radius: 10, y: 4)

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
                .shadow(color: Color.red.opacity(0.35), radius: 10, y: 4)
                
                // Report Incident button
                NavigationLink(destination: DriverReportIncidentView(trip: trip)) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Report Incident")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .shadow(color: Color.orange.opacity(0.35), radius: 10, y: 4)
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

    /// Geocodes both the fleet-manager-specified start and end locations,
    /// then opens Apple Maps with the exact route the fleet manager defined.
    private func openMapsNavigation() {
        guard let startAddr = route?.startLocation, !startAddr.isEmpty,
              let endAddr   = route?.endLocation,   !endAddr.isEmpty
        else { return }

        Task {
            async let sourceResult = geocodeAddress(startAddr)
            async let destResult   = geocodeAddress(endAddr)

            guard let sourceItem = await sourceResult,
                  let destItem   = await destResult
            else { return }

            sourceItem.name = startAddr
            destItem.name   = endAddr

            MKMapItem.openMaps(
                with: [sourceItem, destItem],
                launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                    MKLaunchOptionsShowsTrafficKey: true
                ]
            )
        }
    }

    private func geocodeAddress(_ address: String) async -> MKMapItem? {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = address
        req.resultTypes = .address
        return try? await MKLocalSearch(request: req).start().mapItems.first
    }
    
    private func calculateDistance(from startAddr: String, to endAddr: String) async {
        guard let startItem = await geocodeAddress(startAddr),
              let endItem = await geocodeAddress(endAddr) else { return }
        
        let request = MKDirections.Request()
        request.source = startItem
        request.destination = endItem
        request.transportType = .automobile
        
        if let response = try? await MKDirections(request: request).calculate(),
           let route = response.routes.first {
            await MainActor.run {
                self.estimatedDistance = route.distance / 1000.0
            }
        }
    }

    @ViewBuilder
    func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(label)
                .font(.body)
                .foregroundStyle(Color.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
            trip: Trip(
                id: UUID(),
                vehicleId: UUID(),
                driverId: UUID(),
                routeId: UUID(),
                startTime: Date(),
                endTime: nil,
                distance: nil,
                status: .scheduled,
                orderType: .pickUpAndDrop
            ),
            onStart: { _, _, _, _ in },
            onEnd:   { _, _, _, _ in }
        )
    }
    .environment(AuthViewModel())
}


