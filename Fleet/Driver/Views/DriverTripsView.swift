import SwiftUI
import Supabase

struct DriverTripsView: View {

    @State private var viewModel = DriverTripsViewModel()
    @State private var selectedFilter: TripFilter = .all
    @State private var showingSchedule = false
    @Environment(AuthViewModel.self) private var authViewModel

    enum TripFilter: String, CaseIterable {
        case all       = "All"
        case remaining = "Upcoming"
        case completed = "Completed"
    }

    var filteredTrips: [Trip] {
        switch selectedFilter {
        case .all:       return viewModel.sortedTrips
        case .remaining: return viewModel.sortedTrips.filter { $0.status == .scheduled || $0.status == .active }
        case .completed: return viewModel.sortedTrips.filter { $0.status == .completed }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.trips.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            filterChips
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listSectionSeparator(.hidden)

                        Section {
                            if filteredTrips.isEmpty {
                                ContentUnavailableView(
                                    "No Trips",
                                    systemImage: "road.lanes",
                                    description: Text("No trips match this filter.")
                                )
                                .padding(.vertical, 20)
                                .listRowBackground(Color.clear)
                            } else {
                                ForEach(filteredTrips) { trip in
                                    // ZStack hides NavigationLink's built-in row chevron
                                    // so the chevron lives inside the card instead
                                    ZStack {
                                        // Hidden NavigationLink drives the navigation
                                        NavigationLink {
                                            TripDetailView(
                                                trip: trip,
                                                onStart: { id, vId, notes, urls in
                                                    viewModel.startTrip(id: id, vehicleId: vId, notes: notes, imageUrls: urls)
                                                },
                                                onEnd: { id, vId, distance, notes, urls in
                                                    viewModel.endTrip(id: id, vehicleId: vId, distance: distance, notes: notes, imageUrls: urls)
                                                },
                                                onPickupDone: { id, vId in
                                                    viewModel.gf_pickupDone(tripId: id, vehicleId: vId)
                                                },
                                                onDropoffDone: { id, vId, fenceId in
                                                    viewModel.gf_dropoffDone(tripId: id, vehicleId: vId, geofenceId: fenceId)
                                                }
                                            )
                                        } label: {
                                            EmptyView()
                                        }
                                        .opacity(0)

                                        // Visible card — chevron is inside the card
                                        TripListRow(
                                            trip: trip,
                                            route: viewModel.routeForTrip(trip),
                                            vehicle: viewModel.vehicleForTrip(trip)
                                        )
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                                }
                            }
                        }
                        .listSectionSeparator(.hidden)
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await viewModel.loadData() }
                }
            }
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSchedule = true } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingSchedule) {
                DriverScheduleView(viewModel: viewModel)
            }
            .onChange(of: authViewModel.currentUser?.id, initial: true) { _, newUserId in
                guard let userId = newUserId else { return }
                viewModel.currentUserId = userId
                Task {
                    await viewModel.loadData()
                    viewModel.setupRealtime()
                }
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TripFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? Color.green : Color(.tertiarySystemFill))
                            .foregroundStyle(selectedFilter == filter ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Trip List Row

struct TripListRow: View {
    let trip:    Trip
    let route:   Route?
    let vehicle: Vehicle?

    var statusColor: Color {
        switch trip.status {
        case .scheduled: return .blue
        case .active:    return .green
        case .completed: return .green
        case .cancelled: return .red
        default:         return Color(.quaternaryLabel)
        }
    }

    var statusLabel: String {
        switch trip.status {
        case .scheduled: return "Scheduled"
        case .active:    return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        default:         return "Unknown"
        }
    }

    var orderIcon: String {
        switch trip.orderType {
        case .bulkOrderShip: return "shippingbox.fill"
        case .pickUpAndDrop:  return "arrow.left.arrow.right"
        case .travel:         return "car.fill"
        default:              return "shippingbox"
        }
    }

    var orderColor: Color {
        switch trip.orderType {
        case .bulkOrderShip: return .orange
        case .pickUpAndDrop:  return .teal
        case .travel:         return .indigo
        default:              return .secondary
        }
    }

    var vehicleIcon: String {
        guard let type = vehicle?.vehicleType else { return "car" }
        switch type {
        case .twoWheeler:   return "scooter"
        case .threeWheeler: return "car.2"
        case .car:          return "car"
        case .truck:        return "truck.box"
        }
    }

    var formattedDate: String {
        guard let date = trip.startTime else { return "Not Scheduled" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(orderColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: orderIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(orderColor)
                }
                Text(trip.orderType?.displayName ?? "Trip")
                    .font(.headline)
                Spacer()
                StatusBadge(text: statusLabel, color: statusColor)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            // Route timeline
            if let start = route?.startLocation, let end = route?.endLocation {
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 3) {
                        Circle().fill(.green).frame(width: 7, height: 7)
                        Rectangle().fill(Color(.separator)).frame(width: 1.5, height: 16)
                        Circle().fill(.red).frame(width: 7, height: 7)
                    }
                    .padding(.top, 3)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(start).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        Text(end).font(.subheadline.weight(.medium)).lineLimit(1)
                    }
                }
                .padding(.leading, 2)
            }

            Divider()

            // Vehicle
            Label {
                Text(vehicle.map { "\($0.make ?? "") \($0.model ?? "")" } ?? "No Vehicle")
                    .font(.footnote)
                    .foregroundStyle(vehicle != nil ? .secondary : Color(.tertiaryLabel))
                    .lineLimit(1)
            } icon: {
                Image(systemName: vehicleIcon)
                    .foregroundStyle(.green)
            }

            Divider()

            // Footer
            HStack {
                Label(formattedDate, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("#\(trip.id.uuidString.prefix(8).uppercased())")
                    .font(.caption.monospaced())
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    DriverTripsView()
        .environment(AuthViewModel())
}
